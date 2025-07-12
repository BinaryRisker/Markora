import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;

import '../../../../core/themes/app_theme.dart';
import '../../../../types/editor.dart';
import '../../../math/domain/services/math_parser.dart';
import '../../../math/presentation/widgets/math_formula_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

import '../../../document/presentation/providers/document_providers.dart';
import '../../domain/services/undo_redo_manager.dart';
import '../../domain/services/global_editor_manager.dart';
import '../../../plugins/domain/plugin_context_service.dart';
import '../../../plugins/domain/plugin_implementations.dart';
import '../../../../main.dart';

/// Markdown editor component
class MarkdownEditor extends ConsumerStatefulWidget {
  const MarkdownEditor({
    super.key,
    this.initialContent = '',
    this.onChanged,
    this.onCursorPositionChanged,
    this.readOnly = false,
  });

  /// Initial content
  final String initialContent;
  
  /// Content change callback
  final ValueChanged<String>? onChanged;
  
  /// Cursor position change callback
  final ValueChanged<CursorPosition>? onCursorPositionChanged;
  
  /// Whether read-only
  final bool readOnly;

  @override
  ConsumerState<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends ConsumerState<MarkdownEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late UndoRedoManager _undoRedoManager;
  String _lastSyncedContent = '';
  bool _isApplyingUndoRedo = false;
  String? _tabId;
  
  // Track current language to detect changes
  String? _currentLanguage;
  
  @override
  void initState() {
    super.initState();
    
    _focusNode = FocusNode();
    _undoRedoManager = UndoRedoManager();
    
    // Initialize text editor controller
    _controller = TextEditingController(text: widget.initialContent);
    _lastSyncedContent = widget.initialContent;
    
    // Add initial state to undo manager
    if (widget.initialContent.isNotEmpty) {
      _undoRedoManager.addState(EditorHistoryState(
        text: widget.initialContent,
        selection: TextSelection.collapsed(offset: widget.initialContent.length),
        timestamp: DateTime.now(),
      ));
    }
    
    // Listen to text changes
    _controller.addListener(_onTextChanged);
    
    // Delay registration to global editor manager, ensure ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerToGlobalManager();
      _registerToPluginSystem();
    });
  }
  
  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When component updates, check if need to update active tab in global manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateActiveTab();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if language has changed
    final newLanguage = Localizations.localeOf(context).languageCode;
    if (_currentLanguage != null && _currentLanguage != newLanguage) {
      // Language changed, force rebuild by calling setState
      if (mounted) {
        setState(() {
          // This will trigger a rebuild of the widget tree
        });
      }
    }
    _currentLanguage = newLanguage;
  }

  @override
  void dispose() {
    _unregisterFromGlobalManager();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Register to global editor manager
  void _registerToGlobalManager() {
    if (mounted) {
      final globalManager = ref.read(globalEditorManagerProvider);
      final activeDocument = ref.read(activeDocumentProvider);
      if (activeDocument != null) {
        _tabId = activeDocument.id;
        globalManager.registerEditor(
          tabId: _tabId!,
          undoRedoManager: _undoRedoManager,
          undoCallback: _undo,
          redoCallback: _redo,
        );
        // Set as active tab
        globalManager.setActiveTab(_tabId!);
      }
    }
  }

  /// Unregister from global editor manager
  void _unregisterFromGlobalManager() {
    if (_tabId != null && mounted) {
      final globalManager = ref.read(globalEditorManagerProvider);
      globalManager.unregisterEditor(_tabId!);
    }
  }
  
  /// Update active tab
  void _updateActiveTab() {
    if (mounted) {
      final activeDocument = ref.read(activeDocumentProvider);
      if (activeDocument != null && _tabId != activeDocument.id) {
        // Tab has changed, re-register
        _unregisterFromGlobalManager();
        _registerToGlobalManager();
        _registerToPluginSystem();
      } else if (activeDocument != null && _tabId == activeDocument.id) {
        // Ensure current tab is active
        final globalManager = ref.read(globalEditorManagerProvider);
        globalManager.setActiveTab(_tabId!);
      }
    }
  }

  /// Register to plugin system
  void _registerToPluginSystem() {
    if (mounted) {
      try {
        final contextService = ref.read(pluginContextServiceProvider);
        final editorController = EditorControllerImpl(_controller);
        contextService.setEditorController(editorController);
        contextService.setBuildContext(context);
        debugPrint('Editor registered to plugin system');
      } catch (e) {
        debugPrint('Failed to register editor to plugin system: $e');
      }
    }
  }

  /// Text change handling
  void _onTextChanged() {
    final text = _controller.text;
    
    // Notify external callback
    widget.onChanged?.call(text);
    
    // Update current active tab content
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    final activeIndex = tabsNotifier.activeTabIndex;
    
    if (activeIndex >= 0 && text != _lastSyncedContent) {
      tabsNotifier.updateTabContent(activeIndex, text);
      _lastSyncedContent = text;
    }
    
    // Add to undo history (if not undo/redo operation)
    if (!_isApplyingUndoRedo) {
      _undoRedoManager.addState(EditorHistoryState(
        text: text,
        selection: _controller.selection,
        timestamp: DateTime.now(),
      ));
    }
    
    // Calculate cursor position
    final selection = _controller.selection;
    if (selection.isValid) {
      final lines = text.substring(0, selection.start).split('\n');
      final line = lines.length - 1;
      final column = lines.last.length;
      
      final position = CursorPosition(
        line: line,
        column: column,
        offset: selection.start,
      );
      
      widget.onCursorPositionChanged?.call(position);
    }
    
    // Notify global editor manager of state update
    if (_tabId != null && mounted) {
      final globalManager = ref.read(globalEditorManagerProvider);
      globalManager.notifyContentChanged(_tabId!, text, _controller.selection);
    }
  }

  /// Sync tab content to editor
  void _syncTabContent() {
    final activeDocument = ref.watch(activeDocumentProvider);
    
    if (activeDocument != null) {
      final content = activeDocument.content;
      if (content != _controller.text) {
        // Use addPostFrameCallback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _lastSyncedContent = content;
            _controller.text = content;
            // Keep cursor position at the end
            _controller.selection = TextSelection.collapsed(
              offset: content.length,
            );
          }
        });
      }
    } else {
      // Clear editor when no active document
      if (_controller.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _lastSyncedContent = '';
            _controller.text = '';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to active document changes and sync content
    _syncTabContent();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editorTheme = isDark ? EditorTheme.dark : EditorTheme.light;
    final activeDocument = ref.watch(activeDocumentProvider);
    
    // Plugin system registration is now handled in initState and _updateActiveTab
    
    return Container(
      decoration: BoxDecoration(
        color: editorTheme.backgroundColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Editor toolbar
          _buildEditorToolbar(),
          
          // Code editor
          Expanded(
            child: activeDocument != null 
                ? _buildCodeEditor(isDark, editorTheme)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noOpenDocuments,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.clickPlusButtonToCreate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build editor toolbar
  Widget _buildEditorToolbar() {
    final activeDocument = ref.watch(activeDocumentProvider);
    final isEnabled = activeDocument != null;
    
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
          // Undo/Redo buttons
          _buildToolbarButton(
            icon: Icons.undo,
            tooltip: '${AppLocalizations.of(context)!.undo} (Ctrl+Z)',
            onPressed: isEnabled && _undoRedoManager.canUndo ? _undo : null,
          ),
          _buildToolbarButton(
            icon: Icons.redo,
            tooltip: '${AppLocalizations.of(context)!.redo} (Ctrl+Y)',
            onPressed: isEnabled && _undoRedoManager.canRedo ? _redo : null,
          ),
          const VerticalDivider(width: 1),
          _buildToolbarButton(
            icon: Icons.title,
            tooltip: AppLocalizations.of(context)!.heading,
            onPressed: isEnabled ? () => _insertHeading() : null,
          ),
          _buildToolbarButton(
            icon: Icons.link,
            tooltip: AppLocalizations.of(context)!.link,
            onPressed: isEnabled ? () => _insertLink() : null,
          ),
          _buildToolbarButton(
            icon: Icons.image,
            tooltip: AppLocalizations.of(context)!.image,
            onPressed: isEnabled ? () => _insertImage() : null,
          ),
          const VerticalDivider(width: 1),
          _buildToolbarButton(
            icon: Icons.code,
            tooltip: AppLocalizations.of(context)!.codeBlock,
            onPressed: isEnabled ? () => _insertCodeBlock() : null,
          ),
          _buildToolbarButton(
            icon: Icons.functions,
            tooltip: AppLocalizations.of(context)!.mathFormula,
            onPressed: isEnabled ? () => _insertMathFormula() : null,
          ),
          // Plugin toolbar buttons
          ..._buildPluginToolbarButtons(isEnabled),
          _buildToolbarButton(
            icon: Icons.format_quote,
            tooltip: AppLocalizations.of(context)!.quote,
            onPressed: isEnabled ? () => _insertQuote() : null,
          ),
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: AppLocalizations.of(context)!.unorderedList,
            onPressed: isEnabled ? () => _insertList(false) : null,
          ),
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: AppLocalizations.of(context)!.orderedList,
            onPressed: isEnabled ? () => _insertList(true) : null,
          ),
          const Spacer(),
          if (isEnabled) ...[
            Text(
              'Line ${_getCurrentLine()} Column ${_getCurrentColumn()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// Build plugin toolbar buttons
  List<Widget> _buildPluginToolbarButtons(bool isEnabled) {
    try {
      final contextService = ref.read(pluginContextServiceProvider);
      final actions = contextService.toolbarRegistry.actions;
    final widgets = <Widget>[];
    
    // Debug info
    debugPrint('Number of actions in toolbar registry: ${actions.length}');
    for (final entry in actions.entries) {
      debugPrint('Action ID: ${entry.key}, Title: ${entry.value.action.title}');
    }
    
    for (final actionItem in actions.values) {
      final action = actionItem.action;
      widgets.add(_buildToolbarButton(
        icon: _getIconFromString(action.icon),
        tooltip: action.title,
        onPressed: isEnabled ? () {
          // Execute plugin action
          debugPrint('Execute plugin action: ${action.title}');
          
          // Ensure we have the latest editor controller and context
          _registerToPluginSystem();
          
          // Also ensure the current BuildContext is set
          final contextService = ref.read(pluginContextServiceProvider);
          contextService.setBuildContext(context);
          
          // Execute the callback
          actionItem.callback();
        } : null,
      ));
    }
    
    if (widgets.isNotEmpty) {
      widgets.add(const VerticalDivider(width: 1));
    }
    
    return widgets;
    } catch (e) {
      debugPrint('Failed to build plugin toolbar buttons: $e');
      return [];
    }
  }
  
  /// Convert string to IconData
  IconData _getIconFromString(String? iconName) {
    if (iconName == null) return Icons.extension;
    
    switch (iconName) {
      case 'account_tree':
        return Icons.account_tree;
      case 'code':
        return Icons.code;
      case 'image':
        return Icons.image;
      case 'link':
        return Icons.link;
      case 'functions':
        return Icons.functions;
      case 'format_quote':
        return Icons.format_quote;
      case 'format_list_bulleted':
        return Icons.format_list_bulleted;
      case 'format_list_numbered':
        return Icons.format_list_numbered;
      case 'export':
        return Icons.file_upload_outlined;
      case 'import':
        return Icons.file_download_outlined;
      default:
        return Icons.extension;
    }
  }

  /// Build toolbar button
  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
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

  /// Build line numbers
  Widget _buildLineNumbers() {
    final lines = _controller.text.split('\n');
    final lineCount = lines.length;
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    
    // Calculate dynamic width based on line count
    final maxLineNumber = lineCount;
    final digitCount = maxLineNumber.toString().length;
    final dynamicWidth = (digitCount * settings.fontSize * 0.6) + 16;
    final minWidth = 40.0;
    final maxWidth = math.max(80.0, dynamicWidth + 10); // Ensure maxWidth is always larger than calculated width
    final lineNumberWidth = math.max(minWidth, math.min(dynamicWidth, maxWidth));
    
    return Container(
      width: lineNumberWidth,
      padding: const EdgeInsets.only(right: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(lineCount, (index) {
            return Container(
              height: settings.fontSize * 1.5,
              alignment: Alignment.centerRight,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize * 0.9,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  height: 1.5,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Build code editor
  Widget _buildCodeEditor(bool isDark, EditorTheme editorTheme) {
    final settings = ref.watch(settingsProvider);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: editorTheme.backgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line numbers (if enabled)
          if (settings.showLineNumbers) ...[
            _buildLineNumbers(),
            const SizedBox(width: 8),
          ],
          // Editor content
          Expanded(
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: _handleKeyEvent,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: widget.readOnly,
                style: TextStyle(
                  fontFamily: settings.fontFamily,
                  fontSize: settings.fontSize,
                  color: editorTheme.textColor,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: AppLocalizations.of(context)!.enterMarkdownContent,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: editorTheme.cursorColor,
                enabled: !widget.readOnly,
                expands: true,
                maxLines: settings.wordWrap ? null : null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                scrollPhysics: settings.wordWrap ? null : const AlwaysScrollableScrollPhysics(),
                onChanged: (value) {
                  // Handled by _onTextChanged
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle keyboard events
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final isCtrlPressed = event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight ||
          event.isControlPressed;
      
      if (isCtrlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyZ) {
          _undo();
        } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
          _redo();
        }
      }
    }
  }

  /// Undo operation
  void _undo() {
    final state = _undoRedoManager.undo();
    if (state != null) {
      _applyEditorState(state);
    }
  }

  /// Redo operation
  void _redo() {
    final state = _undoRedoManager.redo();
    if (state != null) {
      _applyEditorState(state);
    }
  }

  /// Apply editor state
  void _applyEditorState(EditorHistoryState state) {
    _isApplyingUndoRedo = true;
    
    // Temporarily remove listener to avoid triggering _onTextChanged
    _controller.removeListener(_onTextChanged);
    
    _controller.text = state.text;
    _controller.selection = state.selection;
    
    // Re-add listener
    _controller.addListener(_onTextChanged);
    
    // Update tab content
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    final activeIndex = tabsNotifier.activeTabIndex;
    if (activeIndex >= 0) {
      tabsNotifier.updateTabContent(activeIndex, state.text);
    }
    _lastSyncedContent = state.text;
    
    // Immediately reset flag
    _isApplyingUndoRedo = false;
  }

  /// Insert Markdown format
  void _insertMarkdown(String prefix, String suffix) {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = '$prefix$selectedText$suffix';
      
      // Replace selected text
      final beforeSelection = text.substring(0, selection.start);
      final afterSelection = text.substring(selection.end);
      _controller.text = beforeSelection + newText + afterSelection;
      
      // Set new cursor position
      if (selectedText.isEmpty) {
        _controller.selection = material.TextSelection.collapsed(
          offset: selection.start + prefix.length,
        );
      } else {
        _controller.selection = material.TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + newText.length,
        );
      }
    }
  }

  /// Insert heading
  void _insertHeading() {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      final lines = text.split('\n');
      final lineIndex = text.substring(0, selection.start).split('\n').length - 1;
      
      if (lineIndex < lines.length) {
        final currentLine = lines[lineIndex];
        String newLine;
        
        if (currentLine.startsWith('# ')) {
          newLine = '## ${currentLine.substring(2)}';
        } else if (currentLine.startsWith('## ')) {
          newLine = '### ${currentLine.substring(3)}';
        } else if (currentLine.startsWith('### ')) {
          newLine = '#### ${currentLine.substring(4)}';
        } else if (currentLine.startsWith('#### ')) {
          newLine = '##### ${currentLine.substring(5)}';
        } else if (currentLine.startsWith('##### ')) {
          newLine = '###### ${currentLine.substring(6)}';
        } else if (currentLine.startsWith('###### ')) {
          newLine = currentLine.substring(7);
        } else {
          newLine = '# $currentLine';
        }
        
        lines[lineIndex] = newLine;
        _controller.text = lines.join('\n');
      }
    }
  }

  /// Insert link
  void _insertLink() {
    _insertMarkdown('[', '](url)');
  }

  /// Insert image
  void _insertImage() {
    _insertMarkdown('![', '](url)');
  }

  /// Insert code block
  void _insertCodeBlock() {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = '```\n$selectedText\n```';
      
      // Replace selected text
      final beforeSelection = text.substring(0, selection.start);
      final afterSelection = text.substring(selection.end);
      _controller.text = beforeSelection + newText + afterSelection;
    }
  }

  /// Insert math formula
  void _insertMathFormula() {
    _showMathFormulaDialog();
  }



  /// Show math formula input dialog
  void _showMathFormulaDialog() {
    showDialog<String>(
      context: context,
      builder: (context) => _MathFormulaDialog(
        onInsert: (latex, isInline) {
          final selection = _controller.selection;
          if (selection.isValid) {
            final selectedText = _controller.text.substring(selection.start, selection.end);
            final formulaText = latex.isNotEmpty ? latex : selectedText;
            
            String newText;
            if (isInline) {
              newText = '\$${formulaText}\$';
            } else {
              newText = '\$\$\n${formulaText}\n\$\$';
            }
            
            // Replace selected text
            final beforeSelection = _controller.text.substring(0, selection.start);
            final afterSelection = _controller.text.substring(selection.end);
            _controller.text = beforeSelection + newText + afterSelection;
            
            // Set new cursor position
            if (formulaText.isEmpty) {
              final cursorOffset = isInline ? 1 : 3;
              _controller.selection = TextSelection.collapsed(
                offset: selection.start + cursorOffset,
              );
            } else {
              _controller.selection = TextSelection.collapsed(
                offset: selection.start + newText.length,
              );
            }
            
            widget.onChanged?.call(_controller.text);
          }
        },
      ),
    );
  }



  /// Insert quote
  void _insertQuote() {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      final lines = text.split('\n');
      final startLine = text.substring(0, selection.start).split('\n').length - 1;
      final endLine = text.substring(0, selection.end).split('\n').length - 1;
      
      for (int i = startLine; i <= endLine && i < lines.length; i++) {
        if (!lines[i].startsWith('> ')) {
          lines[i] = '> ${lines[i]}';
        }
      }
      
      _controller.text = lines.join('\n');
    }
  }

  /// Insert list
  void _insertList(bool ordered) {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      final lines = text.split('\n');
      final startLine = text.substring(0, selection.start).split('\n').length - 1;
      final endLine = text.substring(0, selection.end).split('\n').length - 1;
      
      for (int i = startLine; i <= endLine && i < lines.length; i++) {
        final prefix = ordered ? '${i - startLine + 1}. ' : '- ';
        if (!lines[i].startsWith(prefix)) {
          lines[i] = '$prefix${lines[i]}';
        }
      }
      
      _controller.text = lines.join('\n');
    }
  }

  /// Get current line number
  int _getCurrentLine() {
    final selection = _controller.selection;
    if (selection.isValid) {
      return _controller.text.substring(0, selection.start).split('\n').length;
    }
    return 1;
  }

  /// Get current column number
  int _getCurrentColumn() {
    final selection = _controller.selection;
    if (selection.isValid) {
      final lines = _controller.text.substring(0, selection.start).split('\n');
      return lines.last.length + 1;
    }
    return 1;
  }
}

/// Math formula input dialog
class _MathFormulaDialog extends ConsumerStatefulWidget {
  const _MathFormulaDialog({
    required this.onInsert,
  });

  final Function(String latex, bool isInline) onInsert;

  @override
  ConsumerState<_MathFormulaDialog> createState() => _MathFormulaDialogState();
}

class _MathFormulaDialogState extends ConsumerState<_MathFormulaDialog> {
  late TextEditingController _controller;
  bool _isInline = true;
  String _selectedExample = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // Trigger rebuild to update preview
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              AppLocalizations.of(context)!.insertMathFormula,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Formula type selection
            Row(
              children: [
                Text(AppLocalizations.of(context)!.formulaType, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(AppLocalizations.of(context)!.inlineFormulaOption),
                  selected: _isInline,
                  onSelected: (selected) {
                    setState(() {
                      _isInline = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(AppLocalizations.of(context)!.blockFormulaOption),
                  selected: !_isInline,
                  onSelected: (selected) {
                    setState(() {
                      _isInline = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // LaTeX input field
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.latexFormula,
                hintText: AppLocalizations.of(context)!.formulaExample,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Common formula examples
            Text(AppLocalizations.of(context)!.commonFormulas, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  // Examples list
                  Expanded(
                    flex: 2,
                    child: _buildExamplesList(),
                  ),
                  const SizedBox(width: 16),
                  // Preview
                  Expanded(
                    flex: 3,
                    child: _buildPreview(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _controller.text.trim().isNotEmpty
                      ? () {
                          widget.onInsert(_controller.text.trim(), _isInline);
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: Text(AppLocalizations.of(context)!.insert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesList() {
    final examples = MathParser.getMathExamples();
    final settings = ref.watch(settingsProvider);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return ListTile(
            dense: true,
            title: Text(
              example,
              style: TextStyle(fontFamily: settings.fontFamily, fontSize: 12),
            ),
            selected: _selectedExample == example,
            onTap: () {
              setState(() {
                _selectedExample = example;
                _controller.text = example;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    if (_controller.text.trim().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(AppLocalizations.of(context)!.previewWillBeShownHere),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: MathFormulaWidget(
        formula: MathFormula(
          type: _isInline ? MathType.inline : MathType.block,
          content: _controller.text.trim(),
          rawContent: _isInline 
              ? '\$${_controller.text.trim()}\$'
              : '\$\$${_controller.text.trim()}\$\$',
          startIndex: 0,
          endIndex: _controller.text.trim().length,
        ),
        onError: (error) {
          // Error handled internally by component
        },
      ),
    );
  }
}