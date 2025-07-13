import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import '../../../types/plugin.dart';
import 'plugin_interface.dart';
import 'plugin_package_service.dart';

/// Plugin Manager - 负责插件的生命周期管理
class PluginManager extends ChangeNotifier {
  static PluginManager? _instance;
  static PluginManager get instance => _instance ??= PluginManager._();
  
  PluginManager._();
  
  final Map<String, Plugin> _plugins = {};
  final Map<String, MarkoraPlugin> _loadedPlugins = {};
  final Map<String, PluginConfig> _configs = {};
  final List<PluginEventListener> _listeners = [];
  
  // 临时存储加载的插件状态，用于在插件扫描时应用
  final Map<String, PluginStatus> _pendingPluginStates = {};
  
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
    await _loadPluginConfigs();  // 先加载配置
    await _scanPlugins();        // 再扫描插件
    await _loadEnabledPlugins(); // 最后加载启用的插件
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
  
  /// Get current platform
  String _getCurrentPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  /// Check if the plugin supports the current platform
  bool _checkPlatformSupport(PluginMetadata metadata) {
    if (metadata.supportedPlatforms.isEmpty) {
      return true; // If not specified, supports all platforms
    }
    final currentPlatform = _getCurrentPlatform();
    return metadata.supportedPlatforms.contains(currentPlatform);
  }

  /// Load enabled plugins
  Future<void> _loadEnabledPlugins() async {
    for (final plugin in _plugins.values) {
      if (plugin.status == PluginStatus.enabled) {
        await loadPlugin(plugin.metadata.id);
      }
    }
  }

  Future<PluginMetadata?> _loadPluginMetadata(File manifestFile) async {
    try {
      final content = await manifestFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      // Check if this is a wrapped format (from .mxt package) or direct format
      if (json.containsKey('metadata')) {
        // This is a wrapped format from .mxt package installation
        final metadataJson = json['metadata'] as Map<String, dynamic>;
        debugPrint('Loading wrapped manifest format for plugin: ${metadataJson['id']}');
        return PluginMetadata.fromJson(metadataJson);
      } else {
        // This is direct format (legacy or development plugins)
        debugPrint('Loading direct manifest format for plugin: ${json['id']}');
        return PluginMetadata.fromJson(json);
      }
    } catch (e) {
      debugPrint('Failed to load plugin metadata from ${manifestFile.path}: $e');
      return null;
    }
  }

  Future<MarkoraPlugin?> _createPluginInstance(Plugin pluginInfo) async {
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
      
      return plugin;
    } catch (e) {
      debugPrint('Failed to load plugin: $e');
      return null;
    }
  }
  
  /// Load plugin
  Future<bool> loadPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      debugPrint('Plugin not found: $pluginId');
      return false;
    }
    
    if (_loadedPlugins.containsKey(pluginId)) {
      debugPrint('Plugin already loaded: $pluginId');
      return true;
    }
    
    try {
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.loading);
      
      // Update status to loading
      final oldStatus = plugin.status;
      _plugins[pluginId] = plugin.copyWith(status: PluginStatus.loading);
      _notifyStatusChanged(pluginId, oldStatus, PluginStatus.loading);
      
      // Check dependencies
      if (!_checkDependencies(plugin.metadata)) {
        throw Exception('Plugin dependencies not met');
      }
      
      final pluginInstance = await _createPluginInstance(plugin);
      if (pluginInstance == null) {
        throw Exception('Failed to create plugin instance');
      }
      
      // Initialize plugin
      if (_context != null) {
        await pluginInstance.onLoad(_context!);
      }
      
      _loadedPlugins[pluginId] = pluginInstance;
      
      // Update status to enabled
      _plugins[pluginId] = plugin.copyWith(status: PluginStatus.enabled);
      _notifyStatusChanged(pluginId, PluginStatus.loading, PluginStatus.enabled);
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.loaded);
      
      debugPrint('Plugin loaded successfully: $pluginId');
      return true;
    } catch (e) {
      debugPrint('Plugin loading failed: $pluginId - $e');
      
      // Update status to error
      _plugins[pluginId] = plugin.copyWith(status: PluginStatus.error);
      _notifyStatusChanged(pluginId, PluginStatus.loading, PluginStatus.error);
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.error, error: e.toString());
      
      return false;
    }
  }
  
  /// Unload plugin
  Future<bool> unloadPlugin(String pluginId) async {
    final pluginInstance = _loadedPlugins[pluginId];
    if (pluginInstance == null) {
      debugPrint('Plugin not loaded: $pluginId');
      return false;
    }
    
    try {
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.unloading);
      
      // Unload plugin
      await pluginInstance.onUnload();
      _loadedPlugins.remove(pluginId);
      
      // Update status
      final plugin = _plugins[pluginId];
      if (plugin != null) {
        _plugins[pluginId] = plugin.copyWith(status: PluginStatus.installed);
        _notifyStatusChanged(pluginId, PluginStatus.enabled, PluginStatus.installed);
      }
      
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.unloaded);
      
      debugPrint('Plugin unloaded successfully: $pluginId');
      return true;
    } catch (e) {
      debugPrint('Plugin unloading failed: $pluginId - $e');
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.error, error: e.toString());
      return false;
    }
  }
  
  /// Enable plugin
  Future<bool> enablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    if (plugin.status == PluginStatus.enabled) {
      return true; // Already enabled
    }
    
    final success = await loadPlugin(pluginId);
    if (success) {
      await _savePluginConfigs();
    }
    return success;
  }
  
  /// Disable plugin
  Future<bool> disablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    if (plugin.status != PluginStatus.enabled) {
      return true; // Already disabled
    }
    
    final success = await unloadPlugin(pluginId);
    if (success) {
      // Update status to disabled
      _plugins[pluginId] = plugin.copyWith(status: PluginStatus.disabled);
      _notifyStatusChanged(pluginId, PluginStatus.installed, PluginStatus.disabled);
      await _savePluginConfigs();
    }
    return success;
  }
  
  /// Get development plugins directory
  Future<Directory> getDevPluginsDirectory() async {
    try {
      if (kIsWeb) {
        debugPrint('Web environment: Using relative path for dev plugins');
        return Directory('plugins');
      }
      
      try {
        debugPrint('Current working directory: ${Directory.current.path}');
        
        final pluginsPath = path.join(Directory.current.path, 'plugins');
        debugPrint('Calculated dev plugin directory path: $pluginsPath');
        
        final pluginsDir = Directory(pluginsPath);
        final exists = await pluginsDir.exists();
        debugPrint('Dev plugin directory exists: $exists');
        
        if (!exists) {
          debugPrint('Creating dev plugin directory: $pluginsPath');
          await pluginsDir.create(recursive: true);
        }
        
        return pluginsDir;
      } catch (e) {
        debugPrint('Failed to access current directory: $e');
        return Directory('plugins');
      }
    } catch (e) {
      debugPrint('Failed to get dev plugin directory: $e');
      return Directory('plugins');
    }
  }
  
  /// Get installed plugins directory
  Future<Directory> getInstalledPluginsDirectory() async {
    try {
      if (kIsWeb) {
        debugPrint('Web environment: Using relative path for installed plugins');
        return Directory('installed_plugins');
      }
      
      try {
        debugPrint('Current working directory: ${Directory.current.path}');
        
        final pluginsPath = path.join(Directory.current.path, 'installed_plugins');
        debugPrint('Calculated installed plugin directory path: $pluginsPath');
        
        final pluginsDir = Directory(pluginsPath);
        final exists = await pluginsDir.exists();
        debugPrint('Installed plugin directory exists: $exists');
        
        if (!exists) {
          debugPrint('Creating installed plugin directory: $pluginsPath');
          await pluginsDir.create(recursive: true);
        }
        
        return pluginsDir;
      } catch (e) {
        debugPrint('Failed to access current directory: $e');
        return Directory('installed_plugins');
      }
    } catch (e) {
      debugPrint('Failed to get installed plugin directory: $e');
      return Directory('installed_plugins');
    }
  }
  
  /// Scan plugins directory (updated to scan both directories)
  Future<void> _scanPlugins() async {
    try {
      // Scan development plugins
      final devPluginsDir = await getDevPluginsDirectory();
      debugPrint('Dev plugins directory path: ${devPluginsDir.path}');
      await _scanPluginDirectory(devPluginsDir, isDevelopment: true);
      
      // Scan installed plugins
      final installedPluginsDir = await getInstalledPluginsDirectory();
      debugPrint('Installed plugins directory path: ${installedPluginsDir.path}');
      await _scanPluginDirectory(installedPluginsDir, isDevelopment: false);
      
      debugPrint('Plugin scanning completed');
      debugPrint('Currently loaded plugins: ${_plugins.keys.toList()}');
    } catch (e) {
      debugPrint('Failed to scan plugin directories: $e');
    }
  }
  
  /// Scan single plugin directory (updated with isDevelopment flag)
  Future<void> _scanPluginDirectory(Directory pluginsDir, {required bool isDevelopment}) async {
    try {
      if (!await pluginsDir.exists()) {
        debugPrint('Plugin directory does not exist: ${pluginsDir.path}');
        return;
      }
      
      debugPrint('Start scanning ${isDevelopment ? "development" : "installed"} plugin directory: ${pluginsDir.path}');
      var pluginCount = 0;
      
      await for (final entity in pluginsDir.list()) {
        debugPrint('Found entity: ${entity.path}, type: ${entity.runtimeType}');
        if (entity is Directory) {
          pluginCount++;
          await _scanSinglePluginDirectory(entity, isDevelopment: isDevelopment);
        }
      }
      
      debugPrint('Scanning completed for ${isDevelopment ? "development" : "installed"} plugins, found $pluginCount plugin directories');
    } catch (e) {
      debugPrint('Failed to scan plugin directory ${pluginsDir.path}: $e');
    }
  }
  
  /// Scan single plugin directory (renamed from original _scanPluginDirectory)
  Future<void> _scanSinglePluginDirectory(Directory pluginDir, {required bool isDevelopment}) async {
    try {
      final manifestFile = File('${pluginDir.path}/manifest.json');
      if (!await manifestFile.exists()) {
        debugPrint('Plugin manifest not found: ${manifestFile.path}');
        return;
      }
      
      debugPrint('Loading plugin metadata: ${manifestFile.path}');
      final metadata = await _loadPluginMetadata(manifestFile);
      if (metadata == null) {
        debugPrint('Plugin metadata loading failed: ${manifestFile.path}');
        return;
      }
      
      debugPrint('Successfully loaded ${isDevelopment ? "development" : "installed"} plugin metadata: ${metadata.id} - ${metadata.name}');

      // Check for platform support
      if (!_checkPlatformSupport(metadata)) {
        debugPrint('Plugin ${metadata.id} does not support the current platform');
        _plugins[metadata.id] = Plugin(
          metadata: metadata,
          status: PluginStatus.unsupported,
          installPath: pluginDir.path,
          installDate: _plugins[metadata.id]?.installDate ?? DateTime.now(),
          lastUpdated: DateTime.now(),
          isDevelopment: isDevelopment, // 添加此参数
        );
        return;
      }
      
      final existingPlugin = _plugins[metadata.id];
      final status = _pendingPluginStates[metadata.id] ?? existingPlugin?.status ?? PluginStatus.installed;
      
      if (_pendingPluginStates.containsKey(metadata.id)) {
        _pendingPluginStates.remove(metadata.id);
        debugPrint('Applied pending status for ${metadata.id}: ${status.name}');
      }
      
      final plugin = Plugin(
        metadata: metadata,
        status: status,
        installPath: pluginDir.path,
        installDate: existingPlugin?.installDate ?? DateTime.now(),
        lastUpdated: DateTime.now(),
        isDevelopment: isDevelopment,
      );
      
      _plugins[metadata.id] = plugin;
      debugPrint('Plugin registered: ${metadata.id} with status: ${status.name}, isDevelopment: $isDevelopment');
    } catch (e) {
      debugPrint('Failed to scan plugin directory ${pluginDir.path}: $e');
    }
  }
  
  /// Install plugin from .mxt package (updated to use installed_plugins directory)
  Future<bool> installPlugin(String mxtPath) async {
    try {
      final pluginFile = File(mxtPath);
      if (!await pluginFile.exists()) {
        debugPrint('Plugin package file not found: $mxtPath');
        return false;
      }
      
      // Get the installation directory for installed plugins
      final installedPluginsDir = await getInstalledPluginsDirectory();
      
      // Install the package
      final installPath = await PluginPackageService.installPackage(
        packagePath: mxtPath,
        installDir: installedPluginsDir.path,
      );
      
      // Scan the newly installed plugin directory
      await _scanSinglePluginDirectory(Directory(installPath), isDevelopment: false);
      
      // Persist the new plugin's state
      await _savePluginConfigs();

      // Notify listeners about the change
      notifyListeners();
      debugPrint('Plugin installation completed, UI notified');
      
      debugPrint('Plugin from $mxtPath installed successfully to $installPath');
      return true;
    } catch (e) {
      debugPrint('Plugin installation failed: $e');
      return false;
    }
  }
  
  /// Uninstall plugin (removes from registry and deletes files for installed plugins only)
  Future<bool> uninstallPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    try {
      // Disable plugin first
      await disablePlugin(pluginId);
      
      // Only delete files for installed plugins (not development plugins)
      if (!plugin.isDevelopment && plugin.installPath != null) {
        final pluginDir = Directory(plugin.installPath!);
        final installedPluginsDir = await getInstalledPluginsDirectory();
        
        // Ensure the plugin is in the installed_plugins directory before deleting
        if (pluginDir.path.startsWith(installedPluginsDir.path)) {
          if (await pluginDir.exists()) {
            debugPrint('Deleting installed plugin files: ${pluginDir.path}');
            await pluginDir.delete(recursive: true);
            debugPrint('Plugin files deleted successfully');
          }
        } else {
          debugPrint('Plugin is not in installed_plugins directory, skipping file deletion');
        }
      } else {
        debugPrint('Plugin is a development plugin, keeping files intact');
      }
      
      // Remove from registry
      _plugins.remove(pluginId);
      _configs.remove(pluginId);
      
      // Save updated configuration
      await _savePluginConfigs();
      
      notifyListeners();
      debugPrint('Plugin $pluginId uninstalled successfully');
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
          await _scanSinglePluginDirectory(pluginDir, isDevelopment: plugin.isDevelopment);
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
  
  /// Load plugin configurations
  Future<void> _loadPluginConfigs() async {
    try {
      // 使用Hive存储插件配置
      final box = await Hive.openBox('plugin_configs');
      
      // 加载插件状态
      final pluginStates = box.get('plugin_states', defaultValue: <String, String>{}) as Map<String, String>;
      
      // 加载插件配置
      final pluginConfigs = box.get('plugin_configs', defaultValue: <String, Map<String, dynamic>>{}) as Map<String, Map<String, dynamic>>;
      
      // 应用加载的状态
      for (final entry in pluginStates.entries) {
        final pluginId = entry.key;
        final statusString = entry.value;
        final status = _parsePluginStatus(statusString);
        
        // 如果插件已存在，更新其状态
        if (_plugins.containsKey(pluginId)) {
          _plugins[pluginId] = _plugins[pluginId]!.copyWith(status: status);
        } else {
          // 如果插件还不存在，暂存状态，等待插件扫描时应用
          _pendingPluginStates[pluginId] = status;
        }
      }
      
      // 应用加载的配置
      for (final entry in pluginConfigs.entries) {
        final pluginId = entry.key;
        final config = entry.value;
        
        _configs[pluginId] = PluginConfig(
          pluginId: pluginId,
          config: config,
          isEnabled: pluginStates[pluginId] == 'enabled',
        );
      }
      
      debugPrint('Plugin configurations loaded successfully');
    } catch (e) {
      debugPrint('Failed to load plugin configurations: $e');
    }
  }
  
  /// Save plugin configurations
  Future<void> _savePluginConfigs() async {
    try {
      // 使用Hive存储插件配置
      final box = await Hive.openBox('plugin_configs');
      
      // 保存插件状态
      final pluginStates = <String, String>{};
      for (final plugin in _plugins.values) {
        pluginStates[plugin.metadata.id] = plugin.status.name;
      }
      await box.put('plugin_states', pluginStates);
      
      // 保存插件配置
      final pluginConfigs = <String, Map<String, dynamic>>{};
      for (final config in _configs.values) {
        pluginConfigs[config.pluginId] = config.config;
      }
      await box.put('plugin_configs', pluginConfigs);
      
      debugPrint('Plugin configurations saved successfully');
    } catch (e) {
      debugPrint('Failed to save plugin configurations: $e');
    }
  }
  
  /// 解析插件状态字符串
  PluginStatus _parsePluginStatus(String statusString) {
    switch (statusString) {
      case 'enabled':
        return PluginStatus.enabled;
      case 'disabled':
        return PluginStatus.disabled;
      case 'installed':
        return PluginStatus.installed;
      case 'error':
        return PluginStatus.error;
      case 'loading':
        return PluginStatus.loading;
      default:
        return PluginStatus.installed;
    }
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
  @override
  void dispose() {
    // Cleanup logic here
    super.dispose();
  }

  /// Refresh and scan plugins
  Future<void> scanPlugins() async {
    debugPrint('Manual plugin scan requested');
    await _scanPlugins();
    notifyListeners();
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
    debugPrint('Loading generic plugin proxy: ${metadata.name}');
  }

  @override
  Future<void> onUnload() async {
    debugPrint('Unloading generic plugin proxy: ${metadata.name}');
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    debugPrint('Generic plugin proxy config changed: $config');
  }
}