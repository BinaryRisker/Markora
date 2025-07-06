import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../types/plugin.dart';
import '../providers/plugin_providers.dart';

/// 插件统计卡片组件
class PluginStatsCard extends ConsumerWidget {
  const PluginStatsCard({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(pluginStatsProvider);
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '插件统计',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 总体统计
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.extension,
                    label: '总插件数',
                    value: stats.total.toString(),
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.check_circle,
                    label: '已启用',
                    value: stats.enabled.toString(),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.download_done,
                    label: '已安装',
                    value: stats.installed.toString(),
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.error,
                    label: '错误',
                    value: stats.error.toString(),
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 按类型统计
            Text(
              '按类型分布',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PluginType.values.map((type) {
                final count = stats.pluginsByType[type] ?? 0;
                return _TypeChip(
                  type: type,
                  count: count,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 类型芯片组件
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.count,
  });
  
  final PluginType type;
  final int count;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getTypeColor(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTypeIcon(type),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            type.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 获取插件类型对应的颜色
  Color _getTypeColor(PluginType type) {
    switch (type) {
      case PluginType.syntax:
        return Colors.blue;
      case PluginType.renderer:
        return Colors.green;
      case PluginType.theme:
        return Colors.purple;
      case PluginType.export:
        return Colors.orange;
      case PluginType.import:
        return Colors.teal;
      case PluginType.tool:
        return Colors.red;
      case PluginType.widget:
        return Colors.indigo;
      case PluginType.exporter:
        return Colors.deepOrange;
      case PluginType.integration:
        return Colors.cyan;
      case PluginType.other:
        return Colors.grey;
    }
  }
  
  /// 获取插件类型对应的图标
  IconData _getTypeIcon(PluginType type) {
    switch (type) {
      case PluginType.syntax:
        return Icons.code;
      case PluginType.renderer:
        return Icons.visibility;
      case PluginType.theme:
        return Icons.palette;
      case PluginType.export:
        return Icons.file_upload;
      case PluginType.import:
        return Icons.file_download;
      case PluginType.tool:
        return Icons.build;
      case PluginType.widget:
        return Icons.widgets;
      case PluginType.exporter:
        return Icons.upload;
      case PluginType.integration:
        return Icons.link;
      case PluginType.other:
        return Icons.extension;
    }
  }
}