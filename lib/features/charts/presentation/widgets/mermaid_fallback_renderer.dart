import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../types/charts.dart';

/// Mermaid备用渲染器 - 当WebView不可用时使用
class MermaidFallbackRenderer extends StatelessWidget {
  const MermaidFallbackRenderer({
    super.key,
    required this.chart,
    this.height = 400,
    this.onError,
  });

  final MermaidChart chart;
  final double height;
  final ValueChanged<String>? onError;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height == double.infinity ? null : height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 头部信息
          _buildHeader(context),
          
          // 图表内容
          Expanded(
            child: _buildChartContent(context),
          ),
          
          // 底部操作
          _buildFooter(context),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    final type = chart.type ?? MermaidChartType.flowchart;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getTypeIcon(type),
            size: 20,
            color: _getTypeColor(type),
          ),
          const SizedBox(width: 8),
          Text(
            type.displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getTypeColor(type),
            ),
          ),
          if (chart.title != null) ...[
            const SizedBox(width: 8),
            Text(
              '- ${chart.title}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '简化渲染',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建图表内容
  Widget _buildChartContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图表结构分析
          _buildChartStructure(context),
          
          const SizedBox(height: 16),
          
          // 源码预览
          Expanded(
            child: _buildSourcePreview(context),
          ),
        ],
      ),
    );
  }

  /// 构建图表结构
  Widget _buildChartStructure(BuildContext context) {
    final lines = chart.content.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    
    final nodes = <String>[];
    final connections = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('graph') || 
          trimmed.startsWith('flowchart') ||
          trimmed.startsWith('sequenceDiagram') ||
          trimmed.startsWith('classDiagram')) {
        continue;
      }
      
      if (trimmed.contains('-->') || 
          trimmed.contains('->') ||
          trimmed.contains('--')) {
        connections.add(trimmed);
      } else if (trimmed.isNotEmpty) {
        nodes.add(trimmed);
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '图表结构',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '节点: ${nodes.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '连接: ${connections.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '行数: ${lines.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建源码预览
  Widget _buildSourcePreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
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
              Text(
                'Mermaid源码',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.content_copy),
                iconSize: 16,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(4),
                ),
                onPressed: () => _copySource(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                chart.content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '简化渲染模式',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制源码
  void _copySource(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: chart.content));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mermaid源码已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 获取图表类型图标
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

  /// 获取图表类型颜色
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