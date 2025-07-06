import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../types/plugin.dart';
import '../providers/plugin_providers.dart';

/// Plugin card component
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
              // Plugin header information
              Row(
                children: [
                  // Plugin icon
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
                  
                  // Plugin name and version
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
                  
                  // Status indicator
                  _buildStatusChip(plugin.status, theme, context),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Plugin description
              Text(
                plugin.metadata.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Tags
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
              
              // Action buttons
              if (showActions) ...
              [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Configuration button
                    if (plugin.status == PluginStatus.enabled)
                      TextButton.icon(
                        onPressed: () => _showPluginConfig(context, plugin),
                        icon: const Icon(Icons.settings, size: 16),
                        label: Text(AppLocalizations.of(context)!.configure),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    
                    const SizedBox(width: 8),
                    
                    // Enable/Disable button
                    if (plugin.status == PluginStatus.enabled)
                      FilledButton.icon(
                        onPressed: () => _disablePlugin(context, actions, plugin),
                        icon: const Icon(Icons.pause, size: 16),
                        label: Text(AppLocalizations.of(context)!.disable),
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
                        label: Text(AppLocalizations.of(context)!.enable),
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
  
  /// Build status chip
  Widget _buildStatusChip(PluginStatus status, ThemeData theme, BuildContext context) {
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
            status.getLocalizedDisplayName(context),
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
      case PluginType.exporter:
        return Colors.orange;
      case PluginType.import:
        return Colors.teal;
      case PluginType.tool:
        return Colors.red;
      case PluginType.widget:
        return Colors.indigo;
      case PluginType.component:
        return Colors.amber;
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
      case PluginType.exporter:
        return Icons.file_upload;
      case PluginType.import:
        return Icons.file_download;
      case PluginType.tool:
        return Icons.build;
      case PluginType.widget:
        return Icons.widgets;
      case PluginType.component:
        return Icons.view_module;
      case PluginType.integration:
        return Icons.link;
      case PluginType.other:
        return Icons.extension;
    }
  }
  
  /// Enable plugin
  void _enablePlugin(BuildContext context, PluginActions actions, Plugin plugin) async {
    final success = await actions.enablePlugin(plugin.metadata.id);
    if (context.mounted) {
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? localizations.pluginEnabled : localizations.enablePluginFailed),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  /// Disable plugin
  void _disablePlugin(BuildContext context, PluginActions actions, Plugin plugin) async {
    final success = await actions.disablePlugin(plugin.metadata.id);
    if (context.mounted) {
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? localizations.pluginDisabled : localizations.disablePluginFailed),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  /// Show plugin configuration
  void _showPluginConfig(BuildContext context, Plugin plugin) {
    showDialog(
      context: context,
      builder: (context) => _PluginConfigDialog(plugin: plugin),
    );
  }
}

/// Plugin configuration dialog
class _PluginConfigDialog extends ConsumerWidget {
  const _PluginConfigDialog({required this.plugin});
  
  final Plugin plugin;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(pluginConfigProvider(plugin.metadata.id));
    
    return AlertDialog(
      title: Text('${plugin.metadata.name} ${AppLocalizations.of(context)!.configuration}'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: config.when(
          data: (pluginConfig) {
            if (pluginConfig == null || pluginConfig.settings.isEmpty) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noConfigurableOptions),
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
                      // TODO: Implement configuration editing
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('${AppLocalizations.of(context)!.failedToLoadConfiguration}: $error'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
        FilledButton(
          onPressed: () {
            // TODO: Save configuration
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}