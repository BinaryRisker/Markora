import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/services/command_service.dart';
import '../../../types/plugin.dart';
import 'plugin_context_service.dart';
import 'plugin_package_service.dart';
import 'plugin_interface.dart';
import 'icon_registry.dart';

/// Plugin Manager - 负责插件的生命周期管理 (v2 Architecture)
class PluginManager extends ChangeNotifier {
  static PluginManager? _instance;
  static PluginManager get instance => _instance ??= PluginManager._();
  
  PluginManager._();
  
  final Map<String, Plugin> _plugins = {};
  final Map<String, _GenericPluginProxy> _loadedPlugins = {};
  final List<PluginEventListener> _listeners = [];
  final CommandService _commandService = CommandService.instance;
  
  PluginContext? _context;
  
  /// All plugins list
  List<Plugin> get plugins => _plugins.values.toList();
  
  /// Enabled plugins list
  List<Plugin> get enabledPlugins => _plugins.values
      .where((plugin) => plugin.status == PluginStatus.enabled)
      .toList();
  
  /// Initialize plugin manager
  Future<void> initialize(PluginContext context) async {
    _context = context;

    // Connect the toolbar registry changes to the PluginManager's change notifier
    _context!.toolbarRegistry.addChangeListener(notifyListeners);

    // The correct order is crucial:
    // 1. Scan to discover all available plugins and load their metadata.
    await _scanPlugins();
    // 2. Load the persisted states (enabled/disabled) from storage.
    await _loadPluginStates();
    // 3. Activate plugins that are marked as enabled.
    await _activateEnabledPlugins();
  }

  // --- Listener and Event Methods ---
  
  /// Add plugin event listener
  void addPluginListener(PluginEventListener listener) => _listeners.add(listener);
  
  /// Remove plugin event listener
  void removePluginListener(PluginEventListener listener) => _listeners.remove(listener);
  
  /// Notify plugin lifecycle event to all listeners
  void _notifyLifecycleEvent(String pluginId, PluginLifecycleEvent event, {String? error}) {
    for (final listener in _listeners) {
      listener.onPluginLifecycleEvent(pluginId, event, error: error);
    }
  }
  
  /// Notify plugin status change to all listeners
  void _notifyStatusChanged(String pluginId, PluginStatus oldStatus, PluginStatus newStatus) {
    for (final listener in _listeners) {
      listener.onPluginStatusChanged(pluginId, oldStatus, newStatus);
    }
    notifyListeners();
  }

  // --- Core Plugin Lifecycle ---

  /// Scan all plugin directories for available plugins
  Future<void> _scanPlugins() async {
    // DO NOT CLEAR plugins here. We need to merge new findings with existing state.
    final devDir = await getDevPluginsDirectory();
    final installedDir = await getInstalledPluginsDirectory();
    await _scanPluginDirectory(devDir, isDevelopment: true);
    await _scanPluginDirectory(installedDir, isDevelopment: false);
    debugPrint('Plugin scanning completed. Found ${_plugins.length} plugins.');
    notifyListeners();
  }
  
  /// Scan a single directory for potential plugins
  Future<void> _scanPluginDirectory(Directory pluginsDir, {required bool isDevelopment}) async {
    if (!await pluginsDir.exists()) return;
    await for (final entity in pluginsDir.list()) {
      if (entity is Directory) {
        final manifestFile = File(path.join(entity.path, 'plugin.json'));
        if (await manifestFile.exists()) {
          final metadata = await _loadPluginMetadata(manifestFile);
          if (metadata != null) {
            // If plugin already exists, just update metadata, otherwise create new with 'installed' status.
            final existingPlugin = _plugins[metadata.id];
            if (existingPlugin != null) {
               _plugins[metadata.id] = existingPlugin.copyWith(metadata: metadata);
            } else {
               _plugins[metadata.id] = Plugin(
                  metadata: metadata,
                  status: PluginStatus.installed, // Default status
                  installPath: entity.path,
                  installDate: DateTime.now(),
                  lastUpdated: DateTime.now(),
                  isDevelopment: isDevelopment,
                );
            }
          }
        }
      }
    }
  }

  /// Load plugin metadata from manifest file
  Future<PluginMetadata?> _loadPluginMetadata(File manifestFile) async {
    try {
      final content = await manifestFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return PluginMetadata.fromJson(json);
    } catch (e) {
      debugPrint('Failed to load plugin metadata from ${manifestFile.path}: $e');
      return null;
    }
  }
  
  /// Activate all plugins that are marked as 'enabled'
  Future<void> _activateEnabledPlugins() async {
    for (final plugin in _plugins.values) {
      if (plugin.status == PluginStatus.enabled) {
        await _activatePlugin(plugin);
      }
    }
  }

  /// Activates a plugin by parsing its contributions and registering them
  Future<void> _activatePlugin(Plugin plugin) async {
    final metadata = plugin.metadata;
    if (_loadedPlugins.containsKey(metadata.id)) return; // Already active

    debugPrint('Activating plugin: ${metadata.id}');
    _notifyLifecycleEvent(metadata.id, PluginLifecycleEvent.loading);
    
    // Register contributions including icons
    _registerContributions(plugin);
    
    _loadedPlugins[metadata.id] = _GenericPluginProxy(metadata, plugin.installPath ?? '');
    _updatePluginStatus(metadata.id, PluginStatus.enabled);
    _notifyLifecycleEvent(metadata.id, PluginLifecycleEvent.loaded);
  }

  /// Deactivates a plugin by unregistering all its contributions
  Future<void> _deactivatePlugin(Plugin plugin) async {
    final metadata = plugin.metadata;
    if (!_loadedPlugins.containsKey(metadata.id)) return;

    debugPrint('Deactivating plugin: ${metadata.id}');
    _notifyLifecycleEvent(metadata.id, PluginLifecycleEvent.unloading);
    
    // Unregister contributions including icons
    _unregisterContributions(plugin);
    
    _loadedPlugins.remove(metadata.id);
    _updatePluginStatus(metadata.id, PluginStatus.disabled);
    _notifyLifecycleEvent(metadata.id, PluginLifecycleEvent.unloaded);
  }

  // --- Contribution and Command Handling ---

  /// Register plugin contributions (commands, toolbar items, icons)
  void _registerContributions(Plugin plugin) {
    final contributes = plugin.metadata.contributes;
    if (contributes == null) return;

    // Register Commands
    for (final command in contributes.commands) {
      _commandService.registerCommand(
          command.command, _createCommandHandler(plugin, command));
    }

    // Register Toolbar Items
    if (_context != null) {
      for (final item in contributes.toolbar) {
        _context!.toolbarRegistry.registerAction(
          PluginAction(
              id: item.command,
              title: item.title,
              description: item.description ?? '',
              icon: _createIconWidget(item.icon, item.phosphorIcon),
              group: item.group),
          () => _commandService.executeCommand(item.command),
        );
      }
    }
    
    // Register plugin icons
    _registerPluginIcons(plugin);
  }

  /// Create icon widget for plugin toolbar items
  Widget _createIconWidget(String? iconString, String? phosphorIconName) {
    // Use phosphorIcon from plugin config if available
    if (phosphorIconName != null && phosphorIconName.isNotEmpty) {
      final iconData = IconRegistry().getIcon(phosphorIconName);
      if (iconData != null) {
        return Icon(
          iconData,
          size: 20,
          color: Colors.white,
        );
      }
    }

    // Fallback to iconString if phosphorIcon is not available
    if (iconString != null && iconString.isNotEmpty) {
      final iconData = IconRegistry().getIcon(iconString);
      if (iconData != null) {
        return Icon(
          iconData,
          size: 20,
          color: Colors.white,
        );
      }
    }

    // Final fallback to default icon
    debugPrint('Could not resolve icon: phosphorIcon=$phosphorIconName, icon=$iconString');
    return Icon(
      IconRegistry().getIconWithFallback('plugs'),
      size: 20,
      color: Colors.white,
    );
  }

  /// Unregister plugin contributions
  void _unregisterContributions(Plugin plugin) {
    final contributes = plugin.metadata.contributes;
    if (contributes == null) return;
    
    // Unregister commands
    for (final command in contributes.commands) {
      _commandService.unregisterCommand(command.command);
    }
    
    // Unregister toolbar items
    if (_context != null) {
      for (final item in contributes.toolbar) {
        _context!.toolbarRegistry.unregisterAction(item.command);
      }
    }
    
    // Unregister plugin icons
    _unregisterPluginIcons(plugin);
  }
  
  /// Create command handler for plugin commands
  CommandHandler _createCommandHandler(Plugin plugin, CommandContribution command) {
    final entryPoint = plugin.metadata.entryPoint;
    if (entryPoint == null) {
      return (args) async => debugPrint('No entryPoint defined for ${plugin.metadata.id}');
    }
    switch (entryPoint.type) {
      case 'executable':
        return (args) => _executeProcessCommand(plugin, entryPoint, command, args);
      case 'internal':
        return (args) => _executeInternalCommand(plugin, command, args);
      default:
        return (args) async => debugPrint('Unknown entryPoint type "${entryPoint.type}"');
    }
  }

  /// Execute process-based plugin command
  Future<void> _executeProcessCommand(Plugin plugin, EntryPoint entryPoint, CommandContribution command, Map<String, dynamic>? args) async {
    // Platform-specific executable path logic
    debugPrint('Executing process command: ${command.command} for plugin: ${plugin.metadata.id}');
  }

  /// Execute internal plugin command
  Future<void> _executeInternalCommand(Plugin plugin, CommandContribution command, Map<String, dynamic>? args) async {
    switch (command.command) {
      case 'mermaid.insertBlock':
        const template = '```mermaid\ngraph TD\nA-->B\n```';
        _context?.editorController.insertText(template);
        break;
      default:
        debugPrint('Unknown internal command: ${command.command}');
    }
  }

  // --- Public Methods for UI Interaction ---

  /// Enable a plugin
  Future<void> enablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin != null && plugin.status != PluginStatus.enabled) {
      await _activatePlugin(plugin);
      await _savePluginStates();
      notifyListeners(); // Notify UI to rebuild
    }
  }

  /// Disable a plugin
  Future<void> disablePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin != null && plugin.status == PluginStatus.enabled) {
      await _deactivatePlugin(plugin);
      await _savePluginStates();
      notifyListeners(); // Notify UI to rebuild
    }
  }

  /// Install a plugin from .mxt package
  Future<void> installPlugin(String mxtPath) async {
    try {
      final installedPluginsDir = await getInstalledPluginsDirectory();
      final installPath = await PluginPackageService.installPackage(
          packagePath: mxtPath, installDir: installedPluginsDir.path);
      await _scanPlugins(); // Rescan to discover the new plugin
      final pluginId = path.basename(installPath);
      await enablePlugin(pluginId); // Auto-enable and this will notify listeners
    } catch (e) {
      debugPrint('Failed to install plugin: $e');
      // Optionally, show an error message to the user
    }
  }

  /// Uninstall a plugin
  Future<void> uninstallPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return;
    await disablePlugin(pluginId);
    if (!plugin.isDevelopment && plugin.installPath != null) {
      final pluginDir = Directory(plugin.installPath!);
      if (await pluginDir.exists()) {
        await pluginDir.delete(recursive: true);
      }
    }
    _plugins.remove(pluginId);
    await _savePluginStates();
    notifyListeners();
  }

  // --- State Persistence ---

  /// Save plugin states to persistent storage
  Future<void> _savePluginStates() async {
    final box = await Hive.openBox('plugin_states');
    final Map<String, String> statesToSave = {};
    for (final plugin in _plugins.values) {
      statesToSave[plugin.metadata.id] = plugin.status.name;
    }
    await box.putAll(statesToSave);
    debugPrint('Saved plugin states for ${statesToSave.length} plugins.');
  }

  /// Load plugin states from persistent storage
  Future<void> _loadPluginStates() async {
    final box = await Hive.openBox('plugin_states');
    for (final pluginId in _plugins.keys) {
      final statusName = box.get(pluginId) as String?;
      if (statusName != null) {
        final status = PluginStatus.values.firstWhere(
          (e) => e.name == statusName,
          orElse: () => PluginStatus.installed, // Fallback
        );
        _updatePluginStatus(pluginId, status);
      }
    }
    debugPrint('Loaded plugin states.');
    notifyListeners();
  }

  /// Update plugin status
  void _updatePluginStatus(String pluginId, PluginStatus status) {
    final plugin = _plugins[pluginId];
    if (plugin != null && plugin.status != status) {
      final oldStatus = plugin.status;
      _plugins[pluginId] = plugin.copyWith(status: status);
      _notifyStatusChanged(pluginId, oldStatus, status);
    }
  }

  // --- Utility ---
  
  /// Get development plugins directory
  Future<Directory> getDevPluginsDirectory() async {
    final dir = Directory(path.join(Directory.current.path, 'plugins'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
  
  /// Get installed plugins directory
  Future<Directory> getInstalledPluginsDirectory() async {
     final dir = Directory(path.join(Directory.current.path, 'installed_plugins'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Register icons defined by the plugin
  void _registerPluginIcons(Plugin plugin) {
    final contributes = plugin.metadata.contributes;
    if (contributes == null) return;

    final iconRegistry = IconRegistry();
    
    // Register icons from toolbar contributions
    for (final toolbar in contributes.toolbar) {
      if (toolbar.phosphorIcon != null && toolbar.phosphorIcon!.isNotEmpty) {
        final iconData = _resolvePhosphorIconData(toolbar.phosphorIcon!);
        if (iconData != null) {
          iconRegistry.registerIcon('${plugin.metadata.id}.${toolbar.phosphorIcon}', iconData);
        }
      }
    }
  }

  /// Unregister icons defined by the plugin
  void _unregisterPluginIcons(Plugin plugin) {
    final contributes = plugin.metadata.contributes;
    if (contributes == null) return;

    final iconRegistry = IconRegistry();
    
    // Unregister icons from toolbar contributions
    for (final toolbar in contributes.toolbar) {
      if (toolbar.phosphorIcon != null && toolbar.phosphorIcon!.isNotEmpty) {
        iconRegistry.unregisterIcon('${plugin.metadata.id}.${toolbar.phosphorIcon}');
      }
    }
  }

  /// Resolve Phosphor icon data by name
  IconData? _resolvePhosphorIconData(String iconName) {
    // This method can be extended to support more icon resolution strategies
    return IconRegistry().getIcon(iconName);
  }
}

/// Simplified generic proxy for loaded plugins
class _GenericPluginProxy {
  final PluginMetadata metadata;
  final String pluginPath;
  
  _GenericPluginProxy(this.metadata, this.pluginPath);
}