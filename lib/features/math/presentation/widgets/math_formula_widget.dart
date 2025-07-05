import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../domain/services/math_parser.dart';

/// 数学公式渲染组件
class MathFormulaWidget extends StatelessWidget {
  const MathFormulaWidget({
    super.key,
    required this.formula,
    this.textStyle,
    this.color,
    this.backgroundColor,
    this.onTap,
    this.onError,
  });

  /// 数学公式对象
  final MathFormula formula;
  
  /// 文本样式
  final TextStyle? textStyle;
  
  /// 文字颜色
  final Color? color;
  
  /// 背景颜色
  final Color? backgroundColor;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 错误回调
  final ValueChanged<String>? onError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = textStyle ?? theme.textTheme.bodyLarge;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: _getPadding(),
        decoration: BoxDecoration(
          color: backgroundColor ?? 
                 (formula.type == MathType.block 
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                    : null),
          borderRadius: formula.type == MathType.block 
                        ? BorderRadius.circular(8) 
                        : null,
          border: formula.type == MathType.block
                    ? Border.all(
                        color: theme.dividerColor,
                        width: 1,
                      )
                    : null,
        ),
        child: _buildMath(context, defaultTextStyle),
      ),
    );
  }

  /// 构建数学公式
  Widget _buildMath(BuildContext context, TextStyle? textStyle) {
    try {
      // 预处理LaTeX内容
      final processedLatex = MathParser.preprocessLatex(formula.content);
      
      // 验证LaTeX语法
      if (!MathParser.validateLatex(processedLatex)) {
        return _buildErrorWidget(context, '无效的LaTeX语法');
      }

      return Math.tex(
        processedLatex,
        textStyle: textStyle?.copyWith(
          color: color ?? textStyle?.color,
        ),
        mathStyle: formula.type == MathType.block 
                    ? MathStyle.display 
                    : MathStyle.text,
        options: MathOptions(
          fontSize: _getFontSize(textStyle),
          color: color ?? textStyle?.color ?? Theme.of(context).colorScheme.onSurface,
        ),
      );
    } catch (e) {
      onError?.call(e.toString());
      return _buildErrorWidget(context, '渲染错误: ${e.toString()}');
    }
  }

  /// 构建错误提示组件
  Widget _buildErrorWidget(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red[700],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取内边距
  EdgeInsets _getPadding() {
    switch (formula.type) {
      case MathType.inline:
        return const EdgeInsets.symmetric(horizontal: 2, vertical: 1);
      case MathType.block:
        return const EdgeInsets.all(12);
    }
  }

  /// 获取字体大小
  double _getFontSize(TextStyle? textStyle) {
    final baseSize = textStyle?.fontSize ?? 14.0;
    switch (formula.type) {
      case MathType.inline:
        return baseSize;
      case MathType.block:
        return baseSize * 1.2; // 块级公式略大
    }
  }
}

/// 数学公式预览组件
class MathFormulaPreview extends StatefulWidget {
  const MathFormulaPreview({
    super.key,
    required this.latex,
    this.textStyle,
    this.showOriginal = false,
  });

  /// LaTeX代码
  final String latex;
  
  /// 文本样式
  final TextStyle? textStyle;
  
  /// 是否显示原始LaTeX代码
  final bool showOriginal;

  @override
  State<MathFormulaPreview> createState() => _MathFormulaPreviewState();
}

class _MathFormulaPreviewState extends State<MathFormulaPreview> {
  bool _showSource = false;

  @override
  Widget build(BuildContext context) {
    if (widget.showOriginal || _showSource) {
      return _buildSourceView();
    }

    return _buildRenderedView();
  }

  /// 构建渲染视图
  Widget _buildRenderedView() {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _showSource = true;
        });
      },
      child: MathFormulaWidget(
        formula: MathFormula(
          type: MathType.block,
          content: widget.latex,
          rawContent: '\$\$${widget.latex}\$\$',
          startIndex: 0,
          endIndex: widget.latex.length + 4,
        ),
        textStyle: widget.textStyle,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('数学公式渲染错误: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }

  /// 构建源码视图
  Widget _buildSourceView() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSource = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'LaTeX 源码',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '点击切换到渲染视图',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.latex,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 数学公式输入对话框
class MathFormulaDialog extends StatefulWidget {
  const MathFormulaDialog({
    super.key,
    this.initialLatex = '',
    this.title = '插入数学公式',
  });

  /// 初始LaTeX代码
  final String initialLatex;
  
  /// 对话框标题
  final String title;

  @override
  State<MathFormulaDialog> createState() => _MathFormulaDialogState();
}

class _MathFormulaDialogState extends State<MathFormulaDialog> {
  late TextEditingController _controller;
  String _currentLatex = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLatex);
    _currentLatex = widget.initialLatex;
    _controller.addListener(_onLatexChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onLatexChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onLatexChanged() {
    setState(() {
      _currentLatex = _controller.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LaTeX输入框
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'LaTeX 代码',
                hintText: '例如: E = mc^2',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // 预览
            Text(
              '预览:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: _currentLatex.isNotEmpty
                    ? MathFormulaPreview(latex: _currentLatex)
                    : Center(
                        child: Text(
                          '在上方输入LaTeX代码查看预览',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 常用公式按钮
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: MathParser.getMathExamples().take(6).map((example) {
                return ActionChip(
                  label: Text(
                    example.length > 15 
                        ? '${example.substring(0, 15)}...' 
                        : example,
                    style: const TextStyle(fontSize: 10),
                  ),
                  onPressed: () {
                    _controller.text = example;
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _currentLatex.isNotEmpty
              ? () => Navigator.of(context).pop(_currentLatex)
              : null,
          child: const Text('插入'),
        ),
      ],
    );
  }
} 