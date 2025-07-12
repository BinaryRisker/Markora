import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'l10n/app_localizations.dart';

import 'core/constants/app_constants.dart';
import 'types/editor.dart';
import 'types/document.dart';
import 'features/editor/presentation/widgets/markdown_editor.dart';
import 'features/preview/presentation/widgets/markdown_preview.dart';
import 'features/document/presentation/providers/document_providers.dart';
import 'features/document/domain/services/file_service.dart';
import 'features/document/presentation/widgets/document_tabs.dart';
import 'features/settings/presentation/widgets/settings_page.dart';

import 'features/editor/domain/services/global_editor_manager.dart';
import 'features/plugins/presentation/pages/plugin_management_page.dart';
import 'features/plugins/domain/plugin_context_service.dart';
import 'features/plugins/domain/plugin_manager.dart';

import 'core/utils/markdown_block_cache.dart';

/// Application shell - main interface container
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Current editor mode
  EditorMode _currentMode = EditorMode.split;
  
  // Split ratio (editor:preview)
  double _splitRatio = AppConstants.defaultSplitRatio;
  
  // Plugin toolbar refresh trigger
  int _pluginToolbarRefreshKey = 0;
  
  // Current document content
  String get _currentContent {
    final l10n = AppLocalizations.of(context)!;
    return '''# ${l10n.welcomeTitle}

${l10n.welcomeDescription}

## ${l10n.coreFeatures}

- **${l10n.realtimePreview}** - ${l10n.realtimePreviewDesc}
- **${l10n.syntaxHighlighting}** - ${l10n.syntaxHighlightingDesc}
- **${l10n.mathFormulas}** - ${l10n.mathFormulasDesc}
- **${l10n.chartSupport}** - ${l10n.chartSupportDesc}

## ${l10n.quickStart}

1. ${l10n.quickStartStep1}
2. ${l10n.quickStartStep2}
3. ${l10n.quickStartStep3}

### ${l10n.codeExample}

```dart
void main() {
  print('Hello, Markora!');
}
```

### Math Formulas

${l10n.inlineFormula}：\$E = mc^2\$

${l10n.blockFormula}：
\$\$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}\$\$

### Table

| ${l10n.feature} | ${l10n.status} | ${l10n.description} |
|------|------|------|
| ${l10n.editor} | ✅ | ${l10n.completed} |
| ${l10n.preview} | ✅ | ${l10n.completed} |
| Math | 🚧 | In Development |

> ${l10n.startJourney}
''';
  }
  
  // Cursor position
  CursorPosition _cursorPosition = const CursorPosition(line: 0, column: 0, offset: 0);

  @override
  void initState() {
    super.initState();
    // Update sample documents with localized content after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlugins();
      _updateSampleDocuments();
    });
  }
  
  /// Initialize plugins
  Future<void> _initializePlugins() async {
    try {
      debugPrint('Initializing plugin system...');
      
      // Initialize plugin context service
      final contextService = PluginContextService.instance;
      contextService.initialize();
      debugPrint('Plugin context service initialized');
      
      // Setup plugin listeners BEFORE initializing plugin manager
      _setupPluginListeners(contextService);
      
      // Initialize plugin manager with context
      final pluginManager = PluginManager.instance;
      await pluginManager.initialize(contextService.context);
      debugPrint('Plugin manager initialized');
      
      // Wait a bit for plugins to load
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if plugins are loaded
      final syntaxRegistry = contextService.syntaxRegistry;
      final blockRules = syntaxRegistry.blockSyntaxRules;
      debugPrint('Available plugins after initialization: ${blockRules.keys.toList()}');
      
      // Force multiple toolbar refreshes to ensure UI updates
      if (mounted) {
        setState(() {
          _pluginToolbarRefreshKey++;
        });
        debugPrint('Triggered initial toolbar refresh after plugin initialization');
        
        // Additional delayed refresh to handle any timing issues
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _pluginToolbarRefreshKey++;
          });
          debugPrint('Triggered delayed toolbar refresh');
        }
        
        // Clear preview cache to force re-rendering with new plugins
        _clearPreviewCache();
      }
      
      debugPrint('Plugin system initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize plugins: $e');
    }
  }

  /// Setup plugin listeners
  void _setupPluginListeners(PluginContextService contextService) {
    try {
      final toolbarRegistry = contextService.toolbarRegistry;
      
      toolbarRegistry.addChangeListener(() {
        debugPrint('Toolbar registry change detected, refreshing UI...');
        if (mounted) {
          setState(() {
            _pluginToolbarRefreshKey++;
          });
          debugPrint('Toolbar refresh triggered: key = $_pluginToolbarRefreshKey');
        }
      });
      
      debugPrint('Plugin toolbar listeners setup completed');
    } catch (e) {
      debugPrint('Failed to setup plugin listeners: $e');
    }
  }

  /// Clear preview cache to force re-rendering with new plugins
  void _clearPreviewCache() {
    try {
      markdownBlockCache.clear();
      debugPrint('Preview cache cleared after plugin initialization');
    } catch (e) {
      debugPrint('Failed to clear preview cache: $e');
    }
  }

  /// Update sample documents with localized content
  Future<void> _updateSampleDocuments() async {
    try {
      final repository = ref.read(documentRepositoryProvider);
      final documents = await repository.getAllDocuments();
      
      // Find and update the welcome document
      for (final doc in documents) {
        if (doc.title == AppLocalizations.of(context)!.welcomeDocument) {
          final l10n = AppLocalizations.of(context)!;
          final updatedDoc = doc.copyWith(
            title: l10n.welcomeTitle,
            content: _currentContent,
            updatedAt: DateTime.now(),
          );
          await repository.saveDocument(updatedDoc);
          break;
        }
      }
    } catch (e) {
      // Ignore errors during sample document update
      debugPrint('Failed to update sample documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          _buildToolbar(),
          
          // Document tab bar
          const DocumentTabs(),
          
          // Main content area
          Expanded(
            child: _buildContent(),
          ),
          
          // Status bar
          _buildStatusBar(),
        ],
      ),
    );
  }

  /// Build toolbar
  Widget _buildToolbar() {
    return Container(
      key: ValueKey('toolbar_$_pluginToolbarRefreshKey'),
      height: AppConstants.toolbarHeight,
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
          // File operation buttons
          _buildToolbarButton(
            icon: Icon(PhosphorIconsRegular.file),
            tooltip: AppLocalizations.of(context)!.newDocument,
            onPressed: () => _handleNewDocument(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIconsRegular.folderOpen),
            tooltip: AppLocalizations.of(context)!.openDocument,
            onPressed: () => _handleOpenDocument(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIconsRegular.floppyDisk),
            tooltip: AppLocalizations.of(context)!.saveDocument,
            onPressed: () => _handleSaveDocument(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIconsRegular.copySimple),
            tooltip: AppLocalizations.of(context)!.saveAs,
            onPressed: () => _handleSaveAsDocument(),
          ),
          
          const VerticalDivider(),
          
          // Edit operation buttons
          Consumer(
            builder: (context, ref, child) {
              final undoRedoState = ref.watch(globalUndoRedoStateProvider);
              return _buildToolbarButton(
                icon: Icon(PhosphorIconsRegular.arrowUUpLeft),
                tooltip: AppLocalizations.of(context)!.undo,
                onPressed: undoRedoState.canUndo ? () => _handleUndo() : null,
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final undoRedoState = ref.watch(globalUndoRedoStateProvider);
              return _buildToolbarButton(
                icon: Icon(PhosphorIconsRegular.arrowUUpRight),
                tooltip: AppLocalizations.of(context)!.redo,
                onPressed: undoRedoState.canRedo ? () => _handleRedo() : null,
              );
            },
          ),
          
          const VerticalDivider(),
          
          // Plugin buttons with refresh key
              ...(_pluginToolbarRefreshKey >= 0 ? _buildPluginButtons() : <Widget>[]),
          
          const Spacer(),
          
          // View mode toggle
          _buildModeToggle(),
          
          const SizedBox(width: 8),
          
          // Plugin management button
          _buildToolbarButton(
            icon: Icon(PhosphorIconsRegular.package),
            tooltip: AppLocalizations.of(context)!.pluginManagement,
            onPressed: () => _handlePluginManagement(),
          ),
          
          // Settings button
          _buildToolbarButton(
            icon: Icon(PhosphorIconsRegular.gear),
            tooltip: AppLocalizations.of(context)!.settings,
            onPressed: () => _handleSettings(),
          ),
        ],
      ),
    );
  }

  /// Build toolbar button
  Widget _buildToolbarButton({
    required Widget icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        iconSize: 20,
      ),
    );
  }

  /// Build plugin buttons
  List<Widget> _buildPluginButtons() {
    try {
      final contextService = ref.read(pluginContextServiceProvider);
      final toolbarRegistry = contextService.toolbarRegistry;
      final actions = toolbarRegistry.actions;
      
      debugPrint('Building plugin buttons - refresh key: $_pluginToolbarRefreshKey');
       debugPrint('Number of toolbar actions available: ${actions.length}');
       for (final entry in actions.entries) {
         debugPrint('  - Action ID: ${entry.key}, Title: ${entry.value.action.title}');
       }
      
      if (actions.isEmpty) {
        debugPrint('No plugin actions available, returning empty list');
        return [];
      }
      
      final buttons = <Widget>[];
      
      for (final actionItem in actions.values) {
        final action = actionItem.action;
        buttons.add(
          _buildToolbarButton(
            icon: _getIconFromString(action.icon ?? 'default'),
            tooltip: action.description,
            onPressed: () {
              debugPrint('Execute plugin action: ${action.title}');
              try {
                // Ensure plugin context has current BuildContext
                final contextService = ref.read(pluginContextServiceProvider);
                contextService.setBuildContext(context);
                
                actionItem.callback();
              } catch (e) {
                debugPrint('Plugin action failed: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('插件操作失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        );
      }
      
      debugPrint('Generated ${buttons.length} plugin buttons');
      return buttons;
    } catch (e) {
      debugPrint('Failed to build plugin buttons: $e');
      return [];
    }
  }

  /// Get icon from string
  Widget _getIconFromString(String iconName) {
    switch (iconName) {
      case 'account_tree':
        return Icon(PhosphorIconsRegular.tree);
      case 'code':
        return Icon(PhosphorIconsRegular.code);
      case 'insert_chart':
        return Icon(PhosphorIconsRegular.chartBar);
      case 'functions':
        return Icon(PhosphorIconsRegular.function);
      case 'export':
        return Icon(PhosphorIconsRegular.export);
      case 'import':
        return Icon(PhosphorIconsRegular.download);
      default:
        return Icon(PhosphorIconsRegular.plugs);
    }
  }

  /// Build mode toggle
  Widget _buildModeToggle() {
    return ToggleButtons(
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(
        minHeight: 32,
        minWidth: 32,
      ),
      isSelected: [
        _currentMode == EditorMode.source,
        _currentMode == EditorMode.split,
        _currentMode == EditorMode.preview,
      ],
      onPressed: (index) {
        setState(() {
          switch (index) {
            case 0:
              _currentMode = EditorMode.source;
              break;
            case 1:
              _currentMode = EditorMode.split;
              break;
            case 2:
              _currentMode = EditorMode.preview;
              break;
          }
        });
      },
      children: [
        Tooltip(
          message: AppLocalizations.of(context)!.sourceMode,
          child: Icon(PhosphorIconsRegular.code, size: 16),
        ),
        Tooltip(
          message: AppLocalizations.of(context)!.splitMode,
          child: Icon(PhosphorIconsRegular.columns, size: 16),
        ),
        Tooltip(
          message: AppLocalizations.of(context)!.previewMode,
          child: Icon(PhosphorIconsRegular.eye, size: 16),
        ),
      ],
    );
  }

  /// Build main content area
  Widget _buildContent() {
    switch (_currentMode) {
      case EditorMode.source:
        return _buildEditor();
      case EditorMode.preview:
        return _buildPreview();
      case EditorMode.split:
        return _buildSplitView();
      case EditorMode.live:
        return _buildLiveEditor();
    }
  }

  /// Build editor
  Widget _buildEditor() {
    final activeDocument = ref.watch(activeDocumentProvider);
    final content = activeDocument?.content ?? '';
    
    return MarkdownEditor(
      initialContent: content,
      onChanged: (content) {
        // Remove setState call as content is managed by Tab system
        // Tab system will automatically handle content synchronization
      },
      onCursorPositionChanged: (position) {
        setState(() {
          _cursorPosition = position;
        });
      },
    );
  }

  /// Build preview
  Widget _buildPreview() {
    final activeDocument = ref.watch(activeDocumentProvider);
    final content = activeDocument?.content ?? '';
    
    return MarkdownPreview(
      content: content,
    );
  }

  /// Build split view
  Widget _buildSplitView() {
    return Row(
      children: [
        // Editor area
        Expanded(
          flex: (_splitRatio * 100).round(),
          child: _buildEditor(),
        ),
        
        // Divider
        GestureDetector(
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final double newRatio = details.localPosition.dx / box.size.width;
            setState(() {
              _splitRatio = newRatio.clamp(0.2, 0.8);
            });
          },
          child: Container(
            width: 4,
            color: Theme.of(context).dividerColor,
            child: const Center(
              child: Icon(
                Icons.drag_indicator,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        
        // Preview area
        Expanded(
          flex: ((1 - _splitRatio) * 100).round(),
          child: _buildPreview(),
        ),
      ],
    );
  }

  /// Build live editor
  Widget _buildLiveEditor() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: const Center(
        child: Text(
          'Live Editor\n(Coming Soon)',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Build status bar
  Widget _buildStatusBar() {
    final activeDocument = ref.watch(activeDocumentProvider);
    final tabs = ref.watch(documentTabsProvider);
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    
    return Container(
      height: AppConstants.statusBarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (activeDocument != null) ...[
              Text(
                '${activeDocument.title} | ${activeDocument.content.length} characters',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              if (tabsNotifier.activeTabIndex >= 0 && 
                  tabsNotifier.activeTabIndex < tabs.length &&
                  tabs[tabsNotifier.activeTabIndex].isModified) ...[
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Modified',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ] else ...[                Text(
                AppLocalizations.of(context)!.noOpenDocuments,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
            const Spacer(),
            if (activeDocument != null) ...[
              Text(
                'Ln ${_cursorPosition.line + 1}, Col ${_cursorPosition.column + 1}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Event handling methods
  void _handleNewDocument() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final tabsNotifier = ref.read(documentTabsProvider.notifier);
      await tabsNotifier.createNewDocumentTab(
        title: l10n.newDocument,
        content: '# ${l10n.newDocument}\n\n${l10n.startCreating}',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.documentCreated)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.createDocumentFailed}: $e')),
        );
      }
    }
  }

  void _handleOpenDocument() async {
    try {
      final fileService = FileService();
      Document document;
      
      // Choose different file loading methods based on environment
      if (kIsWeb) {
        // Call Web-specific method directly in Web environment
        document = await fileService.loadDocumentFromWeb();
      } else {
        // Use traditional method in non-Web environment
        final filePath = await fileService.selectOpenFilePath(
          dialogTitle: AppLocalizations.of(context)!.openMarkdownFile,
          allowedExtensions: ['md', 'markdown', 'txt'],
        );
        
        if (filePath == null) return; // User cancelled selection
        
        document = await fileService.loadDocumentFromFile(filePath);
      }
      
      // Add to Tab
      final tabsNotifier = ref.read(documentTabsProvider.notifier);
      tabsNotifier.openDocumentTab(document);
      
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.documentOpened}: ${document.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.openDocumentFailed}: $e')),
        );
      }
    }
  }

  void _handleSaveDocument() async {
    try {
      final tabsNotifier = ref.read(documentTabsProvider.notifier);
      final activeDocument = ref.read(activeDocumentProvider);
      
      // If there's an active document, save directly
      if (activeDocument != null) {
        await tabsNotifier.saveActiveTab();
        
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.documentSaved)),
          );
        }
      } else {
        // If no active document, show save as dialog
        _handleSaveAsDocument();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.saveFailed}: $e')),
        );
      }
    }
  }

  /// Handle "Save As" document
  Future<void> _handleSaveAsDocument() async {
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    if (tabsNotifier.activeDocument == null) return;

    final fileService = ref.read(fileServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final currentDocument = tabsNotifier.activeDocument!;
    final initialFileName = '${currentDocument.title}.md';

    try {
      final filePath = await fileService.saveFile(
        dialogTitle: l10n.saveAs,
        fileName: initialFileName,
      );

      if (filePath != null) {
        await tabsNotifier.saveAsActiveTab(newPath: filePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.documentSavedAs(filePath))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(l10n.saveAsError, e.toString());
      }
    }
  }

  /// Handle "Export" document
  Future<void> _handleExportDocument() async {
    // This feature is now handled by plugins, this button should be removed
  }

  void _handleUndo() {
    final globalEditorManager = ref.read(globalEditorManagerProvider);
    globalEditorManager.undo();
  }

  void _handleRedo() {
    final globalEditorManager = ref.read(globalEditorManagerProvider);
    globalEditorManager.redo();
  }

  void _handlePluginManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PluginManagementPage(),
      ),
    );
  }

  void _handleSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }
}