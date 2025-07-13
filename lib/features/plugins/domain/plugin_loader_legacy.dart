import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import '../../../types/plugin.dart';
import 'plugin_interface.dart';
import 'plugin_loader.dart';
import 'plugin_context_service.dart';
import 'plugin_package_service.dart';

/// Plugin Manager - 负责插件的生命周期管理
/// 所有具体插件实现已移至 plugins/ 目录
class PluginManager extends ChangeNotifier {
  static PluginManager? _instance;
  static PluginManager get instance => _instance ??= PluginManager._();
  
  PluginManager._();
  
  final Map<String, Plugin> _plugins = {};
  final Map<String, MarkoraPlugin> _loadedPlugins = {};
  final Map<String, PluginConfig> _configs = {};
  final List<PluginEventListener> _listeners = [];
  final PluginLoader _loader = PluginLoader();
  
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
  
  /// Scan plugins directory
  Future<void> _scanPlugins() async {
    try {
      final pluginsDir = await _getPluginsDirectory();
      debugPrint('Plugins directory path: ${pluginsDir.path}');
      
      if (!await pluginsDir.exists()) {
        debugPrint('Plugin directory does not exist, creating: ${pluginsDir.path}');
        await pluginsDir.create(recursive: true);
      }
      
      debugPrint('Start scanning plugin directory: ${pluginsDir.path}');
      var pluginCount = 0;
      
      if (await pluginsDir.exists()) {
        await for (final entity in pluginsDir.list()) {
          debugPrint('Found entity: ${entity.path}, type: ${entity.runtimeType}');
          if (entity is Directory) {
            pluginCount++;
            await _scanPluginDirectory(entity);
          }
        }
      }
      
      debugPrint('Scanning completed, found $pluginCount plugin directories');
      debugPrint('Currently loaded plugins: ${_plugins.keys.toList()}');
    } catch (e) {
      debugPrint('Failed to scan plugin directory: $e');
    }
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

  /// Scan single plugin directory
  Future<void> _scanPluginDirectory(Directory pluginDir) async {
    try {
      final manifestFile = File('${pluginDir.path}/manifest.json');
      if (!await manifestFile.exists()) {
        debugPrint('Plugin manifest not found: ${manifestFile.path}');
        return;
      }
      
      debugPrint('Loading plugin metadata: ${manifestFile.path}');
      // 修复：传递 File 对象而不是 String
      final metadata = await _loader.loadPluginMetadata(manifestFile);
      if (metadata == null) {
        debugPrint('Plugin metadata loading failed: ${manifestFile.path}');
        return;
      }
      
      debugPrint('Successfully loaded plugin metadata: ${metadata.id} - ${metadata.name}');

      // Check for platform support
      if (!_checkPlatformSupport(metadata)) {
        debugPrint('Plugin ${metadata.id} does not support the current platform');
        _plugins[metadata.id] = Plugin(
          metadata: metadata,
          status: PluginStatus.unsupported,
          installPath: pluginDir.path,
          installDate: _plugins[metadata.id]?.installDate ?? DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        return;
      }
      
      final existingPlugin = _plugins[metadata.id];
      // 首先检查是否有待应用的状态，然后检查现有插件状态，最后默认为installed
      final status = _pendingPluginStates[metadata.id] ?? existingPlugin?.status ?? PluginStatus.installed;
      
      // 如果使用了待应用的状态，从待应用列表中移除
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
      );
      
      _plugins[metadata.id] = plugin;
      debugPrint('Plugin registered: ${metadata.id} with status: ${status.name}');
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
      
      // 修复：传递 Plugin 对象而不是 PluginMetadata 和 String
      final pluginInstance = await _loader.loadPlugin(plugin);
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
      
      // 移除不存在的 updateToolbarRegistration 调用
      
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
      
      // Remove the problematic updateToolbarRegistration call
      // The toolbar will be updated automatically through the plugin system
      
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
  
  /// Install plugin from .mxt package
  Future<bool> installPlugin(String mxtPath) async {
    try {
      final pluginFile = File(mxtPath);
      if (!await pluginFile.exists()) {
        debugPrint('Plugin package file not found: $mxtPath');
        return false;
      }
      
      // Get the installation directory for plugins
      final pluginsDir = await _getPluginsDirectory();
      
      // Install the package
      final installPath = await PluginPackageService.installPackage(
        packagePath: mxtPath,
        installDir: pluginsDir.path,
      );
      
      // Scan the newly installed plugin directory
      await _scanPluginDirectory(Directory(installPath));
      
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
  
  /// Uninstall plugin (removes from registry but keeps files)
  Future<bool> uninstallPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    try {
      // Disable plugin first
      await disablePlugin(pluginId);
      
      // Only remove from registry, keep physical files
      // This prevents accidental deletion of plugin source code
      _plugins.remove(pluginId);
      _configs.remove(pluginId);
      
      // Save updated configuration
      await _savePluginConfigs();
      
      notifyListeners();
      debugPrint('Plugin $pluginId uninstalled from registry (files preserved)');
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
    try {
      // Check if it's Web environment
      if (kIsWeb) {
        debugPrint('Web environment: Using relative path');
        final pluginsDir = Directory('plugins');
        debugPrint('Plugin directory path: plugins');
        return pluginsDir;
      }
      
      // For non-web platforms, use Directory.current safely
      try {
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
        debugPrint('Failed to access current directory: $e');
        // Fallback to relative path
        return Directory('plugins');
      }
    } catch (e) {
      debugPrint('Failed to get plugin directory: $e');
      // Fallback to current directory
      return Directory('plugins');
    }
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