import 'package:flutter/material.dart';
import '../../../types/plugin.dart';
import 'plugin_interface.dart';
import 'plugin_loader.dart';

/// Plugin factory for creating plugin instances
class PluginFactory {
  static final Map<String, MarkoraPlugin Function()> _factories = {};
  
  /// Register a plugin factory
  static void registerFactory(String pluginId, MarkoraPlugin Function() factory) {
    _factories[pluginId] = factory;
  }
  
  /// Create plugin instance
  static MarkoraPlugin createPlugin(PluginMetadata metadata) {
    final factory = _factories[metadata.id];
    
    if (factory != null) {
      return factory();
    }
    
    // Fallback to generic implementations based on type
    switch (metadata.type) {
      case PluginType.syntax:
        return SyntaxPluginImpl(metadata);
      case PluginType.theme:
        return ThemePluginImpl(metadata);
      case PluginType.export:
        return ExporterPluginImpl(metadata);
      case PluginType.tool:
        return ToolPluginImpl(metadata);
      case PluginType.widget:
        return WidgetPluginImpl(metadata);
      default:
        return UnimplementedPlugin(metadata);
    }
  }
  
  /// Get all registered plugin IDs
  static List<String> getRegisteredPluginIds() {
    return _factories.keys.toList();
  }
  
  /// Check if a plugin factory is registered
  static bool isRegistered(String pluginId) {
    return _factories.containsKey(pluginId);
  }
  
  /// Unregister a plugin factory
  static void unregisterFactory(String pluginId) {
    _factories.remove(pluginId);
  }
  
  /// Clear all factories
  static void clearFactories() {
    _factories.clear();
  }
}

/// Generic plugin implementations
class ExporterPluginImpl extends BasePlugin {
  ExporterPluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    debugPrint('Exporter plugin ${metadata.id} loaded');
  }
}

class ToolPluginImpl extends BasePlugin {
  ToolPluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    debugPrint('Tool plugin ${metadata.id} loaded');
  }
}

class WidgetPluginImpl extends BasePlugin {
  WidgetPluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    debugPrint('Widget plugin ${metadata.id} loaded');
  }
}