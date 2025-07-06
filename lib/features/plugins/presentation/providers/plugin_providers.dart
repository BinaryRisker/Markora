import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../types/plugin.dart';
import '../../domain/plugin_manager.dart';
import '../../domain/plugin_interface.dart';

/// 插件管理器Provider
final pluginManagerProvider = ChangeNotifierProvider<PluginManager>((ref) {
  return PluginManager.instance;
});

/// 所有插件列表
final pluginsProvider = Provider<List<Plugin>>((ref) {
  final manager = ref.watch(pluginManagerProvider);
  return manager.plugins;
});

/// 已加载插件列表Provider
final loadedPluginsProvider = Provider<List<Plugin>>((ref) {
  final manager = ref.watch(pluginManagerProvider);
  return manager.loadedPlugins;
});

/// 已启用插件列表Provider
final enabledPluginsProvider = Provider<List<Plugin>>((ref) {
  final manager = ref.watch(pluginManagerProvider);
  return manager.enabledPlugins;
});

/// 按类型分组的插件Provider
final pluginsByTypeProvider = Provider<Map<PluginType, List<Plugin>>>((ref) {
  final plugins = ref.watch(pluginsProvider);
  final Map<PluginType, List<Plugin>> grouped = {};
  
  for (final plugin in plugins) {
    final type = plugin.metadata.type;
    grouped[type] = [...(grouped[type] ?? []), plugin];
  }
  
  return grouped;
});

/// 插件搜索Provider
final pluginSearchProvider = StateProvider<String>((ref) => '');

/// 过滤后的插件列表Provider
final filteredPluginsProvider = Provider<List<Plugin>>((ref) {
  final plugins = ref.watch(pluginsProvider);
  final searchQuery = ref.watch(pluginSearchProvider);
  
  if (searchQuery.isEmpty) {
    return plugins;
  }
  
  return plugins.where((plugin) {
    final query = searchQuery.toLowerCase();
    return plugin.metadata.name.toLowerCase().contains(query) ||
           plugin.metadata.description.toLowerCase().contains(query) ||
           plugin.metadata.author.toLowerCase().contains(query) ||
           plugin.metadata.tags.any((tag) => tag.toLowerCase().contains(query));
  }).toList();
});

/// 插件类型过滤Provider
final pluginTypeFilterProvider = StateProvider<PluginType?>((ref) => null);

/// 插件状态过滤Provider
final pluginStatusFilterProvider = StateProvider<PluginStatus?>((ref) => null);

/// 应用过滤器后的插件列表Provider
final filteredPluginsByFiltersProvider = Provider<List<Plugin>>((ref) {
  final plugins = ref.watch(filteredPluginsProvider);
  final typeFilter = ref.watch(pluginTypeFilterProvider);
  final statusFilter = ref.watch(pluginStatusFilterProvider);
  
  var filtered = plugins;
  
  if (typeFilter != null) {
    filtered = filtered.where((plugin) => plugin.metadata.type == typeFilter).toList();
  }
  
  if (statusFilter != null) {
    filtered = filtered.where((plugin) => plugin.status == statusFilter).toList();
  }
  
  return filtered;
});

/// 单个插件Provider
final pluginProvider = Provider.family<Plugin?, String>((ref, pluginId) {
  final manager = ref.watch(pluginManagerProvider);
  return manager.getPlugin(pluginId);
});

/// 插件配置Provider
final pluginConfigProvider = FutureProvider.family<PluginConfig?, String>((ref, pluginId) async {
  final manager = ref.watch(pluginManagerProvider);
  return manager.getPluginConfig(pluginId);
});

/// 插件操作Provider
final pluginActionsProvider = Provider<PluginActions>((ref) {
  final manager = ref.watch(pluginManagerProvider);
  return PluginActions(manager);
});

/// 插件统计信息Provider
final pluginStatsProvider = Provider<PluginStats>((ref) {
  final plugins = ref.watch(pluginsProvider);
  
  // 按类型统计
  final pluginsByType = <PluginType, int>{};
  for (final type in PluginType.values) {
    pluginsByType[type] = plugins.where((p) => p.metadata.type == type).length;
  }
  
  final stats = PluginStats(
    total: plugins.length,
    enabled: plugins.where((p) => p.status == PluginStatus.enabled).length,
    disabled: plugins.where((p) => p.status == PluginStatus.disabled).length,
    installed: plugins.where((p) => p.status == PluginStatus.installed).length,
    error: plugins.where((p) => p.status == PluginStatus.error).length,
    pluginsByType: pluginsByType,
  );
  
  return stats;
});

/// 插件操作类
class PluginActions {
  final PluginManager _manager;
  
  PluginActions(this._manager);
  
  /// 启用插件
  Future<bool> enablePlugin(String pluginId) async {
    try {
      await _manager.enablePlugin(pluginId);
      return true;
    } catch (e) {
      debugPrint('启用插件失败: $e');
      return false;
    }
  }
  
  /// 禁用插件
  Future<bool> disablePlugin(String pluginId) async {
    try {
      await _manager.disablePlugin(pluginId);
      return true;
    } catch (e) {
      debugPrint('禁用插件失败: $e');
      return false;
    }
  }
  
  /// 安装插件
  Future<bool> installPlugin(String pluginPath) async {
    try {
      await _manager.installPlugin(pluginPath);
      return true;
    } catch (e) {
      debugPrint('安装插件失败: $e');
      return false;
    }
  }
  
  /// 卸载插件
  Future<bool> uninstallPlugin(String pluginId) async {
    try {
      await _manager.uninstallPlugin(pluginId);
      return true;
    } catch (e) {
      debugPrint('卸载插件失败: $e');
      return false;
    }
  }
  
  /// 重新加载插件
  Future<bool> reloadPlugin(String pluginId) async {
    try {
      await _manager.reloadPlugin(pluginId);
      return true;
    } catch (e) {
      debugPrint('重新加载插件失败: $e');
      return false;
    }
  }
  
  /// 更新插件配置
  Future<void> updateConfig(String pluginId, Map<String, dynamic> config) async {
    try {
      await _manager.updatePluginConfig(pluginId, config);
    } catch (e) {
      debugPrint('更新插件配置失败: $e');
      rethrow;
    }
  }
}

/// 插件统计信息
class PluginStats {
  const PluginStats({
    required this.total,
    required this.enabled,
    required this.disabled,
    required this.installed,
    required this.error,
    required this.pluginsByType,
  });
  
  final int total;
  final int enabled;
  final int disabled;
  final int installed;
  final int error;
  final Map<PluginType, int> pluginsByType;
  
  int get inactive => disabled + installed;
}

/// 插件排序方式
enum PluginSortBy {
  name,
  author,
  type,
  status,
  installDate,
  lastUpdated,
}

/// 插件排序Provider
final pluginSortProvider = StateProvider<PluginSortBy>((ref) => PluginSortBy.name);

/// 排序方向Provider
final pluginSortAscendingProvider = StateProvider<bool>((ref) => true);

/// 排序后的插件列表Provider
final sortedPluginsProvider = Provider<List<Plugin>>((ref) {
  final plugins = ref.watch(filteredPluginsByFiltersProvider);
  final sortBy = ref.watch(pluginSortProvider);
  final ascending = ref.watch(pluginSortAscendingProvider);
  
  final sorted = List<Plugin>.from(plugins);
  
  switch (sortBy) {
    case PluginSortBy.name:
      sorted.sort((a, b) => a.metadata.name.compareTo(b.metadata.name));
      break;
    case PluginSortBy.author:
      sorted.sort((a, b) => a.metadata.author.compareTo(b.metadata.author));
      break;
    case PluginSortBy.type:
      sorted.sort((a, b) => a.metadata.type.displayName.compareTo(b.metadata.type.displayName));
      break;
    case PluginSortBy.status:
      sorted.sort((a, b) => a.status.displayName.compareTo(b.status.displayName));
      break;
    case PluginSortBy.installDate:
      sorted.sort((a, b) {
        final dateA = a.installDate ?? DateTime(1970);
        final dateB = b.installDate ?? DateTime(1970);
        return dateA.compareTo(dateB);
      });
      break;
    case PluginSortBy.lastUpdated:
      sorted.sort((a, b) {
        final dateA = a.lastUpdated ?? DateTime(1970);
        final dateB = b.lastUpdated ?? DateTime(1970);
        return dateA.compareTo(dateB);
      });
      break;
  }
  
  if (!ascending) {
    return sorted.reversed.toList();
  }
  
  return sorted;
});