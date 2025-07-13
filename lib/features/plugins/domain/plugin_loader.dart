import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import '../../../types/plugin.dart';
import 'plugin_interface.dart';

/// Plugin loader service for managing plugin lifecycle
class PluginLoader {
  static final PluginLoader _instance = PluginLoader._internal();
  factory PluginLoader() => _instance;
  PluginLoader._internal();

  final Map<String, MarkoraPlugin> _loadedPlugins = {};
  final Map<String, PluginMetadata> _pluginMetadata = {};

  /// Load plugin metadata from manifest file
  Future<PluginMetadata?> loadPluginMetadata(File manifestFile) async {
    try {
      final content = await manifestFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return PluginMetadata.fromJson(json);
    } catch (e) {
      debugPrint('Failed to load plugin metadata: $e');
      return null;
    }
  }
  
  /// Load plugin instance based on plugin info
  Future<BasePlugin?> loadPlugin(Plugin pluginInfo) async {
    try {
      final metadata = pluginInfo.metadata;
      BasePlugin plugin;
      
      switch (metadata.type) {
        case PluginType.syntax:
          plugin = SyntaxPluginImpl(metadata);
          break;
        case PluginType.renderer:
          plugin = RendererPluginImpl(metadata);
          break;
        case PluginType.theme:
          plugin = ThemePluginImpl(metadata);
          break;
        case PluginType.exporter:
          plugin = ExporterPluginImpl(metadata);
          break;
        case PluginType.tool:
          plugin = ToolPluginImpl(metadata);
          break;
        case PluginType.integration:
          plugin = IntegrationPluginImpl(metadata);
          break;
        default:
          plugin = _GenericPluginProxy(metadata, pluginInfo.installPath ?? '');
      }
      
      _loadedPlugins[metadata.id] = plugin;
      _pluginMetadata[metadata.id] = metadata;
      
      return plugin;
    } catch (e) {
      debugPrint('Failed to load plugin: $e');
      return null;
    }
  }

  /// Unload plugin and cleanup resources
  Future<void> unloadPlugin(String pluginId) async {
    try {
      final plugin = _loadedPlugins[pluginId];
      if (plugin != null) {
        await plugin.onUnload();
        _loadedPlugins.remove(pluginId);
        _pluginMetadata.remove(pluginId);
      }
    } catch (e) {
      debugPrint('Error unloading plugin $pluginId: $e');
    }
  }

  /// Get loaded plugin by ID
  MarkoraPlugin? getPlugin(String pluginId) {
    return _loadedPlugins[pluginId];
  }

  /// Get all loaded plugins
  Map<String, MarkoraPlugin> getAllPlugins() {
    return Map.unmodifiable(_loadedPlugins);
  }

  /// Get plugin metadata by ID
  PluginMetadata? getPluginMetadata(String pluginId) {
    return _pluginMetadata[pluginId];
  }
}

/// Unimplemented plugin placeholder
class UnimplementedPlugin extends BasePlugin {
  UnimplementedPlugin(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;

  @override
  Future<void> onLoad(PluginContext context) async {
    debugPrint('Loading unimplemented plugin: ${metadata.name}');
  }

  @override
  Future<void> onUnload() async {
    debugPrint('Unloading unimplemented plugin: ${metadata.name}');
  }
}

/// Syntax plugin implementation
class SyntaxPluginImpl extends BasePlugin {
  SyntaxPluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;

  @override
  Future<void> onLoad(PluginContext context) async {
    debugPrint('Loading syntax plugin: ${metadata.name}');
  }

  @override
  Future<void> onUnload() async {
    debugPrint('Unloading syntax plugin: ${metadata.name}');
  }
}

/// Renderer plugin implementation
class RendererPluginImpl extends BasePlugin {
  RendererPluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;

  @override
  Future<void> onLoad(PluginContext context) async {
    debugPrint('Loading renderer plugin: ${metadata.name}');
  }

  @override
  Future<void> onUnload() async {
    debugPrint('Unloading renderer plugin: ${metadata.name}');
  }
}

/// Theme plugin implementation
class ThemePluginImpl extends BasePlugin {
  ThemePluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;

  @override
  Future<void> onLoad(PluginContext context) async {
    debugPrint('Loading theme plugin: ${metadata.name}');
  }

  @override
  Future<void> onUnload() async {
    debugPrint('Unloading theme plugin: ${metadata.name}');
  }
}

/// Exporter plugin implementation
class ExporterPluginImpl extends BasePlugin {
  ExporterPluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;

  @override
  Future<void> onLoad(PluginContext context) async {
    debugPrint('Loading exporter plugin: ${metadata.name}');
  }

  @override
  Future<void> onUnload() async {
    debugPrint('Unloading exporter plugin: ${metadata.name}');
  }
}

/// Tool plugin implementation
class ToolPluginImpl extends BasePlugin {
  ToolPluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;

  @override
  Future<void> onLoad(PluginContext context) async {
    debugPrint('Loading tool plugin: ${metadata.name}');
  }

  @override
  Future<void> onUnload() async {
    debugPrint('Unloading tool plugin: ${metadata.name}');
  }
}

/// Integration plugin implementation
class IntegrationPluginImpl extends BasePlugin {
  IntegrationPluginImpl(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;

  @override
  Future<void> onLoad(PluginContext context) async {
    debugPrint('Loading integration plugin: ${metadata.name}');
  }

  @override
  Future<void> onUnload() async {
    debugPrint('Unloading integration plugin: ${metadata.name}');
  }
}

/// Generic plugin proxy for external plugins
class _GenericPluginProxy extends BasePlugin {
  _GenericPluginProxy(this._metadata, this._pluginPath);
  
  final PluginMetadata _metadata;
  final String _pluginPath;
  PluginContext? _context;
  
  @override
  PluginMetadata get metadata => _metadata;

  @override
  Future<void> onLoad(PluginContext context) async {
    _context = context;
    debugPrint('Loading external plugin: ${metadata.name} from $_pluginPath');
    
    try {
      // Register plugin actions if any
      if (metadata.type == PluginType.tool) {
        final action = PluginAction(
          id: '${metadata.id}_action',
          title: metadata.name,
          description: metadata.description,
          icon: 'extension',
        );
        
        // Register action with toolbar registry
        context.toolbarRegistry.registerAction(
          action,
          () async {
            debugPrint('External plugin action executed: ${metadata.name}');
          },
        );
      }
      
      debugPrint('External plugin loaded successfully: ${metadata.name}');
    } catch (e) {
      debugPrint('Failed to load external plugin ${metadata.name}: $e');
      rethrow;
    }
  }

  @override
  Future<void> onUnload() async {
    try {
      // Cleanup plugin resources
      if (_context != null && metadata.type == PluginType.tool) {
        _context!.toolbarRegistry.unregisterAction('${metadata.id}_action');
      }
      
      debugPrint('External plugin unloaded: ${metadata.name}');
    } catch (e) {
      debugPrint('Error unloading external plugin ${metadata.name}: $e');
    }
  }

  @override
  Widget? getConfigWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.extension,
            size: 48,
            color: Colors.blue[600],
          ),
          const SizedBox(height: 16),
          Text(
            'External Plugin: ${metadata.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            metadata.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Plugin Path: $_pluginPath',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}