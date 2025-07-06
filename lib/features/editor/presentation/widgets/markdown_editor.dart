import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;

import '../../../../core/themes/app_theme.dart';
import '../../../../types/editor.dart';
import '../../../math/domain/services/math_parser.dart';
import '../../../math/presentation/widgets/math_formula_widget.dart';

import '../../../document/presentation/providers/document_providers.dart';
import '../../domain/services/undo_redo_manager.dart';
import '../../domain/services/global_editor_manager.dart';

/// Markdown编辑器组件
class MarkdownEditor extends ConsumerStatefulWidget {
  const MarkdownEditor({
    super.key,
    this.initialContent = '',
    this.onChanged,
    this.onCursorPositionChanged,
    this.readOnly = false,
  });

  /// 初始内容
  final String initialContent;
  
  /// 内容变化回调
  final ValueChanged<String>? onChanged;
  
  /// 光标位置变化回调
  final ValueChanged<CursorPosition>? onCursorPositionChanged;
  
  /// 是否只读
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
  
  @override
  void initState() {
    super.initState();
    
    _focusNode = FocusNode();
    _undoRedoManager = UndoRedoManager();
    
    // 初始化文本编辑器控制器
    _controller = TextEditingController(text: widget.initialContent);
    _lastSyncedContent = widget.initialContent;
    
    // 添加初始状态到撤销管理器
    if (widget.initialContent.isNotEmpty) {
      _undoRedoManager.addState(EditorHistoryState(
        text: widget.initialContent,
        selection: TextSelection.collapsed(offset: widget.initialContent.length),
        timestamp: DateTime.now(),
      ));
    }
    
    // 监听文本变化
    _controller.addListener(_onTextChanged);
    
    // 延迟注册到全局编辑器管理器，确保 ref 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerToGlobalManager();
    });
  }
  
  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当组件更新时，检查是否需要更新全局管理器的活跃标签页
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateActiveTab();
    });
  }

  @override
  void dispose() {
    _unregisterFromGlobalManager();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 注册到全局编辑器管理器
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
        // 设置为活跃标签页
        globalManager.setActiveTab(_tabId!);
      }
    }
  }

  /// 从全局编辑器管理器注销
  void _unregisterFromGlobalManager() {
    if (_tabId != null && mounted) {
      final globalManager = ref.read(globalEditorManagerProvider);
      globalManager.unregisterEditor(_tabId!);
    }
  }
  
  /// 更新活跃标签页
  void _updateActiveTab() {
    if (mounted) {
      final activeDocument = ref.read(activeDocumentProvider);
      if (activeDocument != null && _tabId != activeDocument.id) {
        // 标签页发生了变化，重新注册
        _unregisterFromGlobalManager();
        _registerToGlobalManager();
      } else if (activeDocument != null && _tabId == activeDocument.id) {
        // 确保当前标签页是活跃的
        final globalManager = ref.read(globalEditorManagerProvider);
        globalManager.setActiveTab(_tabId!);
      }
    }
  }

  /// 文本变化处理
  void _onTextChanged() {
    final text = _controller.text;
    
    // 通知外部回调
    widget.onChanged?.call(text);
    
    // 更新当前激活的Tab内容
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    final activeIndex = tabsNotifier.activeTabIndex;
    
    if (activeIndex >= 0 && text != _lastSyncedContent) {
      tabsNotifier.updateTabContent(activeIndex, text);
      _lastSyncedContent = text;
    }
    
    // 添加到撤销历史（如果不是撤销/重做操作）
    if (!_isApplyingUndoRedo) {
      _undoRedoManager.addState(EditorHistoryState(
        text: text,
        selection: _controller.selection,
        timestamp: DateTime.now(),
      ));
    }
    
    // 计算光标位置
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
    
    // 通知全局编辑器管理器状态更新
    if (_tabId != null && mounted) {
      final globalManager = ref.read(globalEditorManagerProvider);
      globalManager.notifyContentChanged(_tabId!, text, _controller.selection);
    }
  }

  /// 同步Tab内容到编辑器
  void _syncTabContent() {
    final activeDocument = ref.watch(activeDocumentProvider);
    
    if (activeDocument != null) {
      final content = activeDocument.content;
      if (content != _controller.text) {
        // 使用addPostFrameCallback避免在build期间调用setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _lastSyncedContent = content;
            _controller.text = content;
            // 保持光标位置在末尾
            _controller.selection = TextSelection.collapsed(
              offset: content.length,
            );
          }
        });
      }
    } else {
      // 没有激活文档时清空编辑器
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
    // 监听激活文档变化并同步内容
    _syncTabContent();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editorTheme = isDark ? EditorTheme.dark : EditorTheme.light;
    final activeDocument = ref.watch(activeDocumentProvider);
    
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
          // 编辑器工具栏
          _buildEditorToolbar(),
          
          // 代码编辑器
          Expanded(
            child: activeDocument != null 
                ? _buildCodeEditor(isDark, editorTheme)
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
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
            '没有打开的文档',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方的 + 按钮创建新文档，或从文件菜单打开现有文档',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建编辑器工具栏
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
          // 撤销/重做按钮
          _buildToolbarButton(
            icon: Icons.undo,
            tooltip: '撤销 (Ctrl+Z)',
            onPressed: isEnabled && _undoRedoManager.canUndo ? _undo : null,
          ),
          _buildToolbarButton(
            icon: Icons.redo,
            tooltip: '重做 (Ctrl+Y)',
            onPressed: isEnabled && _undoRedoManager.canRedo ? _redo : null,
          ),
          const VerticalDivider(width: 1),
          _buildToolbarButton(
            icon: Icons.title,
            tooltip: '标题',
            onPressed: isEnabled ? () => _insertHeading() : null,
          ),
          _buildToolbarButton(
            icon: Icons.link,
            tooltip: '链接',
            onPressed: isEnabled ? () => _insertLink() : null,
          ),
          _buildToolbarButton(
            icon: Icons.image,
            tooltip: '图片',
            onPressed: isEnabled ? () => _insertImage() : null,
          ),
          const VerticalDivider(width: 1),
          _buildToolbarButton(
            icon: Icons.code,
            tooltip: '代码块',
            onPressed: isEnabled ? () => _insertCodeBlock() : null,
          ),
          _buildToolbarButton(
            icon: Icons.functions,
            tooltip: '数学公式',
            onPressed: isEnabled ? () => _insertMathFormula() : null,
          ),
          _buildToolbarButton(
            icon: Icons.account_tree,
            tooltip: 'Mermaid图表 (插件)',
                    onPressed: null, // 功能已移至插件
          ),
          _buildToolbarButton(
            icon: Icons.format_quote,
            tooltip: '引用',
            onPressed: isEnabled ? () => _insertQuote() : null,
          ),
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: '无序列表',
            onPressed: isEnabled ? () => _insertList(false) : null,
          ),
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: '有序列表',
            onPressed: isEnabled ? () => _insertList(true) : null,
          ),
          const Spacer(),
          if (isEnabled) ...[
            Text(
              '行 ${_getCurrentLine()} 列 ${_getCurrentColumn()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// 构建工具栏按钮
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

  /// 构建代码编辑器
  Widget _buildCodeEditor(bool isDark, EditorTheme editorTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: editorTheme.backgroundColor,
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: editorTheme.textColor,
            height: 1.5,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '在此输入Markdown内容...',
            contentPadding: EdgeInsets.zero,
          ),
          cursorColor: editorTheme.cursorColor,
          enabled: !widget.readOnly,
          expands: true,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (value) {
            // 由_onTextChanged处理
          },
        ),
      ),
    );
  }

  /// 处理键盘事件
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

  /// 撤销操作
  void _undo() {
    final state = _undoRedoManager.undo();
    if (state != null) {
      _applyEditorState(state);
    }
  }

  /// 重做操作
  void _redo() {
    final state = _undoRedoManager.redo();
    if (state != null) {
      _applyEditorState(state);
    }
  }

  /// 应用编辑器状态
  void _applyEditorState(EditorHistoryState state) {
    _isApplyingUndoRedo = true;
    
    // 临时移除监听器，避免触发_onTextChanged
    _controller.removeListener(_onTextChanged);
    
    _controller.text = state.text;
    _controller.selection = state.selection;
    
    // 重新添加监听器
    _controller.addListener(_onTextChanged);
    
    // 更新Tab内容
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    final activeIndex = tabsNotifier.activeTabIndex;
    if (activeIndex >= 0) {
      tabsNotifier.updateTabContent(activeIndex, state.text);
    }
    _lastSyncedContent = state.text;
    
    // 立即重置标志
    _isApplyingUndoRedo = false;
  }

  /// 插入Markdown格式
  void _insertMarkdown(String prefix, String suffix) {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = '$prefix$selectedText$suffix';
      
      // 替换选中的文本
      final beforeSelection = text.substring(0, selection.start);
      final afterSelection = text.substring(selection.end);
      _controller.text = beforeSelection + newText + afterSelection;
      
      // 设置新的光标位置
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

  /// 插入标题
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

  /// 插入链接
  void _insertLink() {
    _insertMarkdown('[', '](url)');
  }

  /// 插入图片
  void _insertImage() {
    _insertMarkdown('![', '](url)');
  }

  /// 插入代码块
  void _insertCodeBlock() {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = '```\n$selectedText\n```';
      
      // 替换选中的文本
      final beforeSelection = text.substring(0, selection.start);
      final afterSelection = text.substring(selection.end);
      _controller.text = beforeSelection + newText + afterSelection;
    }
  }

  /// 插入数学公式
  void _insertMathFormula() {
    _showMathFormulaDialog();
  }



  /// 显示数学公式输入对话框
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
            
            // 替换选中的文本
            final beforeSelection = _controller.text.substring(0, selection.start);
            final afterSelection = _controller.text.substring(selection.end);
            _controller.text = beforeSelection + newText + afterSelection;
            
            // 设置新的光标位置
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



  /// 插入引用
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

  /// 插入列表
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

  /// 获取当前行号
  int _getCurrentLine() {
    final selection = _controller.selection;
    if (selection.isValid) {
      return _controller.text.substring(0, selection.start).split('\n').length;
    }
    return 1;
  }

  /// 获取当前列号
  int _getCurrentColumn() {
    final selection = _controller.selection;
    if (selection.isValid) {
      final lines = _controller.text.substring(0, selection.start).split('\n');
      return lines.last.length + 1;
    }
    return 1;
  }
}

/// 数学公式输入对话框
class _MathFormulaDialog extends StatefulWidget {
  const _MathFormulaDialog({
    required this.onInsert,
  });

  final Function(String latex, bool isInline) onInsert;

  @override
  State<_MathFormulaDialog> createState() => _MathFormulaDialogState();
}

class _MathFormulaDialogState extends State<_MathFormulaDialog> {
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
      // 触发重建以更新预览
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
            // 标题
            Text(
              '插入数学公式',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // 公式类型选择
            Row(
              children: [
                Text('公式类型: ', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('行内公式'),
                  selected: _isInline,
                  onSelected: (selected) {
                    setState(() {
                      _isInline = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('块级公式'),
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
            
            // LaTeX输入框
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'LaTeX 公式',
                hintText: '例如: E = mc^2',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 常用公式示例
            Text('常用公式:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  // 示例列表
                  Expanded(
                    flex: 2,
                    child: _buildExamplesList(),
                  ),
                  const SizedBox(width: 16),
                  // 预览
                  Expanded(
                    flex: 3,
                    child: _buildPreview(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _controller.text.trim().isNotEmpty
                      ? () {
                          widget.onInsert(_controller.text.trim(), _isInline);
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('插入'),
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
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
        child: const Center(
          child: Text('预览将在这里显示'),
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
          // 错误在组件内部处理
        },
      ),
    );
  }
}