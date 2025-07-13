import '../../../types/plugin.dart';
import 'plugin_factory.dart';
import 'plugin_interface.dart';

/// Plugin registry initializer - 插件注册框架
/// 所有具体插件实现已移至 plugins/ 目录
class PluginRegistryInitializer {
  /// Initialize plugin system - 具体插件通过插件目录动态加载
  static void initializeBuiltInPlugins() {
    // 插件系统初始化完成
    // 具体插件将通过 PluginManager 从 plugins/ 目录动态加载
    print('Plugin system initialized - plugins will be loaded from plugins/ directory');
  }
  
  /// Register external plugin factory
  static void registerExternalPlugin(
    String pluginId,
    PluginMetadata metadata,
    MarkoraPlugin Function() factory,
  ) {
    PluginFactory.registerFactory(pluginId, factory);
    print('External plugin registered: $pluginId');
  }
  
  /// Unregister plugin factory
  static void unregisterPlugin(String pluginId) {
    PluginFactory.unregisterFactory(pluginId);
    print('Plugin unregistered: $pluginId');
  }
  
  /// Get all registered plugin IDs
  static List<String> getRegisteredPlugins() {
    return PluginFactory.getRegisteredPluginIds();
  }
  
  /// Check if plugin is registered
  static bool isPluginRegistered(String pluginId) {
    return PluginFactory.isRegistered(pluginId);
  }
}