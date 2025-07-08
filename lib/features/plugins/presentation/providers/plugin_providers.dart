import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../types/plugin.dart';
import '../../domain/plugin_manager.dart';
import '../../domain/plugin_interface.dart';

/// Plugin manager Provider
final pluginManagerProvider = ChangeNotifierProvider<PluginManager>((ref) {
  return PluginManager.instance;
});

/// All plugins list
final pluginsProvider = Provider<List<Plugin>>((ref) {
  final manager = ref.watch(pluginManagerProvider);
  return manager.plugins;
});

/// Loaded plugins list Provider
final loadedPluginsProvider = Provider<List<Plugin>>((ref) {
  final manager = ref.watch(pluginManagerProvider);
  return manager.loadedPlugins;
});

/// Enabled plugins list Provider
final enabledPluginsProvider = Provider<List<Plugin>>((ref) {
  final manager = ref.watch(pluginManagerProvider);
  return manager.enabledPlugins;
});

/// Plugins grouped by type Provider
final pluginsByTypeProvider = Provider<Map<PluginType, List<Plugin>>>((ref) {
  final plugins = ref.watch(pluginsProvider);
  final Map<PluginType, List<Plugin>> grouped = {};
  
  for (final plugin in plugins) {
    final type = plugin.metadata.type;
    grouped[type] = [...(grouped[type] ?? []), plugin];
  }
  
  return grouped;
});

/// Plugin search Provider
final pluginSearchProvider = StateProvider<String>((ref) => '');

/// Filtered plugins list Provider
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

/// Plugin type filter Provider
final pluginTypeFilterProvider = StateProvider<PluginType?>((ref) => null);

/// Plugin status filter Provider
final pluginStatusFilterProvider = StateProvider<PluginStatus?>((ref) => null);

/// Plugins list after applying filters Provider
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

/// Single plugin Provider
final pluginProvider = Provider.family<Plugin?, String>((ref, pluginId) {
  final manager = ref.watch(pluginManagerProvider);
  return manager.getPlugin(pluginId);
});

/// Plugin configuration Provider
final pluginConfigProvider = FutureProvider.family<PluginConfig?, String>((ref, pluginId) async {
  final manager = ref.watch(pluginManagerProvider);
  return manager.getPluginConfig(pluginId);
});

/// Plugin actions Provider
final pluginActionsProvider = Provider<PluginActions>((ref) {
  final manager = ref.watch(pluginManagerProvider);
  return PluginActions(manager);
});

/// Plugin statistics Provider
final pluginStatsProvider = Provider<PluginStats>((ref) {
  final plugins = ref.watch(pluginsProvider);
  
  // Statistics by type
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

/// Plugin actions class
class PluginActions {
  final PluginManager _manager;
  
  PluginActions(this._manager);
  
  /// Enable plugin
  Future<bool> enablePlugin(String pluginId) async {
    try {
      await _manager.enablePlugin(pluginId);
      return true;
    } catch (e) {
      debugPrint('Failed to enable plugin: $e');
      return false;
    }
  }
  
  /// Disable plugin
  Future<bool> disablePlugin(String pluginId) async {
    try {
      await _manager.disablePlugin(pluginId);
      return true;
    } catch (e) {
      debugPrint('Failed to disable plugin: $e');
      return false;
    }
  }
  
  /// Install plugin
  Future<bool> installPlugin(String pluginPath) async {
    try {
      await _manager.installPlugin(pluginPath);
      return true;
    } catch (e) {
      debugPrint('Failed to install plugin: $e');
      return false;
    }
  }
  
  /// Uninstall plugin
  Future<bool> uninstallPlugin(String pluginId) async {
    try {
      await _manager.uninstallPlugin(pluginId);
      return true;
    } catch (e) {
      debugPrint('Failed to uninstall plugin: $e');
      return false;
    }
  }
  
  /// Reload plugin
  Future<bool> reloadPlugin(String pluginId) async {
    try {
      await _manager.reloadPlugin(pluginId);
      return true;
    } catch (e) {
      debugPrint('Failed to reload plugin: $e');
      return false;
    }
  }
  
  /// Update plugin configuration
  Future<void> updateConfig(String pluginId, Map<String, dynamic> config) async {
    try {
      await _manager.updatePluginConfig(pluginId, config);
    } catch (e) {
      debugPrint('Failed to update plugin configuration: $e');
      rethrow;
    }
  }
}



/// Plugin sort Provider
final pluginSortProvider = StateProvider<PluginSortBy>((ref) => PluginSortBy.name);

/// Sort direction Provider
final pluginSortAscendingProvider = StateProvider<bool>((ref) => true);

/// Sorted plugins list Provider
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