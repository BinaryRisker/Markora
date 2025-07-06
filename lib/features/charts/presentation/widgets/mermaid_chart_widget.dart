import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../types/charts.dart';
import '../../domain/services/mermaid_parser.dart';
import '../../presentation/widgets/simple_mermaid_renderer.dart';

/// Mermaid图表渲染组件
class MermaidChartWidget extends StatefulWidget {
  const MermaidChartWidget({
    super.key,
    required this.chart,
    this.renderOptions,
    this.onError,
    this.onTap,
  });

  /// Mermaid图表
  final MermaidChart chart;
  
  /// 渲染选项
  final MermaidRenderOptions? renderOptions;
  
  /// 错误回调
  final ValueChanged<String>? onError;
  
  /// 点击回调
  final VoidCallback? onTap;

  @override
  State<MermaidChartWidget> createState() => _MermaidChartWidgetState();
}

class _MermaidChartWidgetState extends State<MermaidChartWidget> {
  bool _isHovering = false;
  bool _showSource = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () => setState(() => _showSource = !_showSource),
        child: Container(
          decoration: BoxDecoration(
            color: widget.renderOptions?.backgroundColor != null
                ? Color(int.parse(widget.renderOptions!.backgroundColor.replaceFirst('#', '0xFF')))
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图表头部
              _buildHeader(),
              
              // 图表内容
              _showSource ? _buildSourceView() : _buildChartView(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图表头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
          // 图表类型标识
          _buildTypeLabel(),
          
          // 图表标题（如果有）
          if (widget.chart.title != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.chart.title!,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          
          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 构建图表类型标识
  Widget _buildTypeLabel() {
    final type = widget.chart.type ?? MermaidChartType.flowchart;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTypeIcon(type),
            size: 16,
            color: _getTypeColor(type),
          ),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(type),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 查看源码按钮
        AnimatedOpacity(
          opacity: _isHovering ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Tooltip(
            message: _showSource ? '查看图表' : '查看源码',
            child: IconButton(
              icon: Icon(_showSource ? Icons.visibility : Icons.code),
              iconSize: 16,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(4),
              ),
              onPressed: () => setState(() => _showSource = !_showSource),
            ),
          ),
        ),
        
        // 复制源码按钮
        AnimatedOpacity(
          opacity: _isHovering ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Tooltip(
            message: '复制源码',
            child: IconButton(
              icon: const Icon(Icons.content_copy),
              iconSize: 16,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(4),
              ),
              onPressed: _copySource,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建图表视图
  Widget _buildChartView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SimpleMermaidRenderer(
        chart: widget.chart,
        height: 300,
      ),
    );
  }

  /// 构建图表信息
  Widget _buildChartInfo() {
    final info = <String>[];
    
    if (widget.chart.direction != null) {
      info.add('方向: ${widget.chart.direction}');
    }
    
    if (widget.chart.theme != null) {
      info.add('主题: ${widget.chart.theme}');
    }
    
    info.add('行数: ${widget.chart.content.split('\n').length}');
    
    if (info.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: info.map((item) => Text(
          item,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        )).toList(),
      ),
    );
  }

  /// 构建源码视图
  Widget _buildSourceView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mermaid源码:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: SelectableText(
              widget.chart.content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制源码
  void _copySource() async {
    await Clipboard.setData(ClipboardData(text: widget.chart.content));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mermaid源码已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 获取图表类型对应的图标
  IconData _getTypeIcon(MermaidChartType type) {
    switch (type) {
      case MermaidChartType.flowchart:
        return Icons.account_tree;
      case MermaidChartType.sequenceDiagram:
        return Icons.timeline;
      case MermaidChartType.classDiagram:
        return Icons.class_;
      case MermaidChartType.stateDiagram:
        return Icons.featured_play_list;
      case MermaidChartType.entityRelationshipDiagram:
        return Icons.storage;
      case MermaidChartType.userJourney:
        return Icons.map;
      case MermaidChartType.gantt:
        return Icons.calendar_view_month;
      case MermaidChartType.pie:
        return Icons.pie_chart;
      case MermaidChartType.gitgraph:
        return Icons.merge_type;
      case MermaidChartType.mindmap:
        return Icons.psychology;
      case MermaidChartType.timeline:
        return Icons.view_timeline;
      case MermaidChartType.requirement:
        return Icons.assignment;
    }
  }

  /// 获取图表类型对应的颜色
  Color _getTypeColor(MermaidChartType type) {
    switch (type) {
      case MermaidChartType.flowchart:
        return Colors.blue;
      case MermaidChartType.sequenceDiagram:
        return Colors.green;
      case MermaidChartType.classDiagram:
        return Colors.purple;
      case MermaidChartType.stateDiagram:
        return Colors.orange;
      case MermaidChartType.entityRelationshipDiagram:
        return Colors.teal;
      case MermaidChartType.userJourney:
        return Colors.indigo;
      case MermaidChartType.gantt:
        return Colors.brown;
      case MermaidChartType.pie:
        return Colors.pink;
      case MermaidChartType.gitgraph:
        return Colors.deepOrange;
      case MermaidChartType.mindmap:
        return Colors.cyan;
      case MermaidChartType.timeline:
        return Colors.lime;
      case MermaidChartType.requirement:
        return Colors.amber;
    }
  }
}

/// 简化的Mermaid图表组件
class SimpleMermaidChart extends StatelessWidget {
  const SimpleMermaidChart({
    super.key,
    required this.code,
    this.renderOptions,
  });

  /// Mermaid代码
  final String code;
  
  /// 渲染选项
  final MermaidRenderOptions? renderOptions;

  @override
  Widget build(BuildContext context) {
    final charts = MermaidParser.parseCharts('```mermaid\n$code\n```');
    
    if (charts.isEmpty) {
      return _buildErrorWidget(context, '无法解析Mermaid图表');
    }

    return MermaidChartWidget(
      chart: charts.first,
      renderOptions: renderOptions,
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 