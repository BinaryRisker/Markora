import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../domain/services/math_parser.dart';

/// Math formula rendering component
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

  /// Math formula object
  final MathFormula formula;
  
  /// Text style
  final TextStyle? textStyle;
  
  /// Text color
  final Color? color;
  
  /// Background color
  final Color? backgroundColor;
  
  /// Click callback
  final VoidCallback? onTap;
  
  /// Error callback
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

  /// Build math formula
  Widget _buildMath(BuildContext context, TextStyle? textStyle) {
    try {
      // Preprocess LaTeX content
      final processedLatex = MathParser.preprocessLatex(formula.content);
      
      // Validate LaTeX syntax
      if (!MathParser.validateLatex(processedLatex)) {
        return _buildErrorWidget(context, 'Invalid LaTeX syntax');
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
      return _buildErrorWidget(context, 'Rendering error: ${e.toString()}');
    }
  }

  /// Build error widget
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

  /// Get padding
  EdgeInsets _getPadding() {
    switch (formula.type) {
      case MathType.inline:
        return const EdgeInsets.symmetric(horizontal: 2, vertical: 1);
      case MathType.block:
        return const EdgeInsets.all(12);
    }
  }

  /// Get font size
  double _getFontSize(TextStyle? textStyle) {
    final baseSize = textStyle?.fontSize ?? 14.0;
    switch (formula.type) {
      case MathType.inline:
        return baseSize;
      case MathType.block:
        return baseSize * 1.2; // Block formulas slightly larger
    }
  }
}

/// Math formula preview component
class MathFormulaPreview extends StatefulWidget {
  const MathFormulaPreview({
    super.key,
    required this.latex,
    this.textStyle,
    this.showOriginal = false,
  });

  /// LaTeX code
  final String latex;
  
  /// Text style
  final TextStyle? textStyle;
  
  /// Whether to show raw LaTeX code
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

  /// Build render view
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
              content: Text('Math formula rendering error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }

  /// Build source view
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
                  'LaTeX Source',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Click to switch to render view',
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

/// Math formula input dialog
class MathFormulaDialog extends StatefulWidget {
  const MathFormulaDialog({
    super.key,
    this.initialLatex = '',
    this.title = 'Insert Math Formula',
  });

  /// Initial LaTeX code
  final String initialLatex;
  
  /// Dialog title
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
            // LaTeX input field
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'LaTeX Code',
                hintText: 'e.g.: E = mc^2',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Preview
            Text(
              'Preview:',
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
                          'Enter LaTeX code above to see preview',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Common formula buttons
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _currentLatex.isNotEmpty
              ? () => Navigator.of(context).pop(_currentLatex)
              : null,
          child: const Text('Insert'),
        ),
      ],
    );
  }
}