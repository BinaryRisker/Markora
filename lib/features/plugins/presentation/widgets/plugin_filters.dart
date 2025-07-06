import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../types/plugin.dart';
import '../providers/plugin_providers.dart';

/// 插件过滤器组件
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
              '过滤和排序',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            
            // 过滤器行
            Row(
              children: [
                // 类型过滤
                Expanded(
                  child: _TypeFilterDropdown(
                    value: typeFilter,
                    onChanged: (type) {
                      ref.read(pluginTypeFilterProvider.notifier).state = type;
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 状态过滤
                Expanded(
                  child: _StatusFilterDropdown(
                    value: statusFilter,
                    onChanged: (status) {
                      ref.read(pluginStatusFilterProvider.notifier).state = status;
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 排序方式
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
                
                // 排序方向
                IconButton(
                  onPressed: () {
                    ref.read(pluginSortAscendingProvider.notifier).state = !sortAscending;
                  },
                  icon: Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  tooltip: sortAscending ? '升序' : '降序',
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 快速过滤按钮
            Wrap(
              spacing: 8,
              children: [
                _QuickFilterChip(
                  label: '全部',
                  isSelected: typeFilter == null && statusFilter == null,
                  onTap: () {
                    ref.read(pluginTypeFilterProvider.notifier).state = null;
                    ref.read(pluginStatusFilterProvider.notifier).state = null;
                  },
                ),
                _QuickFilterChip(
                  label: '已启用',
                  isSelected: statusFilter == PluginStatus.enabled,
                  onTap: () {
                    ref.read(pluginStatusFilterProvider.notifier).state = PluginStatus.enabled;
                  },
                ),
                _QuickFilterChip(
                  label: '语法插件',
                  isSelected: typeFilter == PluginType.syntax,
                  onTap: () {
                    ref.read(pluginTypeFilterProvider.notifier).state = PluginType.syntax;
                  },
                ),
                _QuickFilterChip(
                  label: '主题插件',
                  isSelected: typeFilter == PluginType.theme,
                  onTap: () {
                    ref.read(pluginTypeFilterProvider.notifier).state = PluginType.theme;
                  },
                ),
                _QuickFilterChip(
                  label: '工具插件',
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

/// 类型过滤下拉框
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
        labelText: '插件类型',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<PluginType?>(
          value: null,
          child: Text('全部类型'),
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
      case PluginType.exporter:
        return Icons.upload;
      case PluginType.integration:
        return Icons.link;
      case PluginType.other:
        return Icons.extension;
    }
  }
}

/// 状态过滤下拉框
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
        labelText: '插件状态',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<PluginStatus?>(
          value: null,
          child: Text('全部状态'),
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

/// 排序下拉框
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
        labelText: '排序方式',
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
              Text('名称'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: PluginSortBy.type,
          child: Row(
            children: [
              Icon(Icons.category, size: 16),
              SizedBox(width: 8),
              Text('类型'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: PluginSortBy.status,
          child: Row(
            children: [
              Icon(Icons.info, size: 16),
              SizedBox(width: 8),
              Text('状态'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: PluginSortBy.lastUpdated,
          child: Row(
            children: [
              Icon(Icons.update, size: 16),
              SizedBox(width: 8),
              Text('更新时间'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: PluginSortBy.author,
          child: Row(
            children: [
              Icon(Icons.person, size: 16),
              SizedBox(width: 8),
              Text('作者'),
            ],
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

/// 快速过滤芯片
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