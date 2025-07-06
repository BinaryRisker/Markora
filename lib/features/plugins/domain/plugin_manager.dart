import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../types/plugin.dart';
import 'plugin_interface.dart';
import 'plugin_loader.dart';

/// Plugin Manager
class PluginManager extends ChangeNotifier {
  static PluginManager? _instance;
  static PluginManager get instance => _instance ??= PluginManager._();
  
  PluginManager._();
  
  final Map<String, Plugin> _plugins = {};
  final Map<String, MarkoraPlugin> _loadedPlugins = {};
  final Map<String, PluginConfig> _configs = {};
  final List<PluginEventListener> _listeners = [];
  final PluginLoader _loader = PluginLoader();
  
  PluginContext? _context;
  
  /// Get plugin context
  PluginContext? get context => _context;
  
  /// All plugins list
  List<Plugin> get plugins => _plugins.values.toList();
  
  /// Loaded plugins list
  List<Plugin> get loadedPlugins => _plugins.values
      .where((plugin) => _loadedPlugins.containsKey(plugin.metadata.id))
      .toList();
  
  /// Enabled plugins list
  List<Plugin> get enabledPlugins => _plugins.values
      .where((plugin) => plugin.status == PluginStatus.enabled)
      .toList();
  
  /// Initialize plugin manager
  Future<void> initialize(PluginContext context) async {
    _context = context;
    await _loadPluginConfigs();
    await _scanPlugins();
    await _loadEnabledPlugins();
  }
  
  /// Add event listener
  void addPluginListener(PluginEventListener listener) {
    _listeners.add(listener);
  }
  
  /// Remove event listener
  void removePluginListener(PluginEventListener listener) {
    _listeners.remove(listener);
  }
  
  /// Notify lifecycle event
  void _notifyLifecycleEvent(String pluginId, PluginLifecycleEvent event, {String? error}) {
    for (final listener in _listeners) {
      listener.onPluginLifecycleEvent(pluginId, event, error: error);
    }
  }
  
  /// Notify status change event
  void _notifyStatusChanged(String pluginId, PluginStatus oldStatus, PluginStatus newStatus) {
    for (final listener in _listeners) {
      listener.onPluginStatusChanged(pluginId, oldStatus, newStatus);
    }
    notifyListeners();
  }
  
  /// Scan plugins directory
  Future<void> _scanPlugins() async {
    try {
      final pluginsDir = await _getPluginsDirectory();
      debugPrint('Plugins directory path: ${pluginsDir.path}');
      
      // Skip directory scanning in Web environment
      if (kIsWeb) {
        debugPrint('Web environment: Skip plugin directory scanning');
        // Manually add known plugins in Web environment
        await _scanKnownPlugins();
        return;
      }
      
      if (!await pluginsDir.exists()) {
        debugPrint('Plugin directory does not exist, creating: ${pluginsDir.path}');
        await pluginsDir.create(recursive: true);
        return;
      }
      
      debugPrint('Start scanning plugin directory: ${pluginsDir.path}');
      var pluginCount = 0;
      
      await for (final entity in pluginsDir.list()) {
        debugPrint('Found entity: ${entity.path}, type: ${entity.runtimeType}');
        if (entity is Directory) {
          pluginCount++;
          await _scanPluginDirectory(entity);
        }
      }
      
      debugPrint('Scanning completed, found $pluginCount plugin directories');
      debugPrint('Currently loaded plugins: ${_plugins.keys.toList()}');
    } catch (e) {
      debugPrint('Failed to scan plugin directory: $e');
    }
  }
  
  /// Scan known plugins (Web environment only)
  Future<void> _scanKnownPlugins() async {
    try {
      // Manually add mermaid plugin
      final mermaidPluginDir = Directory('plugins/mermaid_plugin');
      await _scanPluginDirectory(mermaidPluginDir);
      
      debugPrint('Web environment plugin scanning completed');
    } catch (e) {
      debugPrint('Web environment plugin scanning failed: $e');
    }
  }
  
  /// Scan single plugin directory
  Future<void> _scanPluginDirectory(Directory pluginDir) async {
    try {
      debugPrint('Scanning plugin directory: ${pluginDir.path}');
      final manifestFile = File(path.join(pluginDir.path, 'plugin.json'));
      debugPrint('Looking for plugin manifest file: ${manifestFile.path}');
      
      if (!await manifestFile.exists()) {
        debugPrint('Plugin manifest file does not exist: ${manifestFile.path}');
        return;
      }
      
      debugPrint('Loading plugin metadata: ${manifestFile.path}');
      final metadata = await _loader.loadPluginMetadata(manifestFile);
      if (metadata == null) {
        debugPrint('Plugin metadata loading failed: ${manifestFile.path}');
        return;
      }
      
      debugPrint('Successfully loaded plugin metadata: ${metadata.id} - ${metadata.name}');
      
      final existingPlugin = _plugins[metadata.id];
      final status = existingPlugin?.status ?? PluginStatus.installed;
      
      final plugin = Plugin(
        metadata: metadata,
        status: status,
        installPath: pluginDir.path,
        installDate: existingPlugin?.installDate ?? DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      _plugins[metadata.id] = plugin;
      debugPrint('Plugin added to manager: ${metadata.id}');
    } catch (e) {
      debugPrint('Failed to scan plugin directory ${pluginDir.path}: $e');
    }
  }
  
  /// Load enabled plugins
  Future<void> _loadEnabledPlugins() async {
    for (final plugin in _plugins.values) {
      if (plugin.status == PluginStatus.enabled) {
        await loadPlugin(plugin.metadata.id);
      }
    }
  }
  
  /// Load plugin
  Future<bool> loadPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    if (_loadedPlugins.containsKey(pluginId)) {
      return true; // Already loaded
    }
    
    try {
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.loading);
      
      final pluginInstance = await _loader.loadPlugin(plugin);
      if (pluginInstance == null) {
        throw Exception('Plugin loading failed');
      }
      
      if (_context != null) {
        await pluginInstance.onLoad(_context!);
      }
      
      _loadedPlugins[pluginId] = pluginInstance;
      
      final oldStatus = plugin.status;
      final newStatus = PluginStatus.enabled;
      _plugins[pluginId] = plugin.copyWith(status: newStatus);
      
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.loaded);
      _notifyStatusChanged(pluginId, oldStatus, newStatus);
      
      return true;
    } catch (e) {
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.error, error: e.toString());
      
      final oldStatus = plugin.status;
      final newStatus = PluginStatus.error;
      _plugins[pluginId] = plugin.copyWith(
        status: newStatus,
        errorMessage: e.toString(),
      );
      
      _notifyStatusChanged(pluginId, oldStatus, newStatus);
      return false;
    }
  }
  
  /// Unload plugin
  Future<bool> unloadPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    final pluginInstance = _loadedPlugins[pluginId];
    
    if (plugin == null || pluginInstance == null) return false;
    
    try {
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.unloading);
      
      await pluginInstance.onUnload();
      _loadedPlugins.remove(pluginId);
      
      final oldStatus = plugin.status;
      final newStatus = PluginStatus.installed;
      _plugins[pluginId] = plugin.copyWith(status: newStatus);
      
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.unloaded);
      _notifyStatusChanged(pluginId, oldStatus, newStatus);
      
      return true;
    } catch (e) {
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.error, error: e.toString());
      return false;
    }
  }
  
  /// Enable plugin
  Future<bool> enablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    if (plugin.status == PluginStatus.enabled) return true;
    
    return await loadPlugin(pluginId);
  }
  
  /// Disable plugin
  Future<bool> disablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    if (plugin.status != PluginStatus.enabled) return true;
    
    return await unloadPlugin(pluginId);
  }
  
  /// Install plugin
  Future<bool> installPlugin(String pluginPath) async {
    try {
      final pluginFile = File(pluginPath);
      if (!await pluginFile.exists()) return false;
      
      // TODO: Implement plugin installation logic (extract, validate, copy, etc.)
      // Need to handle different plugin formats (zip, tar.gz, etc.)
      
      await _scanPlugins();
      return true;
    } catch (e) {
      debugPrint('Plugin installation failed: $e');
      return false;
    }
  }
  
  /// Uninstall plugin
  Future<bool> uninstallPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    try {
      // Disable plugin first
      await disablePlugin(pluginId);
      
      // Delete plugin files
      if (plugin.installPath != null) {
        final pluginDir = Directory(plugin.installPath!);
        if (await pluginDir.exists()) {
          await pluginDir.delete(recursive: true);
        }
      }
      
      _plugins.remove(pluginId);
      _configs.remove(pluginId);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Plugin uninstallation failed: $e');
      return false;
    }
  }
  
  /// Reload plugin
  Future<bool> reloadPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    try {
      final wasEnabled = plugin.status == PluginStatus.enabled;
      
      // Unload plugin first
      if (wasEnabled) {
        await unloadPlugin(pluginId);
      }
      
      // Rescan plugin directory
      if (plugin.installPath != null) {
        final pluginDir = Directory(plugin.installPath!);
        if (await pluginDir.exists()) {
          await _scanPluginDirectory(pluginDir);
        }
      }
      
      // Re-enable if previously enabled
      if (wasEnabled) {
        return await loadPlugin(pluginId);
      }
      
      return true;
    } catch (e) {
      debugPrint('Plugin reload failed: $e');
      return false;
    }
  }
  
  /// Get plugin configuration
  PluginConfig? getPluginConfig(String pluginId) {
    return _configs[pluginId];
  }
  
  /// Update plugin configuration
  Future<void> updatePluginConfig(String pluginId, Map<String, dynamic> config) async {
    final pluginConfig = PluginConfig(
      pluginId: pluginId,
      config: config,
      isEnabled: _configs[pluginId]?.isEnabled ?? true,
    );
    
    _configs[pluginId] = pluginConfig;
    
    // Notify plugin configuration change
    final pluginInstance = _loadedPlugins[pluginId];
    if (pluginInstance != null) {
      pluginInstance.onConfigChanged(config);
    }
    
    for (final listener in _listeners) {
      listener.onPluginConfigChanged(pluginId, config);
    }
    
    await _savePluginConfigs();
  }
  
  /// Get plugins directory
  Future<Directory> _getPluginsDirectory() async {
    // Use relative path in Flutter Web
    // Use application data directory on other platforms
    try {
      // Check if it's Web environment
      if (kIsWeb) {
        debugPrint('Web environment: Using relative path');
        // Use relative path directly in Web environment, don't access Directory.current
        final pluginsDir = Directory('plugins');
        debugPrint('Plugin directory path: plugins');
        return pluginsDir;
      }
      
      debugPrint('Current working directory: ${Directory.current.path}');
      
      // Try to use plugins folder under project root directory
      final pluginsPath = path.join(Directory.current.path, 'plugins');
      debugPrint('Calculated plugin directory path: $pluginsPath');
      
      final pluginsDir = Directory(pluginsPath);
      final exists = await pluginsDir.exists();
      debugPrint('Plugin directory exists: $exists');
      
      // Try to create directory if it doesn't exist
      if (!exists) {
        debugPrint('Creating plugin directory: $pluginsPath');
        await pluginsDir.create(recursive: true);
      }
      
      return pluginsDir;
    } catch (e) {
      debugPrint('Failed to get plugin directory: $e');
      // Fallback to current directory
      return Directory('plugins');
    }
  }
  
  /// Load plugin configurations
  Future<void> _loadPluginConfigs() async {
    // TODO: Load plugin configurations from persistent storage
    // Can use Hive, SharedPreferences, etc.
  }
  
  /// Save plugin configurations
  Future<void> _savePluginConfigs() async {
    // TODO: Save plugin configurations to persistent storage
  }
  
  /// Get plugin instance
  MarkoraPlugin? getPluginInstance(String pluginId) {
    return _loadedPlugins[pluginId];
  }
  
  /// Get plugin information
  Plugin? getPlugin(String pluginId) {
    return _plugins[pluginId];
  }
  
  /// Check plugin dependencies
  bool _checkDependencies(PluginMetadata metadata) {
    for (final dependency in metadata.dependencies) {
      final dependencyPlugin = _plugins[dependency];
      if (dependencyPlugin == null || dependencyPlugin.status != PluginStatus.enabled) {
        return false;
      }
    }
    return true;
  }
  
  /// Clean up resources
  void dispose() {
    for (final pluginInstance in _loadedPlugins.values) {
      pluginInstance.onUnload().catchError((e) {
        debugPrint('Plugin unload failed: $e');
      });
    }
    _loadedPlugins.clear();
    _plugins.clear();
    _configs.clear();
    _listeners.clear();
    super.dispose();
  }
}