import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../types/plugin.dart';
import '../providers/plugin_providers.dart';

/// 插件卡片组件
class PluginCard extends ConsumerWidget {
  const PluginCard({
    super.key,
    required this.plugin,
    this.onTap,
    this.showActions = true,
  });
  
  final Plugin plugin;
  final VoidCallback? onTap;
  final bool showActions;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.watch(pluginActionsProvider);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 插件头部信息
              Row(
                children: [
                  // 插件图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getTypeColor(plugin.metadata.type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(plugin.metadata.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 插件名称和版本
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plugin.metadata.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${plugin.metadata.version} • ${plugin.metadata.author}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 状态指示器
                  _buildStatusChip(plugin.status, theme),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 插件描述
              Text(
                plugin.metadata.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // 标签
              if (plugin.metadata.tags.isNotEmpty) ...
              [
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: plugin.metadata.tags.take(3).map((tag) => Chip(
                    label: Text(
                      tag,
                      style: theme.textTheme.bodySmall,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
              
              // 操作按钮
              if (showActions) ...
              [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 配置按钮
                    if (plugin.status == PluginStatus.enabled)
                      TextButton.icon(
                        onPressed: () => _showPluginConfig(context, plugin),
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('配置'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // 启用/禁用按钮
                    if (plugin.status == PluginStatus.enabled)
                      FilledButton.icon(
                        onPressed: () => _disablePlugin(context, actions, plugin),
                        icon: const Icon(Icons.pause, size: 16),
                        label: const Text('禁用'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                    else if (plugin.status == PluginStatus.installed || 
                             plugin.status == PluginStatus.disabled)
                      FilledButton.icon(
                        onPressed: () => _enablePlugin(context, actions, plugin),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('启用'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建状态芯片
  Widget _buildStatusChip(PluginStatus status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (status) {
      case PluginStatus.enabled:
        backgroundColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        icon = Icons.check_circle;
        break;
      case PluginStatus.disabled:
        backgroundColor = theme.colorScheme.outline;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.pause_circle;
        break;
      case PluginStatus.installed:
        backgroundColor = theme.colorScheme.secondary;
        textColor = theme.colorScheme.onSecondary;
        icon = Icons.download_done;
        break;
      case PluginStatus.error:
        backgroundColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        icon = Icons.error;
        break;
      case PluginStatus.loading:
        backgroundColor = theme.colorScheme.surfaceVariant;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.hourglass_empty;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
      case PluginType.exporter:
        return Colors.orange;
      case PluginType.import:
        return Colors.teal;
      case PluginType.tool:
        return Colors.red;
      case PluginType.widget:
        return Colors.indigo;
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
      case PluginType.exporter:
        return Icons.file_upload;
      case PluginType.import:
        return Icons.file_download;
      case PluginType.tool:
        return Icons.build;
      case PluginType.widget:
        return Icons.widgets;
      case PluginType.integration:
        return Icons.link;
      case PluginType.other:
        return Icons.extension;
    }
  }
  
  /// 启用插件
  void _enablePlugin(BuildContext context, PluginActions actions, Plugin plugin) async {
    final success = await actions.enablePlugin(plugin.metadata.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '插件已启用' : '启用失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  /// 禁用插件
  void _disablePlugin(BuildContext context, PluginActions actions, Plugin plugin) async {
    final success = await actions.disablePlugin(plugin.metadata.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '插件已禁用' : '禁用失败'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }
  
  /// 显示插件配置
  void _showPluginConfig(BuildContext context, Plugin plugin) {
    showDialog(
      context: context,
      builder: (context) => _PluginConfigDialog(plugin: plugin),
    );
  }
}

/// 插件配置对话框
class _PluginConfigDialog extends ConsumerWidget {
  const _PluginConfigDialog({required this.plugin});
  
  final Plugin plugin;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(pluginConfigProvider(plugin.metadata.id));
    
    return AlertDialog(
      title: Text('${plugin.metadata.name} 配置'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: config.when(
          data: (pluginConfig) {
            if (pluginConfig == null || pluginConfig.settings.isEmpty) {
              return const Center(
                child: Text('该插件暂无可配置项'),
              );
            }
            
            return ListView.builder(
              itemCount: pluginConfig.settings.length,
              itemBuilder: (context, index) {
                final setting = pluginConfig.settings.entries.elementAt(index);
                return ListTile(
                  title: Text(setting.key),
                  subtitle: Text(setting.value.toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: 实现配置编辑
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('加载配置失败: $error'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        FilledButton(
          onPressed: () {
            // TODO: 保存配置
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}