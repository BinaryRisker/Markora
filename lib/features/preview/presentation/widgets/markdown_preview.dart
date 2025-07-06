import 'dart:async';
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

import '../../../math/domain/services/math_parser.dart';
import '../../../math/presentation/widgets/math_formula_widget.dart';
import '../../../syntax_highlighting/presentation/widgets/code_block_widget.dart';

import '../../../plugins/domain/plugin_implementations.dart';
import '../../../export/presentation/widgets/export_dialog.dart';
import '../../../export/domain/entities/export_settings.dart';
import '../../../document/presentation/providers/document_providers.dart';



/// Render cache item
class _RenderCacheItem {
  const _RenderCacheItem({
    required this.content,
    required this.widget,
    required this.timestamp,
  });

  final String content;
  final Widget widget;
  final DateTime timestamp;
}

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
  
  // Performance optimization related
  Timer? _debounceTimer;
  String _lastRenderedContent = '';
  Widget? _cachedWidget;
  final Map<String, _RenderCacheItem> _renderCache = {};
  static const int _maxCacheSize = 10;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Track current language to detect changes
  String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if language has changed
    final newLanguage = Localizations.localeOf(context).languageCode;
    if (_currentLanguage != null && _currentLanguage != newLanguage) {
      // Language changed, clear cache and force rebuild
      _renderCache.clear();
      _cachedWidget = null;
      _lastRenderedContent = '';
    }
    _currentLanguage = newLanguage;
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
    // Get current language for cache key
    final currentLanguage = Localizations.localeOf(context).languageCode;
    
    // If content hasn't changed and language hasn't changed, return cached widget
    if (widget.content == _lastRenderedContent && _cachedWidget != null) {
      return _cachedWidget!;
    }

    // Check cache (include language in cache key)
    final cacheKey = '${widget.content.hashCode}_$currentLanguage';
    final cachedItem = _renderCache[cacheKey];
    
    if (cachedItem != null) {
      // Check if cache is expired
      final now = DateTime.now();
      if (now.difference(cachedItem.timestamp) < _cacheExpiry) {
        _lastRenderedContent = widget.content;
        _cachedWidget = cachedItem.widget;
        return cachedItem.widget;
      } else {
        // Cache expired, remove it
        _renderCache.remove(cacheKey);
      }
    }

    // Use debounce mechanism
    _debounceTimer?.cancel();
    
    // If first render or content is empty, render immediately
    if (_cachedWidget == null || widget.content.isEmpty) {
      return _renderAndCache();
    }

    // For content changes, use debounce
    _debounceTimer = Timer(_debounceDelay, () {
      if (mounted) {
        setState(() {
          _renderAndCache();
        });
      }
    });

    // Return current cached widget (display during debounce)
    return _cachedWidget ?? _buildLoadingWidget();
  }

  /// Render and cache content
  Widget _renderAndCache() {
    final widget = _buildMarkdownContent();
    final currentLanguage = Localizations.localeOf(context).languageCode;
    final cacheKey = '${this.widget.content.hashCode}_$currentLanguage';
    
    // Clean expired cache
    _cleanExpiredCache();
    
    // Limit cache size
    if (_renderCache.length >= _maxCacheSize) {
      final oldestKey = _renderCache.keys.first;
      _renderCache.remove(oldestKey);
    }
    
    // Add to cache
    _renderCache[cacheKey] = _RenderCacheItem(
      content: this.widget.content,
      widget: widget,
      timestamp: DateTime.now(),
    );
    
    _lastRenderedContent = this.widget.content;
    _cachedWidget = widget;
    
    return widget;
  }

  /// Clean expired cache
  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _renderCache.entries) {
      if (now.difference(entry.value.timestamp) >= _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _renderCache.remove(key);
    }
  }

  /// Build loading widget
  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
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

  /// Build Markdown content
  Widget _buildMarkdownContent() {
    if (widget.content.isEmpty) {
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

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: _buildContentWithMath(),
      ),
    );
  }

  /// Build content with math formulas and plugin content
  Widget _buildContentWithMath() {
    // First process plugin registered block syntax
    final processedContent = _processPluginSyntax(widget.content);
    
    // Parse math formulas
    final mathFormulas = MathParser.parseFormulas(processedContent.content);
    
    if (mathFormulas.isEmpty && processedContent.pluginWidgets.isEmpty) {
      // No special content, use normal Markdown rendering
      return MarkdownBody(
        data: processedContent.content,
        selectable: widget.selectable,
        styleSheet: _buildMarkdownStyleSheet(),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        builders: {
          'code': CodeElementBuilder(),
        },
        onTapLink: (text, href, title) {
          if (href != null) {
            _handleLinkTap(href);
          }
        },
        onTapText: widget.onTap,
      );
    }

    // Has special content, needs special handling
    return _buildMixedContent(mathFormulas, processedContent.pluginWidgets);
  }

  /// Build mixed content (text + math formulas + plugin components)
  Widget _buildMixedContent(List<MathFormula> mathFormulas, List<_PluginElement> pluginElements) {
    final widgets = <Widget>[];
    
    // Merge all special elements and sort by position
    final allElements = <_SpecialElement>[];
    
    // Add math formulas
    for (final formula in mathFormulas) {
      allElements.add(_SpecialElement(
        type: _SpecialElementType.math,
        startIndex: formula.startIndex,
        endIndex: formula.endIndex,
        data: formula,
      ));
    }
    
    // Add plugin components
    for (final pluginElement in pluginElements) {
      allElements.add(_SpecialElement(
        type: _SpecialElementType.plugin,
        startIndex: pluginElement.start,
        endIndex: pluginElement.end,
        data: pluginElement.widget,
      ));
    }
    
    // Sort by position
    allElements.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    int currentIndex = 0;

    for (final element in allElements) {
      // Add normal text before element
      if (currentIndex < element.startIndex) {
        final textContent = widget.content.substring(currentIndex, element.startIndex);
        if (textContent.trim().isNotEmpty) {
          widgets.add(MarkdownBody(
            data: textContent,
            selectable: widget.selectable,
            styleSheet: _buildMarkdownStyleSheet(),
            extensionSet: md.ExtensionSet.gitHubFlavored,
            builders: {
              'code': CodeElementBuilder(),
            },
            onTapLink: (text, href, title) {
              if (href != null) {
                _handleLinkTap(href);
              }
            },
            onTapText: widget.onTap,
          ));
        }
      }

      // Add special element
      if (element.type == _SpecialElementType.math) {
        final formula = element.data as MathFormula;
        widgets.add(MathFormulaWidget(
          formula: formula,
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
        ));
      } else if (element.type == _SpecialElementType.plugin) {
        final widget = element.data as Widget;
        widgets.add(widget);
      }

      currentIndex = element.endIndex;
    }

    // Add remaining text at the end
    if (currentIndex < widget.content.length) {
      final remainingContent = widget.content.substring(currentIndex);
      if (remainingContent.trim().isNotEmpty) {
        widgets.add(MarkdownBody(
          data: remainingContent,
          selectable: widget.selectable,
          styleSheet: _buildMarkdownStyleSheet(),
          extensionSet: md.ExtensionSet.gitHubFlavored,
          builders: {
            'code': CodeElementBuilder(),
          },
          onTapLink: (text, href, title) {
            if (href != null) {
              _handleLinkTap(href);
            }
          },
          onTapText: widget.onTap,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Build Markdown style sheet
  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return MarkdownStyleSheet(
      // Paragraph style
      p: textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurface,
      ),
      
      // Heading styles
      h1: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h2: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h3: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h4: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h5: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h6: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      
      // Code style
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: textTheme.bodyMedium?.fontSize,
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
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      
      // List style
      listBullet: textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      
      // Table style
      tableHead: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      tableBody: textTheme.bodyLarge?.copyWith(
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
      // Force rebuild preview
    });
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
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'code') {
      final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';
      final code = element.textContent;
      
      return SimpleCodeBlock(
        code: code,
        language: language.isNotEmpty ? language : null,
        showLineNumbers: true,
        showCopyButton: true,
      );
    }
    return null;
  }
}

/// Special element type
enum _SpecialElementType {
  math,   // Math formula
  plugin, // Plugin component
}

/// Special element
class _SpecialElement {
  const _SpecialElement({
    required this.type,
    required this.startIndex,
    required this.endIndex,
    required this.data,
  });

  final _SpecialElementType type;
  final int startIndex;
  final int endIndex;
  final dynamic data;
}

/// Plugin element
class _PluginElement {
  const _PluginElement({
    required this.start,
    required this.end,
    required this.content,
    required this.widget,
  });

  final int start;
  final int end;
  final String content;
  final Widget widget;
}

/// Processed content
class _ProcessedContent {
  const _ProcessedContent({
    required this.content,
    required this.pluginWidgets,
  });

  final String content;
  final List<_PluginElement> pluginWidgets;
}

/// Process plugin syntax
_ProcessedContent _processPluginSyntax(String content) {
  final pluginWidgets = <_PluginElement>[];
  String processedContent = content;
  int offset = 0;

  try {
    // Get global syntax registry
     final syntaxRegistry = globalSyntaxRegistry;
     final blockRules = syntaxRegistry.blockSyntaxRules;

    for (final rule in blockRules.values) {
      final matches = rule.pattern.allMatches(content);
      
      for (final match in matches) {
        try {
          final widget = rule.builder(match.group(0)!);
          pluginWidgets.add(_PluginElement(
            start: match.start - offset,
            end: match.end - offset,
            content: match.group(0)!,
            widget: widget,
          ));
          
          // Remove matched text from content
           final before = processedContent.substring(0, match.start - offset);
           final after = processedContent.substring(match.end - offset);
           processedContent = before + after;
           offset += (match.end - match.start);
        } catch (e) {
          // Plugin rendering error, skip
          print('Plugin syntax error: $e');
        }
      }
    }
  } catch (e) {
    print('Error processing plugin syntax: $e');
  }

  return _ProcessedContent(
    content: processedContent,
    pluginWidgets: pluginWidgets,
  );
}