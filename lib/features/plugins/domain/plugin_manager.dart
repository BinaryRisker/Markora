import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../types/plugin.dart';
import 'plugin_interface.dart';
import 'plugin_loader.dart';

/// 插件管理器
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
  
  /// 获取插件上下文
  PluginContext? get context => _context;
  
  /// 所有插件列表
  List<Plugin> get plugins => _plugins.values.toList();
  
  /// 已加载的插件列表
  List<Plugin> get loadedPlugins => _plugins.values
      .where((plugin) => _loadedPlugins.containsKey(plugin.metadata.id))
      .toList();
  
  /// 已启用的插件列表
  List<Plugin> get enabledPlugins => _plugins.values
      .where((plugin) => plugin.status == PluginStatus.enabled)
      .toList();
  
  /// 初始化插件管理器
  Future<void> initialize(PluginContext context) async {
    _context = context;
    await _loadPluginConfigs();
    await _scanPlugins();
    await _loadEnabledPlugins();
  }
  
  /// 添加事件监听器
  void addPluginListener(PluginEventListener listener) {
    _listeners.add(listener);
  }
  
  /// 移除事件监听器
  void removePluginListener(PluginEventListener listener) {
    _listeners.remove(listener);
  }
  
  /// 通知生命周期事件
  void _notifyLifecycleEvent(String pluginId, PluginLifecycleEvent event, {String? error}) {
    for (final listener in _listeners) {
      listener.onPluginLifecycleEvent(pluginId, event, error: error);
    }
  }
  
  /// 通知状态变更事件
  void _notifyStatusChanged(String pluginId, PluginStatus oldStatus, PluginStatus newStatus) {
    for (final listener in _listeners) {
      listener.onPluginStatusChanged(pluginId, oldStatus, newStatus);
    }
    notifyListeners();
  }
  
  /// 扫描插件目录
  Future<void> _scanPlugins() async {
    try {
      final pluginsDir = await _getPluginsDirectory();
      debugPrint('插件目录路径: ${pluginsDir.path}');
      
      if (!await pluginsDir.exists()) {
        debugPrint('插件目录不存在，正在创建: ${pluginsDir.path}');
        await pluginsDir.create(recursive: true);
        return;
      }
      
      debugPrint('开始扫描插件目录: ${pluginsDir.path}');
      var pluginCount = 0;
      
      await for (final entity in pluginsDir.list()) {
        debugPrint('发现实体: ${entity.path}, 类型: ${entity.runtimeType}');
        if (entity is Directory) {
          pluginCount++;
          await _scanPluginDirectory(entity);
        }
      }
      
      debugPrint('扫描完成，发现 $pluginCount 个插件目录');
      debugPrint('当前已加载插件: ${_plugins.keys.toList()}');
    } catch (e) {
      debugPrint('扫描插件目录失败: $e');
    }
  }
  
  /// 扫描单个插件目录
  Future<void> _scanPluginDirectory(Directory pluginDir) async {
    try {
      debugPrint('正在扫描插件目录: ${pluginDir.path}');
      final manifestFile = File(path.join(pluginDir.path, 'plugin.json'));
      debugPrint('查找插件清单文件: ${manifestFile.path}');
      
      if (!await manifestFile.exists()) {
        debugPrint('插件清单文件不存在: ${manifestFile.path}');
        return;
      }
      
      debugPrint('正在加载插件元数据: ${manifestFile.path}');
      final metadata = await _loader.loadPluginMetadata(manifestFile);
      if (metadata == null) {
        debugPrint('插件元数据加载失败: ${manifestFile.path}');
        return;
      }
      
      debugPrint('成功加载插件元数据: ${metadata.id} - ${metadata.name}');
      
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
      debugPrint('插件已添加到管理器: ${metadata.id}');
    } catch (e) {
      debugPrint('扫描插件目录失败 ${pluginDir.path}: $e');
    }
  }
  
  /// 加载已启用的插件
  Future<void> _loadEnabledPlugins() async {
    for (final plugin in _plugins.values) {
      if (plugin.status == PluginStatus.enabled) {
        await loadPlugin(plugin.metadata.id);
      }
    }
  }
  
  /// 加载插件
  Future<bool> loadPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    if (_loadedPlugins.containsKey(pluginId)) {
      return true; // 已经加载
    }
    
    try {
      _notifyLifecycleEvent(pluginId, PluginLifecycleEvent.loading);
      
      final pluginInstance = await _loader.loadPlugin(plugin);
      if (pluginInstance == null) {
        throw Exception('插件加载失败');
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
  
  /// 卸载插件
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
  
  /// 启用插件
  Future<bool> enablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    if (plugin.status == PluginStatus.enabled) return true;
    
    return await loadPlugin(pluginId);
  }
  
  /// 禁用插件
  Future<bool> disablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    if (plugin.status != PluginStatus.enabled) return true;
    
    return await unloadPlugin(pluginId);
  }
  
  /// 安装插件
  Future<bool> installPlugin(String pluginPath) async {
    try {
      final pluginFile = File(pluginPath);
      if (!await pluginFile.exists()) return false;
      
      // TODO: 实现插件安装逻辑（解压、验证、复制等）
      // 这里需要根据插件格式（zip、tar.gz等）进行相应处理
      
      await _scanPlugins();
      return true;
    } catch (e) {
      debugPrint('安装插件失败: $e');
      return false;
    }
  }
  
  /// 卸载插件
  Future<bool> uninstallPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    try {
      // 先禁用插件
      await disablePlugin(pluginId);
      
      // 删除插件文件
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
      debugPrint('卸载插件失败: $e');
      return false;
    }
  }
  
  /// 重新加载插件
  Future<bool> reloadPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    
    try {
      final wasEnabled = plugin.status == PluginStatus.enabled;
      
      // 先卸载插件
      if (wasEnabled) {
        await unloadPlugin(pluginId);
      }
      
      // 重新扫描插件目录
      if (plugin.installPath != null) {
        final pluginDir = Directory(plugin.installPath!);
        if (await pluginDir.exists()) {
          await _scanPluginDirectory(pluginDir);
        }
      }
      
      // 如果之前是启用状态，重新启用
      if (wasEnabled) {
        return await loadPlugin(pluginId);
      }
      
      return true;
    } catch (e) {
      debugPrint('重新加载插件失败: $e');
      return false;
    }
  }
  
  /// 获取插件配置
  PluginConfig? getPluginConfig(String pluginId) {
    return _configs[pluginId];
  }
  
  /// 更新插件配置
  Future<void> updatePluginConfig(String pluginId, Map<String, dynamic> config) async {
    final pluginConfig = PluginConfig(
      pluginId: pluginId,
      config: config,
      isEnabled: _configs[pluginId]?.isEnabled ?? true,
    );
    
    _configs[pluginId] = pluginConfig;
    
    // 通知插件配置变更
    final pluginInstance = _loadedPlugins[pluginId];
    if (pluginInstance != null) {
      pluginInstance.onConfigChanged(config);
    }
    
    for (final listener in _listeners) {
      listener.onPluginConfigChanged(pluginId, config);
    }
    
    await _savePluginConfigs();
  }
  
  /// 获取插件目录
  Future<Directory> _getPluginsDirectory() async {
    // 在Flutter Web中，使用相对路径
    // 在其他平台中，使用应用数据目录
    try {
      debugPrint('当前工作目录: ${Directory.current.path}');
      
      // 尝试使用项目根目录下的plugins文件夹
      final pluginsPath = path.join(Directory.current.path, 'plugins');
      debugPrint('计算的插件目录路径: $pluginsPath');
      
      final pluginsDir = Directory(pluginsPath);
      final exists = await pluginsDir.exists();
      debugPrint('插件目录是否存在: $exists');
      
      // 如果目录不存在，尝试创建
      if (!exists) {
        debugPrint('正在创建插件目录: $pluginsPath');
        await pluginsDir.create(recursive: true);
      }
      
      return pluginsDir;
    } catch (e) {
      debugPrint('获取插件目录失败: $e');
      // 回退到当前目录
      return Directory('plugins');
    }
  }
  
  /// 加载插件配置
  Future<void> _loadPluginConfigs() async {
    // TODO: 从持久化存储加载插件配置
    // 可以使用Hive、SharedPreferences等
  }
  
  /// 保存插件配置
  Future<void> _savePluginConfigs() async {
    // TODO: 保存插件配置到持久化存储
  }
  
  /// 获取插件实例
  MarkoraPlugin? getPluginInstance(String pluginId) {
    return _loadedPlugins[pluginId];
  }
  
  /// 获取插件信息
  Plugin? getPlugin(String pluginId) {
    return _plugins[pluginId];
  }
  
  /// 检查插件依赖
  bool _checkDependencies(PluginMetadata metadata) {
    for (final dependency in metadata.dependencies) {
      final dependencyPlugin = _plugins[dependency];
      if (dependencyPlugin == null || dependencyPlugin.status != PluginStatus.enabled) {
        return false;
      }
    }
    return true;
  }
  
  /// 清理资源
  void dispose() {
    for (final pluginInstance in _loadedPlugins.values) {
      pluginInstance.onUnload().catchError((e) {
        debugPrint('插件卸载失败: $e');
      });
    }
    _loadedPlugins.clear();
    _plugins.clear();
    _configs.clear();
    _listeners.clear();
    super.dispose();
  }
}