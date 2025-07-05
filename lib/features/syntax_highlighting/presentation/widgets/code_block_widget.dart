import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../types/syntax_highlighting.dart';
import '../../../syntax_highlighting/domain/services/syntax_parser.dart';
import '../../../syntax_highlighting/data/syntax_themes.dart';

/// 代码块渲染组件
class CodeBlockWidget extends StatefulWidget {
  const CodeBlockWidget({
    super.key,
    required this.codeBlock,
    this.theme,
    this.config = const SyntaxHighlightConfig(),
    this.onLanguageChanged,
  });

  /// 代码块信息
  final CodeBlock codeBlock;
  
  /// 语法高亮主题
  final SyntaxHighlightTheme? theme;
  
  /// 语法高亮配置
  final SyntaxHighlightConfig config;
  
  /// 语言变化回调
  final ValueChanged<ProgrammingLanguage?>? onLanguageChanged;

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  late ScrollController _scrollController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? SyntaxThemes.getDefaultTheme(
      Theme.of(context).brightness == Brightness.dark
    );
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: SyntaxThemes.colorFromInt(theme.backgroundColor),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 代码块头部
            _buildHeader(theme),
            
            // 代码内容
            _buildCodeContent(theme),
          ],
        ),
      ),
    );
  }

  /// 构建代码块头部
  Widget _buildHeader(SyntaxHighlightTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SyntaxThemes.colorFromInt(theme.backgroundColor).withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 语言标识
          _buildLanguageLabel(theme),
          
          // 文件名（如果有）
          if (widget.codeBlock.fileName != null) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.insert_drive_file,
              size: 16,
              color: SyntaxThemes.colorFromInt(theme.defaultTextColor).withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              widget.codeBlock.fileName!,
              style: TextStyle(
                fontSize: 12,
                color: SyntaxThemes.colorFromInt(theme.defaultTextColor).withOpacity(0.7),
                fontFamily: widget.config.fontFamily,
              ),
            ),
          ],
          
          const Spacer(),
          
          // 复制按钮
          if (widget.codeBlock.showCopyButton)
            _buildCopyButton(theme),
        ],
      ),
    );
  }

  /// 构建语言标识
  Widget _buildLanguageLabel(SyntaxHighlightTheme theme) {
    final language = widget.codeBlock.language;
    final displayName = language?.displayName ?? 'Plain Text';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontFamily: widget.config.fontFamily,
        ),
      ),
    );
  }

  /// 构建复制按钮
  Widget _buildCopyButton(SyntaxHighlightTheme theme) {
    return AnimatedOpacity(
      opacity: _isHovering ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Tooltip(
        message: '复制代码',
        child: IconButton(
          icon: const Icon(Icons.content_copy),
          iconSize: 16,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            foregroundColor: SyntaxThemes.colorFromInt(theme.defaultTextColor).withOpacity(0.7),
          ),
          onPressed: () => _copyToClipboard(),
        ),
      ),
    );
  }

  /// 构建代码内容
  Widget _buildCodeContent(SyntaxHighlightTheme theme) {
    if (!widget.config.enableSyntaxHighlighting) {
      return _buildPlainTextContent(theme);
    }

    final syntaxElements = SyntaxParser.parseCode(
      widget.codeBlock.content,
      widget.codeBlock.language,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行号
          if (widget.config.enableLineNumbers && widget.codeBlock.showLineNumbers)
            _buildLineNumbers(theme),
          
          // 代码内容
          Expanded(
            child: _buildSyntaxHighlightedContent(syntaxElements, theme),
          ),
        ],
      ),
    );
  }

  /// 构建普通文本内容
  Widget _buildPlainTextContent(SyntaxHighlightTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行号
          if (widget.config.enableLineNumbers && widget.codeBlock.showLineNumbers)
            _buildLineNumbers(theme),
          
          // 文本内容
          Expanded(
            child: SelectableText(
              widget.codeBlock.content,
              style: TextStyle(
                fontFamily: widget.config.fontFamily,
                fontSize: widget.config.fontSize,
                color: SyntaxThemes.colorFromInt(theme.defaultTextColor),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建行号
  Widget _buildLineNumbers(SyntaxHighlightTheme theme) {
    final lines = widget.codeBlock.content.split('\n');
    final lineCount = lines.length;
    final maxLineNumber = widget.codeBlock.startLine + lineCount - 1;
    final maxDigits = maxLineNumber.toString().length;

    return Container(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(lineCount, (index) {
          final lineNumber = widget.codeBlock.startLine + index;
          return Text(
            lineNumber.toString().padLeft(maxDigits),
            style: TextStyle(
              fontFamily: widget.config.fontFamily,
              fontSize: widget.config.fontSize,
              color: SyntaxThemes.colorFromInt(theme.defaultTextColor).withOpacity(0.5),
              height: 1.5,
            ),
          );
        }),
      ),
    );
  }

  /// 构建语法高亮内容
  Widget _buildSyntaxHighlightedContent(List<SyntaxElement> elements, SyntaxHighlightTheme theme) {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SelectableText.rich(
          TextSpan(
            children: elements.map((element) {
              return TextSpan(
                text: element.text,
                style: SyntaxThemes.getTextStyle(
                  element.type,
                  theme,
                  fontSize: widget.config.fontSize,
                  fontFamily: widget.config.fontFamily,
                ),
              );
            }).toList(),
          ),
          style: TextStyle(
            height: 1.5,
            fontFamily: widget.config.fontFamily,
            fontSize: widget.config.fontSize,
          ),
        ),
      ),
    );
  }

  /// 复制到剪贴板
  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.codeBlock.content));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('代码已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// 简化的代码块组件
class SimpleCodeBlock extends StatelessWidget {
  const SimpleCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.showLineNumbers = true,
    this.showCopyButton = true,
    this.theme,
  });

  /// 代码内容
  final String code;
  
  /// 编程语言
  final String? language;
  
  /// 是否显示行号
  final bool showLineNumbers;
  
  /// 是否显示复制按钮
  final bool showCopyButton;
  
  /// 语法高亮主题
  final SyntaxHighlightTheme? theme;

  @override
  Widget build(BuildContext context) {
    final programmingLanguage = ProgrammingLanguage.fromIdentifier(language);
    
    final codeBlock = CodeBlock(
      content: code,
      language: programmingLanguage,
      startLine: 1,
      endLine: code.split('\n').length,
      showLineNumbers: showLineNumbers,
      showCopyButton: showCopyButton,
    );

    return CodeBlockWidget(
      codeBlock: codeBlock,
      theme: theme,
    );
  }
} 