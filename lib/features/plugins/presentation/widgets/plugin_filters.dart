import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../types/plugin.dart';
import '../providers/plugin_providers.dart';

/// Plugin filter component
class PluginFilters extends ConsumerWidget {
  const PluginFilters({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilter = ref.watch(pluginTypeFilterProvider);
    final statusFilter = ref.watch(pluginStatusFilterProvider);
    final sortBy = ref.watch(pluginSortProvider);
    final sortAscending = ref.watch(pluginSortAscendingProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter and Sort',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            
            // Filter row
            Row(
              children: [
                // Type filter
                Expanded(
                  child: _TypeFilterDropdown(
                    value: typeFilter,
                    onChanged: (type) {
                      ref.read(pluginTypeFilterProvider.notifier).state = type;
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Status filter
                Expanded(
                  child: _StatusFilterDropdown(
                    value: statusFilter,
                    onChanged: (status) {
                      ref.read(pluginStatusFilterProvider.notifier).state = status;
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Sort method
                Expanded(
                  child: _SortDropdown(
                    value: sortBy,
                    onChanged: (sort) {
                      if (sort != null) {
                        ref.read(pluginSortProvider.notifier).state = sort;
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Sort direction
                IconButton(
                  onPressed: () {
                    ref.read(pluginSortAscendingProvider.notifier).state = !sortAscending;
                  },
                  icon: Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  tooltip: sortAscending ? 'Ascending' : 'Descending',
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Quick filter buttons
            Wrap(
              spacing: 8,
              children: [
                _QuickFilterChip(
                  label: 'All',
                  isSelected: typeFilter == null && statusFilter == null,
                  onTap: () {
                    ref.read(pluginTypeFilterProvider.notifier).state = null;
                    ref.read(pluginStatusFilterProvider.notifier).state = null;
                  },
                ),
                _QuickFilterChip(
                  label: 'Enabled',
                  isSelected: statusFilter == PluginStatus.enabled,
                  onTap: () {
                    ref.read(pluginStatusFilterProvider.notifier).state = PluginStatus.enabled;
                  },
                ),
                _QuickFilterChip(
                  label: 'Syntax',
                  isSelected: typeFilter == PluginType.syntax,
                  onTap: () {
                    ref.read(pluginTypeFilterProvider.notifier).state = PluginType.syntax;
                  },
                ),
                _QuickFilterChip(
                  label: 'Theme',
                  isSelected: typeFilter == PluginType.theme,
                  onTap: () {
                    ref.read(pluginTypeFilterProvider.notifier).state = PluginType.theme;
                  },
                ),
                _QuickFilterChip(
                  label: 'Tool',
                  isSelected: typeFilter == PluginType.tool,
                  onTap: () {
                    ref.read(pluginTypeFilterProvider.notifier).state = PluginType.tool;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Type filter dropdown
class _TypeFilterDropdown extends StatelessWidget {
  const _TypeFilterDropdown({
    required this.value,
    required this.onChanged,
  });
  
  final PluginType? value;
  final ValueChanged<PluginType?> onChanged;
  
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PluginType?>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Plugin Type',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<PluginType?>(
          value: null,
          child: Text('All Types'),
        ),
        ...PluginType.values.map((type) => DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(_getTypeIcon(type), size: 16),
              const SizedBox(width: 8),
              Text(type.displayName),
            ],
          ),
        )),
      ],
      onChanged: (value) => onChanged(value!),
    );
  }
  
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

/// Status filter dropdown
class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown({
    required this.value,
    required this.onChanged,
  });
  
  final PluginStatus? value;
  final ValueChanged<PluginStatus?> onChanged;
  
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PluginStatus?>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Plugin Status',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<PluginStatus?>(
          value: null,
          child: Text('All Status'),
        ),
        ...PluginStatus.values.map((status) => DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(_getStatusIcon(status), size: 16),
              const SizedBox(width: 8),
              Text(status.displayName),
            ],
          ),
        )),
      ],
      onChanged: onChanged,
    );
  }
  
  IconData _getStatusIcon(PluginStatus status) {
    switch (status) {
      case PluginStatus.enabled:
        return Icons.check_circle;
      case PluginStatus.disabled:
        return Icons.pause_circle;
      case PluginStatus.installed:
        return Icons.download_done;
      case PluginStatus.error:
        return Icons.error;
      case PluginStatus.loading:
        return Icons.hourglass_empty;
    }
  }
}

/// Sort dropdown
class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.value,
    required this.onChanged,
  });
  
  final PluginSortBy value;
  final ValueChanged<PluginSortBy?> onChanged;
  
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PluginSortBy>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Sort By',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: PluginSortBy.name,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 16),
              SizedBox(width: 8),
              Text('Name'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: PluginSortBy.type,
          child: Row(
            children: [
              Icon(Icons.category, size: 16),
              SizedBox(width: 8),
              Text('Type'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: PluginSortBy.status,
          child: Row(
            children: [
              Icon(Icons.info, size: 16),
              SizedBox(width: 8),
              Text('Status'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: PluginSortBy.lastUpdated,
          child: Row(
            children: [
              Icon(Icons.update, size: 16),
              SizedBox(width: 8),
              Text('Last Updated'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: PluginSortBy.author,
          child: Row(
            children: [
              Icon(Icons.person, size: 16),
              SizedBox(width: 8),
              Text('Author'),
            ],
          ),
        ),
      ],
      onChanged: onChanged,
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}