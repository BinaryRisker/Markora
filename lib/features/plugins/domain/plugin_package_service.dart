import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../types/plugin.dart';

/// Plugin package service for handling .mxt files
class PluginPackageService {
  static const String packageVersion = '1.0.0';
  static const String manifestFileName = 'manifest.json';
  static const String pluginFileName = 'plugin.json';
  
  /// Create a plugin package (.mxt file) from a plugin directory
  static Future<String> createPackage({
    required String pluginDir,
    required String outputPath,
  }) async {
    try {
      debugPrint('Creating plugin package from: $pluginDir');
      
      // Validate plugin directory
      final pluginDirectory = Directory(pluginDir);
      if (!await pluginDirectory.exists()) {
        throw Exception('Plugin directory does not exist: $pluginDir');
      }
      
      // Read plugin metadata
      final pluginJsonFile = File(path.join(pluginDir, pluginFileName));
      if (!await pluginJsonFile.exists()) {
        throw Exception('Plugin.json not found in: $pluginDir');
      }
      
      final pluginJsonContent = await pluginJsonFile.readAsString();
      final pluginJson = jsonDecode(pluginJsonContent) as Map<String, dynamic>;
      
      // Create plugin metadata
      final metadata = PluginMetadata(
        id: pluginJson['id'] as String,
        name: pluginJson['name'] as String,
        version: pluginJson['version'] as String,
        description: pluginJson['description'] as String,
        author: pluginJson['author'] as String,
        homepage: pluginJson['homepage'] as String?,
        repository: pluginJson['repository'] as String?,
        license: pluginJson['license'] as String? ?? 'MIT',
        type: _parsePluginType(pluginJson['type'] as String),
        tags: (pluginJson['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        minVersion: pluginJson['minVersion'] as String? ?? '1.0.0',
        maxVersion: pluginJson['maxVersion'] as String?,
        dependencies: (pluginJson['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      );
      
      // Collect all files in the plugin directory
      final files = <String>[];
      final assets = <String>[];
      
      await for (final entity in pluginDirectory.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: pluginDir);
          files.add(relativePath);
          
          // Identify asset files
          final extension = path.extension(relativePath).toLowerCase();
          if (['.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico'].contains(extension)) {
            assets.add(relativePath);
          }
        }
      }
      
      // Create package manifest
      final manifest = PluginPackageManifest(
        metadata: metadata,
        files: files,
        packageVersion: packageVersion,
        assets: assets,
        permissions: _getRequiredPermissions(pluginDir),
      );
      
      // Create archive
      final archive = Archive();
      
      // Add manifest file
      final manifestJson = jsonEncode(manifest.toJson());
      final manifestBytes = utf8.encode(manifestJson);
      archive.addFile(ArchiveFile(manifestFileName, manifestBytes.length, manifestBytes));
      
      // Add all plugin files
      for (final file in files) {
        final filePath = path.join(pluginDir, file);
        final fileBytes = await File(filePath).readAsBytes();
        archive.addFile(ArchiveFile(file, fileBytes.length, fileBytes));
      }
      
      // Encode archive
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      
      if (zipBytes == null) {
        throw Exception('Failed to create archive');
      }
      
      // Write package file
      final packageFile = File(outputPath);
      await packageFile.writeAsBytes(zipBytes);
      
      debugPrint('Plugin package created: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('Failed to create plugin package: $e');
      rethrow;
    }
  }
  
  /// Extract and install a plugin package (.mxt file)
  static Future<String> installPackage({
    required String packagePath,
    required String installDir,
  }) async {
    try {
      debugPrint('Installing plugin package: $packagePath');
      
      // Read package file
      final packageFile = File(packagePath);
      if (!await packageFile.exists()) {
        throw Exception('Package file does not exist: $packagePath');
      }
      
      final packageBytes = await packageFile.readAsBytes();
      
      // Decode archive
      final archive = ZipDecoder().decodeBytes(packageBytes);
      
      // Extract and read manifest to get the plugin ID
      final manifestFile = archive.findFile(manifestFileName);
      if (manifestFile == null) {
        throw Exception('Manifest not found in package ($manifestFileName)');
      }
      
      final manifestJson = utf8.decode(manifestFile.content as List<int>);
      final manifestData = jsonDecode(manifestJson) as Map<String, dynamic>;
      
      final pluginId = manifestData['id'] as String?;
      if (pluginId == null || pluginId.isEmpty) {
        throw Exception('Plugin ID not found or is empty in manifest');
      }

      // Optional: Validate package version compatibility
      final packageVersion = manifestData['packageVersion'] as String?;
      if (packageVersion != null && !_isPackageVersionCompatible(packageVersion)) {
        throw Exception('Incompatible package version: $packageVersion');
      }
      
      // Create plugin installation directory in installed_plugins
      final pluginInstallDir = path.join(installDir, pluginId);
      final pluginDirectory = Directory(pluginInstallDir);
      
      if (await pluginDirectory.exists()) {
        // Remove existing installation (no need to check for dev plugins here)
        await pluginDirectory.delete(recursive: true);
      }
      
      await pluginDirectory.create(recursive: true);
      
      // Extract all files
      for (final file in archive) {
        final filePath = path.join(pluginInstallDir, file.name);
        final fileDir = Directory(path.dirname(filePath));
        
        if (!await fileDir.exists()) {
          await fileDir.create(recursive: true);
        }
        
        final outputFile = File(filePath);
        await outputFile.writeAsBytes(file.content as List<int>);
      }
      
      debugPrint('Plugin package installed to: $pluginInstallDir');
      return pluginInstallDir;
    } catch (e) {
      debugPrint('Failed to install plugin package: $e');
      rethrow;
    }
  }
  
  /// Validate a plugin package without installing
  static Future<PluginPackageManifest> validatePackage(String packagePath) async {
    try {
      final packageFile = File(packagePath);
      if (!await packageFile.exists()) {
        throw Exception('Package file does not exist: $packagePath');
      }
      
      final packageBytes = await packageFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(packageBytes);
      
      final manifestFile = archive.findFile(manifestFileName);
      if (manifestFile == null) {
        throw Exception('Manifest not found in package');
      }
      
      final manifestJson = utf8.decode(manifestFile.content as List<int>);
      final manifest = PluginPackageManifest.fromJson(jsonDecode(manifestJson));
      
      // Validate package structure
      final pluginJsonFile = archive.findFile(pluginFileName);
      if (pluginJsonFile == null) {
        throw Exception('plugin.json not found in package');
      }
      
      return manifest;
    } catch (e) {
      debugPrint('Failed to validate plugin package: $e');
      rethrow;
    }
  }
  
  /// Calculate package checksum
  static Future<String> calculateChecksum(String packagePath) async {
    final file = File(packagePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Get package size in bytes
  static Future<int> getPackageSize(String packagePath) async {
    final file = File(packagePath);
    return await file.length();
  }
  
  /// Parse plugin type from string
  static PluginType _parsePluginType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'syntax':
        return PluginType.syntax;
      case 'renderer':
        return PluginType.renderer;
      case 'theme':
        return PluginType.theme;
      case 'export':
        return PluginType.export;
      case 'exporter':
        return PluginType.exporter;
      case 'tool':
        return PluginType.tool;
      case 'integration':
        return PluginType.integration;
      default:
        return PluginType.tool;
    }
  }
  
  /// Check if package version is compatible
  static bool _isPackageVersionCompatible(String version) {
    // Accept 1.x.x for legacy and 2.x.x for new format
    return version.startsWith('1.') || version.startsWith('2.');
  }
  
  /// Get required permissions for a plugin
  static List<String> _getRequiredPermissions(String pluginDir) {
    final permissions = <String>[];
    
    // Basic permissions that all plugins need
    permissions.add('ui.dialog');
    permissions.add('editor.access');
    
    // Check for file system access
    final libDir = Directory(path.join(pluginDir, 'lib'));
    if (libDir.existsSync()) {
      // Scan for file operations in the code (simplified check)
      permissions.add('file.read');
      permissions.add('file.write');
    }
    
    return permissions;
  }
}