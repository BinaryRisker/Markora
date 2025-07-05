import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../math/domain/services/math_parser.dart';
import '../../../math/presentation/widgets/math_formula_widget.dart';
import '../../../syntax_highlighting/presentation/widgets/code_block_widget.dart';
import '../../../../types/syntax_highlighting.dart';
import '../../../charts/domain/services/mermaid_parser.dart';
import '../../../charts/presentation/widgets/mermaid_chart_widget.dart';
import '../../../../types/charts.dart';

/// Markdown预览组件
class MarkdownPreview extends ConsumerStatefulWidget {
  const MarkdownPreview({
    super.key,
    required this.content,
    this.onTap,
    this.selectable = true,
  });

  /// Markdown内容
  final String content;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 是否可选择文本
  final bool selectable;

  @override
  ConsumerState<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends ConsumerState<MarkdownPreview> {
  late ScrollController _scrollController;

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
          // 预览工具栏
          _buildPreviewToolbar(),
          
          // Markdown内容
          Expanded(
            child: _buildMarkdownContent(),
          ),
        ],
      ),
    );
  }

  /// 构建预览工具栏
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
            '预览',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 导出按钮
          _buildToolbarButton(
            icon: Icons.picture_as_pdf,
            tooltip: '导出为PDF',
            onPressed: () => _exportToPdf(),
          ),
          _buildToolbarButton(
            icon: Icons.html,
            tooltip: '导出为HTML',
            onPressed: () => _exportToHtml(),
          ),
          _buildToolbarButton(
            icon: Icons.refresh,
            tooltip: '刷新预览',
            onPressed: () => _refreshPreview(),
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

  /// 构建Markdown内容
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
              '在左侧编辑器中输入Markdown内容',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '预览将在这里显示',
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

  /// 构建包含数学公式和图表的内容
  Widget _buildContentWithMath() {
    // 解析数学公式和Mermaid图表
    final mathFormulas = MathParser.parseFormulas(widget.content);
    final mermaidCharts = MermaidParser.parseCharts(widget.content);
    
    if (mathFormulas.isEmpty && mermaidCharts.isEmpty) {
      // 没有特殊内容，直接使用普通Markdown渲染
      return MarkdownBody(
        data: widget.content,
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

    // 有特殊内容，需要特殊处理
    return _buildMixedContent(mathFormulas, mermaidCharts);
  }

  /// 构建混合内容（文本+数学公式+图表）
  Widget _buildMixedContent(List<MathFormula> mathFormulas, List<MermaidChart> mermaidCharts) {
    final widgets = <Widget>[];
    
    // 合并所有特殊元素并按位置排序
    final allElements = <_SpecialElement>[];
    
    // 添加数学公式
    for (final formula in mathFormulas) {
      allElements.add(_SpecialElement(
        type: _SpecialElementType.math,
        startIndex: formula.startIndex,
        endIndex: formula.endIndex,
        data: formula,
      ));
    }
    
    // 添加Mermaid图表
    for (final chart in mermaidCharts) {
      allElements.add(_SpecialElement(
        type: _SpecialElementType.chart,
        startIndex: chart.startIndex,
        endIndex: chart.endIndex,
        data: chart,
      ));
    }
    
    // 按位置排序
    allElements.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    int currentIndex = 0;

    for (final element in allElements) {
      // 添加元素前的普通文本
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

      // 添加特殊元素
      if (element.type == _SpecialElementType.math) {
        final formula = element.data as MathFormula;
        widgets.add(MathFormulaWidget(
          formula: formula,
          textStyle: Theme.of(context).textTheme.bodyLarge,
          onError: (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('数学公式渲染错误: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ));
      } else if (element.type == _SpecialElementType.chart) {
        final chart = element.data as MermaidChart;
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: MermaidChartWidget(
            chart: chart,
            onError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('图表渲染错误: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ));
      }

      currentIndex = element.endIndex;
    }

    // 添加最后剩余的文本
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

  /// 构建Markdown样式表
  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return MarkdownStyleSheet(
      // 段落样式
      p: textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurface,
      ),
      
      // 标题样式
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
      
      // 代码样式
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
      
      // 引用样式
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
      
      // 链接样式
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      
      // 列表样式
      listBullet: textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      
      // 表格样式
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
      
      // 水平分割线
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

  /// 处理链接点击
  void _handleLinkTap(String href) async {
    try {
      final uri = Uri.parse(href);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法打开链接: $href')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('链接格式错误: $href')),
        );
      }
    }
  }

  /// 导出为PDF
  void _exportToPdf() {
    // TODO: 实现PDF导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF导出功能即将推出')),
    );
  }

  /// 导出为HTML
  void _exportToHtml() {
    // TODO: 实现HTML导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('HTML导出功能即将推出')),
    );
  }

  /// 刷新预览
  void _refreshPreview() {
    setState(() {
      // 强制重建预览
    });
  }
}

/// 数学公式构建器
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
            '数学公式解析错误: $mathContent',
            style: TextStyle(color: Colors.red),
          ),
        );
      }
    }
    return null;
  }
}

/// 代码块构建器
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

/// 特殊元素类型
enum _SpecialElementType {
  math,   // 数学公式
  chart,  // Mermaid图表
}

/// 特殊元素
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