import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../types/plugin.dart';
import '../providers/plugin_providers.dart';

/// Compact header component for plugin page
class PluginCompactHeader extends ConsumerStatefulWidget {
  const PluginCompactHeader({super.key});
  
  @override
  ConsumerState<PluginCompactHeader> createState() => _PluginCompactHeaderState();
}

class _PluginCompactHeaderState extends ConsumerState<PluginCompactHeader> {
  late final TextEditingController _searchController;
  final GlobalKey _statsButtonKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    
    // Listen to search state changes
    ref.listenManual(pluginSearchProvider, (previous, next) {
      if (next != _searchController.text) {
        _searchController.text = next;
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(pluginSearchProvider);
    final typeFilter = ref.watch(pluginTypeFilterProvider);
    final statusFilter = ref.watch(pluginStatusFilterProvider);
    final stats = ref.watch(pluginStatsProvider);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          // Search field (expandable)
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchPluginHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _clearSearch,
                          iconSize: 18,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  ref.read(pluginSearchProvider.notifier).state = value;
                },
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Quick filter chips
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickFilterChip(
                    label: AppLocalizations.of(context)!.all,
                    isSelected: typeFilter == null && statusFilter == null,
                    onTap: () {
                      ref.read(pluginTypeFilterProvider.notifier).state = null;
                      ref.read(pluginStatusFilterProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 4),
                  _QuickFilterChip(
                    label: AppLocalizations.of(context)!.enabled,
                    isSelected: statusFilter == PluginStatus.enabled,
                    onTap: () {
                      ref.read(pluginStatusFilterProvider.notifier).state = 
                          statusFilter == PluginStatus.enabled ? null : PluginStatus.enabled;
                    },
                  ),
                  const SizedBox(width: 4),
                  _QuickFilterChip(
                    label: AppLocalizations.of(context)!.syntaxPlugin,
                    isSelected: typeFilter == PluginType.syntax,
                    onTap: () {
                      ref.read(pluginTypeFilterProvider.notifier).state = 
                          typeFilter == PluginType.syntax ? null : PluginType.syntax;
                    },
                  ),
                  const SizedBox(width: 4),
                  _QuickFilterChip(
                    label: AppLocalizations.of(context)!.themePlugin,
                    isSelected: typeFilter == PluginType.theme,
                    onTap: () {
                      ref.read(pluginTypeFilterProvider.notifier).state = 
                          typeFilter == PluginType.theme ? null : PluginType.theme;
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Compact stats with dropdown
          _CompactStatsButton(
            key: _statsButtonKey,
            stats: stats,
            onPressed: () => _showStatsDropdown(),
          ),
          
          const SizedBox(width: 4),
          
          // More filters button
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: _showAdvancedFilters,
            tooltip: 'More Filters',
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    ref.read(pluginSearchProvider.notifier).state = '';
  }
  
  /// Show statistics dropdown
  void _showStatsDropdown() {
    final RenderBox button = _statsButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<void>(
          enabled: false,
          child: _DetailedStatsContent(stats: ref.read(pluginStatsProvider)),
        ),
      ],
    );
  }
  
  /// Show advanced filters dialog
  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder: (context) => const _AdvancedFiltersDialog(),
    );
  }
}

/// Quick filter chip
class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer 
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: theme.colorScheme.primary, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Compact statistics button
class _CompactStatsButton extends StatelessWidget {
  const _CompactStatsButton({
    super.key,
    required this.stats,
    required this.onPressed,
  });
  
  final PluginStatistics stats;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${stats.total}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            if (stats.enabled > 0) ...[
              Text(
                '/',
                            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
              ),
              Text(
                '${stats.enabled}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
            if (stats.error > 0) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.error_outline,
                size: 12,
                color: theme.colorScheme.error,
              ),
            ],
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Detailed statistics content for dropdown
class _DetailedStatsContent extends StatelessWidget {
  const _DetailedStatsContent({required this.stats});
  
  final PluginStatistics stats;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.pluginStatistics,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Statistics grid
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.extension,
                  label: AppLocalizations.of(context)!.totalPlugins,
                  value: stats.total.toString(),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatItem(
                  icon: Icons.check_circle,
                  label: AppLocalizations.of(context)!.enabled,
                  value: stats.enabled.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.download_done,
                  label: AppLocalizations.of(context)!.installedStatus,
                  value: stats.installed.toString(),
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatItem(
                  icon: Icons.error,
                  label: AppLocalizations.of(context)!.errors,
                  value: stats.error.toString(),
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Type distribution
          Text(
            AppLocalizations.of(context)!.distributionByType,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: PluginType.values.map((type) {
              final count = stats.pluginsByType[type] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                                          color: _getTypeColor(type).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${type.getLocalizedDisplayName(context)}: $count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: _getTypeColor(type),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Color _getTypeColor(PluginType type) {
    switch (type) {
      case PluginType.syntax:
        return Colors.blue;
      case PluginType.renderer:
        return Colors.purple;
      case PluginType.theme:
        return Colors.pink;
      case PluginType.export:
        return Colors.orange;
      case PluginType.import:
        return Colors.green;
      case PluginType.tool:
        return Colors.teal;
      case PluginType.widget:
        return Colors.indigo;
      case PluginType.component:
        return Colors.cyan;
      case PluginType.exporter:
        return Colors.amber;
      case PluginType.integration:
        return Colors.deepOrange;
      case PluginType.other:
        return Colors.grey;
    }
  }
}

/// Compact statistics item
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Advanced filters dialog
class _AdvancedFiltersDialog extends ConsumerStatefulWidget {
  const _AdvancedFiltersDialog();
  
  @override
  ConsumerState<_AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();
}

class _AdvancedFiltersDialogState extends ConsumerState<_AdvancedFiltersDialog> {
  @override
  Widget build(BuildContext context) {
    final typeFilter = ref.watch(pluginTypeFilterProvider);
    final statusFilter = ref.watch(pluginStatusFilterProvider);
    final sortBy = ref.watch(pluginSortProvider);
    final sortAscending = ref.watch(pluginSortAscendingProvider);
    
    return AlertDialog(
      title: Text('Advanced Filters'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type filter
            DropdownButtonFormField<PluginType?>(
              value: typeFilter,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.pluginType,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<PluginType?>(
                  value: null,
                  child: Text(AppLocalizations.of(context)!.allTypes),
                ),
                ...PluginType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.getLocalizedDisplayName(context)),
                  );
                }),
              ],
              onChanged: (value) {
                ref.read(pluginTypeFilterProvider.notifier).state = value;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Status filter
            DropdownButtonFormField<PluginStatus?>(
              value: statusFilter,
              decoration: InputDecoration(
                labelText: 'Plugin Status',
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<PluginStatus?>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...PluginStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.getLocalizedDisplayName(context)),
                  );
                }),
              ],
              onChanged: (value) {
                ref.read(pluginStatusFilterProvider.notifier).state = value;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Sort options
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PluginSortBy>(
                    value: sortBy,
                    decoration: InputDecoration(
                      labelText: 'Sort By',
                      border: const OutlineInputBorder(),
                    ),
                    items: PluginSortBy.values.map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(sort.getLocalizedDisplayName(context)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(pluginSortProvider.notifier).state = value;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    ref.read(pluginSortAscendingProvider.notifier).state = !sortAscending;
                  },
                  icon: Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
        TextButton(
          onPressed: () {
            // Reset all filters
            ref.read(pluginTypeFilterProvider.notifier).state = null;
            ref.read(pluginStatusFilterProvider.notifier).state = null;
            ref.read(pluginSortProvider.notifier).state = PluginSortBy.name;
            ref.read(pluginSortAscendingProvider.notifier).state = true;
          },
          child: Text('Reset'),
        ),
      ],
    );
  }
} 