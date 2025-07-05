import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' as material;

import '../../../../core/themes/app_theme.dart';
import '../../../../types/editor.dart';

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
  
  @override
  void initState() {
    super.initState();
    
    _focusNode = FocusNode();
    
    // 初始化文本编辑器控制器
    _controller = TextEditingController(text: widget.initialContent);
    
    // 监听文本变化
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 文本变化处理
  void _onTextChanged() {
    final text = _controller.text;
    widget.onChanged?.call(text);
    
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editorTheme = isDark ? EditorTheme.dark : EditorTheme.light;
    
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
            child: _buildCodeEditor(isDark, editorTheme),
          ),
        ],
      ),
    );
  }

  /// 构建编辑器工具栏
  Widget _buildEditorToolbar() {
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
          _buildToolbarButton(
            icon: Icons.format_bold,
            tooltip: '粗体 (Ctrl+B)',
            onPressed: () => _insertMarkdown('**', '**'),
          ),
          _buildToolbarButton(
            icon: Icons.format_italic,
            tooltip: '斜体 (Ctrl+I)',
            onPressed: () => _insertMarkdown('*', '*'),
          ),
          _buildToolbarButton(
            icon: Icons.format_strikethrough,
            tooltip: '删除线',
            onPressed: () => _insertMarkdown('~~', '~~'),
          ),
          const VerticalDivider(width: 1),
          _buildToolbarButton(
            icon: Icons.title,
            tooltip: '标题',
            onPressed: () => _insertHeading(),
          ),
          _buildToolbarButton(
            icon: Icons.link,
            tooltip: '链接',
            onPressed: () => _insertLink(),
          ),
          _buildToolbarButton(
            icon: Icons.image,
            tooltip: '图片',
            onPressed: () => _insertImage(),
          ),
          const VerticalDivider(width: 1),
          _buildToolbarButton(
            icon: Icons.code,
            tooltip: '代码块',
            onPressed: () => _insertCodeBlock(),
          ),
          _buildToolbarButton(
            icon: Icons.format_quote,
            tooltip: '引用',
            onPressed: () => _insertQuote(),
          ),
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: '无序列表',
            onPressed: () => _insertList(false),
          ),
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: '有序列表',
            onPressed: () => _insertList(true),
          ),
          const Spacer(),
          Text(
            '行 ${_getCurrentLine()} 列 ${_getCurrentColumn()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// 构建工具栏按钮
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

  /// 构建代码编辑器
  Widget _buildCodeEditor(bool isDark, EditorTheme editorTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: editorTheme.backgroundColor,
      ),
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
    );
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