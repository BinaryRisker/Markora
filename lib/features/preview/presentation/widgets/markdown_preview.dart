import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../types/document.dart';
import '../../../../types/syntax_highlighting.dart';
import '../../../../main.dart';
import '../../../../core/utils/markdown_block_parser.dart';
import '../../../../core/utils/markdown_block_cache.dart';
import '../../../../core/utils/plugin_block_processor.dart';
import '../../../../core/utils/performance_monitor.dart';

import '../../../math/domain/services/math_parser.dart';
import '../../../plugins/domain/plugin_context_service.dart';
import '../../../math/presentation/widgets/math_formula_widget.dart';
import '../../../syntax_highlighting/presentation/widgets/code_block_widget.dart';


import '../../../export/presentation/widgets/export_dialog.dart';
import '../../../export/domain/entities/export_settings.dart';
import '../../../document/presentation/providers/document_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';





/// Markdown preview component
class MarkdownPreview extends ConsumerStatefulWidget {
  const MarkdownPreview({
    super.key,
    required this.content,
    this.onTap,
    this.selectable = true,
  });

  /// Markdown content
  final String content;
  
  /// Click callback
  final VoidCallback? onTap;
  
  /// Whether text is selectable
  final bool selectable;

  @override
  ConsumerState<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends ConsumerState<MarkdownPreview> {
  late ScrollController _scrollController;
  late MarkdownBlockParser _blockParser;
  
  // Performance optimization related
  Timer? _debounceTimer;
  String _lastRenderedContent = '';
  List<MarkdownBlock> _cachedBlocks = [];
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  
  // Track current language and font settings to detect changes
  String? _currentLanguage;
  String? _currentFontFamily;
  double? _currentFontSize;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _blockParser = MarkdownBlockParser();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if language has changed
    final newLanguage = Localizations.localeOf(context).languageCode;
    final settings = ref.watch(settingsProvider);
    final newFontFamily = settings.fontFamily;
    final newFontSize = settings.fontSize;
    
    bool shouldClearCache = false;
    
    if (_currentLanguage != null && _currentLanguage != newLanguage) {
      shouldClearCache = true;
    }
    
    if (_currentFontFamily != null && _currentFontFamily != newFontFamily) {
      shouldClearCache = true;
    }
    
    if (_currentFontSize != null && _currentFontSize != newFontSize) {
      shouldClearCache = true;
    }
    
    if (shouldClearCache) {
      // Settings changed, clear cache and force rebuild
      markdownBlockCache.clear();
      _cachedBlocks.clear();
      _lastRenderedContent = '';
    }
    
    _currentLanguage = newLanguage;
    _currentFontFamily = newFontFamily;
    _currentFontSize = newFontSize;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Preview toolbar
          _buildPreviewToolbar(),
          
          // Preview content
          Expanded(
            child: _buildOptimizedMarkdownContent(),
          ),
        ],
      ),
    );
  }

  /// Build optimized Markdown content (with cache and debounce)
  Widget _buildOptimizedMarkdownContent() {
    // If content hasn't changed, return cached blocks
    if (_lastRenderedContent == widget.content && _cachedBlocks.isNotEmpty) {
      return _buildBlockListView();
    }

    // Use debounce mechanism for content changes
    _debounceTimer?.cancel();
    
    // If first render or content is empty, render immediately
    if (_cachedBlocks.isEmpty || widget.content.isEmpty) {
      return _parseAndRenderBlocks();
    }

    // For content changes, use debounce
    _debounceTimer = Timer(_debounceDelay, () {
      if (mounted) {
        setState(() {
          _parseAndRenderBlocks();
        });
      }
    });

    // Return current cached blocks (display during debounce)
    return _buildBlockListView();
  }

  /// Parse content into blocks and render
  Widget _parseAndRenderBlocks() {
    if (widget.content.isEmpty) {
      return _buildEmptyState();
    }

    // Parse markdown into blocks
    final parseTimer = performanceMonitor.startTimer('markdown_parsing');
    _cachedBlocks = _blockParser.parseBlocks(widget.content);
    _lastRenderedContent = widget.content;
    parseTimer.stop(
      type: MetricType.parsing,
      metadata: {
        'content_length': widget.content.length,
        'blocks_count': _cachedBlocks.length,
      },
    );

    // Clean expired cache
    markdownBlockCache.cleanExpired();

    return _buildBlockListView();
  }

  /// Build ListView with blocks
  Widget _buildBlockListView() {
    if (_cachedBlocks.isEmpty) {
      return _buildEmptyState();
    }

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _cachedBlocks.length,
        itemBuilder: (context, index) {
          final block = _cachedBlocks[index];
          return _buildBlockWidget(block);
        },
      ),
    );
  }

  /// Build widget for a single block
  Widget _buildBlockWidget(MarkdownBlock block) {
    final settings = ref.watch(settingsProvider);
    final currentLanguage = Localizations.localeOf(context).languageCode;
    
    // Generate cache key with current settings
    final cacheKey = CacheKeyGenerator.forBlock(
      block,
      fontFamily: settings.fontFamily,
      fontSize: settings.fontSize.toDouble(),
      theme: Theme.of(context).brightness.name,
      language: currentLanguage,
    );

    // Check cache first
    final cacheTimer = performanceMonitor.startTimer('cache_lookup');
    final cachedWidget = markdownBlockCache.get(cacheKey);
    if (cachedWidget != null) {
      cacheTimer.stop(
        type: MetricType.caching,
        metadata: {
          'cache_hit': true,
          'block_type': block.type.name,
        },
      );
      return cachedWidget;
    }
    cacheTimer.stop(
      type: MetricType.caching,
      metadata: {
        'cache_hit': false,
        'block_type': block.type.name,
      },
    );

    // Build new widget
    final renderTimer = performanceMonitor.startTimer('block_rendering_${block.type.name}');
    Widget widget;
    switch (block.type) {
      case MarkdownBlockType.empty:
        widget = _buildEmptyBlock(block);
        break;
      case MarkdownBlockType.heading:
        widget = _buildHeadingBlock(block);
        break;
      case MarkdownBlockType.paragraph:
        widget = _buildParagraphBlock(block);
        break;
      case MarkdownBlockType.codeBlock:
        widget = _buildCodeBlock(block);
        break;
      case MarkdownBlockType.mathBlock:
        widget = _buildMathBlock(block);
        break;
      case MarkdownBlockType.quote:
        widget = _buildQuoteBlock(block);
        break;
      case MarkdownBlockType.list:
        widget = _buildListBlock(block);
        break;
      case MarkdownBlockType.table:
        widget = _buildTableBlock(block);
        break;
      case MarkdownBlockType.horizontalRule:
        widget = _buildHorizontalRuleBlock(block);
        break;
      case MarkdownBlockType.plugin:
        widget = _buildPluginBlock(block);
        break;
      case MarkdownBlockType.mathInline:
        widget = _buildParagraphBlock(block); // Treat as paragraph for now
        break;
    }

    // Cache the widget
    markdownBlockCache.put(cacheKey, widget);
    
    renderTimer.stop(
      type: MetricType.rendering,
      metadata: {
        'block_type': block.type.name,
        'content_length': block.content.length,
        'cached': false,
      },
    );

    return widget;
  }



  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.enterMarkdownContentInLeftEditor,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.previewWillBeDisplayedHere,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty block (spacing)
  Widget _buildEmptyBlock(MarkdownBlock block) {
    return const SizedBox(height: 8);
  }

  /// Build heading block
  Widget _buildHeadingBlock(MarkdownBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MarkdownBody(
        data: block.content,
        selectable: widget.selectable,
        styleSheet: _buildMarkdownStyleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        onTapLink: (text, href, title) {
          if (href != null) {
            _handleLinkTap(href);
          }
        },
        onTapText: widget.onTap,
      ),
    );
  }

  /// Build paragraph block
  Widget _buildParagraphBlock(MarkdownBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildContentWithMath(block.content),
    );
  }

  /// Build code block
  Widget _buildCodeBlock(MarkdownBlock block) {
    final settings = ref.watch(settingsProvider);
    final lines = block.content.split('\n');
    
    // Extract language from first line
    String language = '';
    String codeContent = block.content;
    
    if (lines.isNotEmpty && lines.first.startsWith('```')) {
      language = lines.first.substring(3).trim();
      if (lines.length > 2) {
        codeContent = lines.sublist(1, lines.length - 1).join('\n');
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CodeBlockWidget(
        codeBlock: CodeBlock(
          content: codeContent,
          language: ProgrammingLanguage.fromIdentifier(language),
          startLine: 1,
          endLine: codeContent.split('\n').length,
          showLineNumbers: true,
          showCopyButton: true,
        ),
        config: SyntaxHighlightConfig(
          fontFamily: settings.fontFamily,
        ),
      ),
    );
  }

  /// Build math block
  Widget _buildMathBlock(MarkdownBlock block) {
    final lines = block.content.split('\n');
    String mathContent = block.content;
    
    // Extract math content between $$
    if (lines.length > 2) {
      mathContent = lines.sublist(1, lines.length - 1).join('\n');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MathFormulaWidget(
        formula: MathFormula(
          type: MathType.block,
          content: mathContent,
          rawContent: block.content,
          startIndex: 0,
          endIndex: mathContent.length,
        ),
        textStyle: Theme.of(context).textTheme.bodyLarge,
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Math formula rendering error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  /// Build quote block
  Widget _buildQuoteBlock(MarkdownBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MarkdownBody(
        data: block.content,
        selectable: widget.selectable,
        styleSheet: _buildMarkdownStyleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        onTapLink: (text, href, title) {
          if (href != null) {
            _handleLinkTap(href);
          }
        },
        onTapText: widget.onTap,
      ),
    );
  }

  /// Build list block
  Widget _buildListBlock(MarkdownBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MarkdownBody(
        data: block.content,
        selectable: widget.selectable,
        styleSheet: _buildMarkdownStyleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        onTapLink: (text, href, title) {
          if (href != null) {
            _handleLinkTap(href);
          }
        },
        onTapText: widget.onTap,
      ),
    );
  }

  /// Build table block
  Widget _buildTableBlock(MarkdownBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MarkdownBody(
        data: block.content,
        selectable: widget.selectable,
        styleSheet: _buildMarkdownStyleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        onTapLink: (text, href, title) {
          if (href != null) {
            _handleLinkTap(href);
          }
        },
        onTapText: widget.onTap,
      ),
    );
  }

  /// Build horizontal rule block
  Widget _buildHorizontalRuleBlock(MarkdownBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MarkdownBody(
        data: block.content,
        selectable: widget.selectable,
        styleSheet: _buildMarkdownStyleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        onTapLink: (text, href, title) {
          if (href != null) {
            _handleLinkTap(href);
          }
        },
        onTapText: widget.onTap,
      ),
    );
  }

  /// Build plugin block
  Widget _buildPluginBlock(MarkdownBlock block) {
    // Process plugin elements
    final pluginElements = PluginBlockProcessor.processPluginBlock(block);
    
    if (pluginElements.isEmpty) {
      // No plugin elements found, treat as paragraph
      return _buildParagraphBlock(block);
    }
    
    // If only one plugin element that covers the entire block, return it directly
    if (pluginElements.length == 1 && 
        pluginElements.first.startIndex == 0 && 
        pluginElements.first.endIndex == block.content.length) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: pluginElements.first.widget,
      );
    }
    
    // Multiple plugin elements or mixed content, build mixed layout
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildMixedPluginContent(block.content, pluginElements),
    );
  }

  /// Build mixed content with plugin elements
  Widget _buildMixedPluginContent(String content, List<PluginElement> pluginElements) {
    final widgets = <Widget>[];
    int currentIndex = 0;

    for (final element in pluginElements) {
      // Add text before plugin element
      if (currentIndex < element.startIndex) {
        final textContent = content.substring(currentIndex, element.startIndex);
        if (textContent.trim().isNotEmpty) {
          widgets.add(_buildContentWithMath(textContent));
        }
      }

      // Add plugin widget
      widgets.add(element.widget);
      currentIndex = element.endIndex;
    }

    // Add remaining text
    if (currentIndex < content.length) {
      final remainingContent = content.substring(currentIndex);
      if (remainingContent.trim().isNotEmpty) {
        widgets.add(_buildContentWithMath(remainingContent));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Build content with math formulas support
  Widget _buildContentWithMath(String content) {
    // Parse math formulas
    final mathFormulas = MathParser.parseFormulas(content);
    
    if (mathFormulas.isEmpty) {
      // No math formulas, use normal Markdown rendering
      final settings = ref.watch(settingsProvider);
      return MarkdownBody(
        data: content,
        selectable: widget.selectable,
        styleSheet: _buildMarkdownStyleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        builders: {
          'code': _buildCustomCodeBlock,
        },
        onTapLink: (text, href, title) {
          if (href != null) {
            _handleLinkTap(href);
          }
        },
        onTapText: widget.onTap,
      );
    }

    // Has math formulas, needs special handling
    return _buildContentWithMathFormulas(content, mathFormulas);
  }

  /// Build content with math formulas
  Widget _buildContentWithMathFormulas(String content, List<MathFormula> mathFormulas) {
    if (mathFormulas.isEmpty) {
      // Fallback to normal rendering
      final settings = ref.watch(settingsProvider);
      return MarkdownBody(
        data: content,
        selectable: widget.selectable,
        styleSheet: _buildMarkdownStyleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        builders: {
          'code': _buildCustomCodeBlock,
        },
        onTapLink: (text, href, title) {
          if (href != null) {
            _handleLinkTap(href);
          }
        },
        onTapText: widget.onTap,
      );
    }

    // Build content with math formulas
    final widgets = <Widget>[];
    int lastEndIndex = 0;

    for (final formula in mathFormulas) {
      // Add text before this formula
      if (formula.startIndex > lastEndIndex) {
        final textBefore = content.substring(lastEndIndex, formula.startIndex);
        if (textBefore.trim().isNotEmpty) {
          widgets.add(_buildMarkdownSegment(textBefore));
        }
      }

      // Add math formula widget
      widgets.add(MathFormulaWidget(
        formula: formula,
        textStyle: Theme.of(context).textTheme.bodyLarge,
        onError: (error) {
          debugPrint('Math formula error: $error');
        },
      ));

      lastEndIndex = formula.endIndex;
    }

    // Add remaining text
    if (lastEndIndex < content.length) {
      final textAfter = content.substring(lastEndIndex);
      if (textAfter.trim().isNotEmpty) {
        widgets.add(_buildMarkdownSegment(textAfter));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Build markdown segment without math formulas
  Widget _buildMarkdownSegment(String content) {
    final settings = ref.watch(settingsProvider);
    return MarkdownBody(
      data: content,
      selectable: widget.selectable,
      styleSheet: _buildMarkdownStyleSheet(),
      extensionSet: md.ExtensionSet.gitHubFlavored,
      builders: {
        'code': _buildCustomCodeBlock,
      },
      onTapLink: (text, href, title) {
        if (href != null) {
          _handleLinkTap(href);
        }
      },
      onTapText: widget.onTap,
    );
  }

  /// Build preview toolbar
  Widget _buildPreviewToolbar() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.visibility,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.preview,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Export buttons
          _buildToolbarButton(
            icon: Icons.picture_as_pdf,
            tooltip: AppLocalizations.of(context)!.exportAsPdf,
            onPressed: () => _exportToPdf(),
          ),
          _buildToolbarButton(
            icon: Icons.html,
            tooltip: AppLocalizations.of(context)!.exportAsHtml,
            onPressed: () => _exportToHtml(),
          ),
          _buildToolbarButton(
            icon: Icons.refresh,
            tooltip: AppLocalizations.of(context)!.refreshPreview,
            onPressed: () => _refreshPreview(),
          ),
          // Debug: Cache statistics (only in debug mode)
          if (kDebugMode) ...[
            _buildToolbarButton(
              icon: Icons.analytics_outlined,
              tooltip: 'Cache Statistics',
              onPressed: () => _showCacheStatistics(),
            ),
            _buildToolbarButton(
              icon: Icons.speed_outlined,
              tooltip: 'Performance Report',
              onPressed: () => _showPerformanceReport(),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Build toolbar button
  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        iconSize: 16,
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(4),
        ),
      ),
    );
  }





  /// Custom code element builder that supports mermaid
  MarkdownElementBuilder get _buildCustomCodeBlock => MermaidCodeElementBuilder(ref);

  /// Build Markdown style sheet
  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settings = ref.watch(settingsProvider);
    
    return MarkdownStyleSheet(
      // Paragraph style
      p: textTheme.bodyLarge?.copyWith(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize.toDouble(),
        height: 1.6,
        color: theme.colorScheme.onSurface,
      ),
      
      // Heading styles
      h1: textTheme.headlineLarge?.copyWith(
        fontFamily: settings.fontFamily,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h2: textTheme.headlineMedium?.copyWith(
        fontFamily: settings.fontFamily,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h3: textTheme.headlineSmall?.copyWith(
        fontFamily: settings.fontFamily,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h4: textTheme.titleLarge?.copyWith(
        fontFamily: settings.fontFamily,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h5: textTheme.titleMedium?.copyWith(
        fontFamily: settings.fontFamily,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h6: textTheme.titleSmall?.copyWith(
        fontFamily: settings.fontFamily,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      
      // Code style
      code: TextStyle(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize.toDouble(),
        backgroundColor: theme.colorScheme.surfaceVariant,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      
      // Quote style
      blockquote: textTheme.bodyLarge?.copyWith(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize.toDouble(),
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      
      // Link style
      a: TextStyle(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize.toDouble(),
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      
      // List style
      listBullet: textTheme.bodyLarge?.copyWith(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize.toDouble(),
        color: theme.colorScheme.onSurface,
      ),
      
      // Table style
      tableHead: textTheme.bodyLarge?.copyWith(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize.toDouble(),
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      tableBody: textTheme.bodyLarge?.copyWith(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize.toDouble(),
        color: theme.colorScheme.onSurface,
      ),
      tableBorder: TableBorder.all(
        color: theme.dividerColor,
        width: 1,
      ),
      tableHeadAlign: TextAlign.center,
      tableCellsPadding: const EdgeInsets.all(8),
      
      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Handle link tap
  void _handleLinkTap(String href) async {
    try {
      final uri = Uri.parse(href);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open link: $href')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link format: $href')),
        );
      }
    }
  }

  /// Export as PDF
  void _exportToPdf() {
    _showExportDialog(ExportFormat.pdf);
  }

  /// Export as HTML
  void _exportToHtml() {
    _showExportDialog(ExportFormat.html);
  }

  /// Show export dialog with specified format
  void _showExportDialog(ExportFormat format) {
    // Get current document or create temporary document
    final currentDoc = ref.read(currentDocumentProvider);
    final l10n = AppLocalizations.of(context)!;
    final documentToExport = currentDoc ?? Document(
      id: 'temp_export',
      title: l10n.untitledDocument,
      content: widget.content,
      type: DocumentType.markdown,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    showExportDialog(context, documentToExport, initialFormat: format);
  }

  /// Refresh preview
  void _refreshPreview() {
    setState(() {
      markdownBlockCache.clear();
      _cachedBlocks.clear();
      _lastRenderedContent = '';
    });
  }

  /// Show cache statistics (debug only)
  void _showCacheStatistics() {
    if (!kDebugMode) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                markdownBlockCache.getEfficiencyReport(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              markdownBlockCache.clear();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear Cache'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show performance report (debug only)
  void _showPerformanceReport() {
    if (!kDebugMode) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                performanceMonitor.getPerformanceReport(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              performanceMonitor.clear();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Performance metrics cleared')),
              );
            },
            child: const Text('Clear Metrics'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Math formula builder
class MathElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'math') {
      final mathContent = element.textContent;
      try {
        return Math.tex(
          mathContent,
          textStyle: preferredStyle ?? const TextStyle(),
        );
      } catch (e) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Math formula parsing error: $mathContent',
            style: TextStyle(color: Colors.red),
          ),
        );
      }
    }
    return null;
  }
}

/// Code block builder
class CodeElementBuilder extends MarkdownElementBuilder {
  CodeElementBuilder({required this.fontFamily});
  
  final String fontFamily;
  
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'code') {
      final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';
      final code = element.textContent;
      
      return CodeBlockWidget(
        codeBlock: CodeBlock(
          content: code,
          language: ProgrammingLanguage.fromIdentifier(language),
          startLine: 1,
          endLine: code.split('\n').length,
          showLineNumbers: true,
          showCopyButton: true,
        ),
        config: SyntaxHighlightConfig(
          fontFamily: fontFamily,
        ),
      );
    }
    return null;
  }
}

/// Custom code element builder that supports Mermaid charts
class MermaidCodeElementBuilder extends MarkdownElementBuilder {
  MermaidCodeElementBuilder(this.ref);
  
  final WidgetRef ref;
  
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Check if this is a code block element
    if (element.tag == 'pre') {
      // Get the first child (should be a code element)
      final children = element.children;
      if (children != null && children.isNotEmpty) {
        final firstChild = children.first;
        if (firstChild is md.Element && firstChild.tag == 'code') {
          final textContent = firstChild.textContent;
          final className = firstChild.attributes['class'] ?? '';
          
          // Check if this is a mermaid code block
          if (className.startsWith('language-mermaid')) {
            return _buildMermaidChart(textContent);
          }
        }
      }
    }
    
    // Fall back to default code block rendering
    final settings = ref.watch(settingsProvider);
    return CodeElementBuilder(fontFamily: settings.fontFamily).visitElementAfter(element, preferredStyle);
  }
  
  /// Build mermaid chart widget
  Widget _buildMermaidChart(String content) {
    try {
      final contextService = PluginContextService.instance;
      final syntaxRegistry = contextService.syntaxRegistry;
      final blockRules = syntaxRegistry.blockSyntaxRules;
      
      // Look for mermaid block syntax rule
      final mermaidRule = blockRules['mermaid'];
      if (mermaidRule != null) {
        // Use plugin to render mermaid
        final fullContent = '```mermaid\n$content\n```';
        return mermaidRule.builder(fullContent);
      }
    } catch (e) {
      debugPrint('Error rendering mermaid with plugin: $e');
    }
    
    // Fallback: show as mermaid placeholder
    final settings = ref.watch(settingsProvider);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mermaid Chart',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontFamily: settings.fontFamily,
                fontSize: settings.fontSize * 0.9,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading Mermaid plugin...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

