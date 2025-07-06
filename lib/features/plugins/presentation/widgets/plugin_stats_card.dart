import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../types/plugin.dart';
import '../providers/plugin_providers.dart';

/// Plugin statistics card component
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
              'Plugin Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Overall statistics
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.extension,
                    label: 'Total Plugins',
                    value: stats.total.toString(),
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.check_circle,
                    label: 'Enabled',
                    value: stats.enabled.toString(),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.download_done,
                    label: 'Installed',
                    value: stats.installed.toString(),
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.error,
                    label: 'Errors',
                    value: stats.error.toString(),
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Statistics by type
            Text(
              'Distribution by Type',
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

/// Statistics item component
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

/// Type chip component
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
  
  /// Get color corresponding to plugin type
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
      case PluginType.component:
        return Colors.amber;
      case PluginType.exporter:
        return Colors.deepOrange;
      case PluginType.integration:
        return Colors.cyan;
      case PluginType.other:
        return Colors.grey;
    }
  }
  
  /// Get icon corresponding to plugin type
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
      case PluginType.component:
        return Icons.view_module;
      case PluginType.exporter:
        return Icons.upload;
      case PluginType.integration:
        return Icons.link;
      case PluginType.other:
        return Icons.extension;
    }
  }
}