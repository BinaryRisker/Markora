import '../../features/plugins/domain/plugin_interface.dart';

typedef PluginFactory = MarkoraPlugin Function();

/// A central registry for plugin factories.
class PluginRegistry {
  static final Map<String, PluginFactory> _factories = {};

  /// Registers a plugin factory for a given plugin ID.
  static void register(String pluginId, PluginFactory factory) {
    _factories[pluginId] = factory;
    print('Registered plugin factory: $pluginId');
  }

  /// Retrieves the factory for a given plugin ID.
  static PluginFactory? getFactory(String pluginId) {
    return _factories[pluginId];
  }

  /// Returns all registered plugin IDs.
  static List<String> get registeredPluginIds => _factories.keys.toList();

  static MarkoraPlugin? createPlugin(String pluginId) {
    final factory = _factories[pluginId];
    return factory?.call();
  }
} 