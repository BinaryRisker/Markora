import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:archive/archive.dart';

/// Represents the metadata of a plugin, parsed from plugin.json.
class PluginMetadata {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final List<String> platforms;
  final String main;
  final String minAppVersion;
  final String type;

  PluginMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.platforms,
    required this.main,
    required this.minAppVersion,
    required this.type,
  });

  factory PluginMetadata.fromJson(Map<String, dynamic> json) {
    return PluginMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      platforms: List<String>.from(json['platforms'] ?? []),
      main: json['main'] as String,
      minAppVersion: json['minAppVersion'] as String? ?? '1.0.0',
      type: json['pluginType'] as String? ?? json['type'] as String? ?? 'tool',
    );
  }
}

/// Manages the lifecycle of all plugins.
class PluginManager extends ChangeNotifier {
  static final PluginManager _instance = PluginManager._internal();
  factory PluginManager() => _instance;

  PluginManager._internal();

  final Map<String, PluginMetadata> _plugins = {};
  bool _isInitialized = false;

  List<PluginMetadata> get plugins => _plugins.values.toList();

  /// Initializes the plugin manager and loads all installed plugins.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadInstalledPlugins();

    _isInitialized = true;
    notifyListeners();
    debugPrint('PluginManager initialized with ${_plugins.length} plugins.');
  }

  /// Gets the root directory where plugins are stored.
  Future<Directory> getPluginsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final pluginsDir = Directory(path.join(appDir.path, 'Markora', 'plugins'));
    if (!await pluginsDir.exists()) {
      await pluginsDir.create(recursive: true);
    }
    return pluginsDir;
  }

  /// Loads all plugins found in the plugins directory.
  Future<void> _loadInstalledPlugins() async {
    final pluginsDir = await getPluginsDirectory();
    final entities = pluginsDir.listSync();

    for (final entity in entities) {
      if (entity is Directory) {
        final manifestFile = File(path.join(entity.path, 'plugin.json'));
        if (await manifestFile.exists()) {
          try {
            final content = await manifestFile.readAsString();
            final json = jsonDecode(content);
            final metadata = PluginMetadata.fromJson(json);
            _plugins[metadata.id] = metadata;
          } catch (e) {
            debugPrint('Failed to load plugin from ${entity.path}: $e');
          }
        }
      }
    }
  }

  /// Installs a plugin from a .mtx file.
  Future<void> installPlugin(String mtxPath) async {
    final mtxFile = File(mtxPath);
    if (!await mtxFile.exists()) {
      throw Exception('MTX file not found: $mtxPath');
    }

    final bytes = await mtxFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find manifest to get plugin ID
    final manifestEntry = archive.findFile('plugin.json');
    if (manifestEntry == null) {
      throw Exception('Invalid MTX package: plugin.json not found.');
    }

    final manifestContent = utf8.decode(manifestEntry.content as List<int>);
    final metadata = PluginMetadata.fromJson(jsonDecode(manifestContent));

    final pluginsDir = await getPluginsDirectory();
    final pluginDir = Directory(path.join(pluginsDir.path, metadata.id));

    if (await pluginDir.exists()) {
      // Check if this is a development plugin directory (has lib/main.dart)
      final devMainFile = File(path.join(pluginDir.path, 'lib', 'main.dart'));
      if (await devMainFile.exists()) {
        throw Exception('Cannot install over development plugin: ${metadata.id}. '
            'Development plugins should not be overwritten by package installation.');
      }
      // Remove existing installation only if it's not a development directory
      await pluginDir.delete(recursive: true);
      debugPrint('Existing plugin ${metadata.id} directory deleted.');
    }
    await pluginDir.create();

    for (final file in archive) {
      final filePath = path.join(pluginDir.path, file.name);
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }

    _plugins[metadata.id] = metadata;
    notifyListeners();
    debugPrint('Plugin ${metadata.name} installed successfully.');
  }

  /// Uninstalls a plugin (removes from registry but keeps files).
  Future<void> uninstallPlugin(String pluginId) async {
    if (!_plugins.containsKey(pluginId)) {
      throw Exception('Plugin not found: $pluginId');
    }

    // Only remove from memory registry, keep physical files
    // This prevents accidental deletion of plugin source code
    _plugins.remove(pluginId);
    notifyListeners();
    debugPrint('Plugin $pluginId uninstalled from registry (files preserved).');
  }
}