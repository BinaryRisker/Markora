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
import 'features/document/presentation/widgets/file_dialog.dart';
import 'features/document/domain/services/file_service.dart';
import 'features/document/presentation/widgets/document_tabs.dart';
import 'features/document/presentation/widgets/save_as_dialog.dart';
import 'features/settings/presentation/widgets/settings_page.dart';
import 'features/export/presentation/widgets/export_dialog.dart';
import 'features/editor/domain/services/global_editor_manager.dart';
import 'features/plugins/presentation/pages/plugin_management_page.dart';

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
      _updateSampleDocuments();
    });
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
          _buildToolbarButton(
            icon: Icon(PhosphorIconsRegular.export),
            tooltip: AppLocalizations.of(context)!.exportDocument,
            onPressed: () => _handleExportDocument(),
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

  /// Handle save as
  void _handleSaveAsDocument() async {
    try {
      final activeDocument = ref.read(activeDocumentProvider);
      final l10n = AppLocalizations.of(context)!;
      final documentToSave = activeDocument ?? Document(
        id: 'temp_save',
        title: l10n.newDocument,
        content: _currentContent,
        type: DocumentType.markdown,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await showDialog<SaveResult>(
        context: context,
        builder: (context) => SaveAsDialog(
          document: documentToSave,
          initialFormat: SaveFormat.markdown,
        ),
      );

      if (result != null) {
        // Save file according to selected format
        await _saveFileWithFormat(documentToSave, result);
        
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.documentSavedAs}: ${result.fileName}')),
          );
        }
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

  /// Save file according to format
  Future<void> _saveFileWithFormat(Document document, SaveResult result) async {
    // File has already been saved to disk in SaveAsDialog
    // Here we only need to update document info in Tab
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    
    // Update document title to filename (without extension)
    final fileNameWithoutExt = result.fileName.replaceAll(RegExp(r'\.[^.]*$'), '');
    final updatedDocument = document.copyWith(
      title: fileNameWithoutExt,
      updatedAt: DateTime.now(),
    );
    
    // Save to Hive database
    await ref.read(documentServiceProvider).saveDocument(updatedDocument);
    
    // If document is in Tab, update Tab
    final activeIndex = tabsNotifier.activeTabIndex;
    if (activeIndex >= 0) {
      final tabs = ref.read(documentTabsProvider);
      if (activeIndex < tabs.length && tabs[activeIndex].document.id == document.id) {
        // Update current Tab's document info
        tabsNotifier.updateTabContent(activeIndex, updatedDocument.content);
      }
    }
  }

  void _handleExportDocument() {
    // Get current document or create temporary document
    final currentDoc = ref.read(currentDocumentProvider);
    final l10n = AppLocalizations.of(context)!;
    final documentToExport = currentDoc ?? Document(
      id: 'temp_export',
      title: l10n.untitledDocument,
      content: _currentContent,
      type: DocumentType.markdown,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    showExportDialog(context, documentToExport);
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