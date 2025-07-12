#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// Plugin package service for handling .mxt files - standalone version
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
      print('Creating plugin package from: $pluginDir');
      
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
      
      // Collect all files in the plugin directory
      final files = <String>[];
      final assets = <String>[];
      
      await for (final entity in pluginDirectory.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: pluginDir);
          files.add(relativePath);
          
          // Identify asset files
          final extension = path.extension(relativePath).toLowerCase();
          if (['.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.exe'].contains(extension)) {
            assets.add(relativePath);
          }
        }
      }
      
      // Create package manifest
      final manifest = {
        'metadata': {
          'id': pluginJson['id'],
          'name': pluginJson['name'],
          'version': pluginJson['version'],
          'description': pluginJson['description'],
          'author': pluginJson['author'],
          'homepage': pluginJson['homepage'],
          'repository': pluginJson['repository'],
          'license': pluginJson['license'] ?? 'MIT',
          'type': pluginJson['type'],
          'tags': pluginJson['tags'] ?? [],
          'minVersion': pluginJson['minVersion'] ?? '1.0.0',
          'maxVersion': pluginJson['maxVersion'],
          'dependencies': pluginJson['dependencies'] ?? [],
        },
        'files': files,
        'packageVersion': packageVersion,
        'assets': assets,
        'permissions': pluginJson['permissions'] ?? [],
      };
      
      // Create archive
      final archive = Archive();
      
      // Add manifest file
      final manifestJson = jsonEncode(manifest);
      final manifestBytes = utf8.encode(manifestJson);
      archive.addFile(ArchiveFile(manifestFileName, manifestBytes.length, manifestBytes));
      
      // Add all plugin files
      for (final file in files) {
        final filePath = path.join(pluginDir, file);
        final fileEntity = File(filePath);
        if (await fileEntity.exists()) {
          final fileBytes = await fileEntity.readAsBytes();
          archive.addFile(ArchiveFile(file, fileBytes.length, fileBytes));
        }
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
      
      print('Plugin package created: $outputPath');
      return outputPath;
    } catch (e) {
      print('Failed to create plugin package: $e');
      rethrow;
    }
  }
  
  /// Calculate package size
  static Future<int> getPackageSize(String packagePath) async {
    final file = File(packagePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
  
  /// Calculate package checksum
  static Future<String> calculateChecksum(String packagePath) async {
    final file = File(packagePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    }
    return '';
  }
  
  /// Validate a plugin package without installing
  static Future<Map<String, dynamic>> validatePackage(String packagePath) async {
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
      final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      
      return manifest;
    } catch (e) {
      print('Failed to validate plugin package: $e');
      rethrow;
    }
  }
}

/// Script to package the Pandoc plugin into .mxt format
Future<void> main(List<String> args) async {
  try {
    print('Markora Plugin Packager - Pandoc Plugin');
    print('=========================================');
    
    // Get the current directory
    final currentDir = Directory.current.path;
    final pluginDir = path.join(currentDir, 'plugins', 'pandoc_plugin');
    final outputDir = path.join(currentDir, 'packages');
    
    // Ensure output directory exists
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }
    
    final outputPath = path.join(outputDir, 'pandoc_plugin.mxt');
    
    print('Plugin directory: $pluginDir');
    print('Output path: $outputPath');
    
    // Validate plugin directory
    final pluginDirectory = Directory(pluginDir);
    if (!await pluginDirectory.exists()) {
      print('Error: Plugin directory does not exist: $pluginDir');
      exit(1);
    }
    
    // Check for required files
    final pluginJsonFile = File(path.join(pluginDir, 'plugin.json'));
    if (!await pluginJsonFile.exists()) {
      print('Error: plugin.json not found in plugin directory');
      exit(1);
    }
    
    final mainDartFile = File(path.join(pluginDir, 'lib', 'main.dart'));
    if (!await mainDartFile.exists()) {
      print('Error: lib/main.dart not found in plugin directory');
      exit(1);
    }
    
    print('Creating plugin package...');
    
    // Create the package
    final createdPackagePath = await PluginPackageService.createPackage(
      pluginDir: pluginDir,
      outputPath: outputPath,
    );
    
    // Calculate package info
    final packageSize = await PluginPackageService.getPackageSize(createdPackagePath);
    final checksum = await PluginPackageService.calculateChecksum(createdPackagePath);
    
    print('Package created successfully!');
    print('File: $createdPackagePath');
    print('Size: ${(packageSize / 1024 / 1024).toStringAsFixed(2)} MB');
    print('Checksum: $checksum');
    
    // Validate the package
    print('\nValidating package...');
    final manifest = await PluginPackageService.validatePackage(createdPackagePath);
    
    print('Package validation successful!');
    final metadata = manifest['metadata'] as Map<String, dynamic>;
    print('Plugin ID: ${metadata['id']}');
    print('Plugin Name: ${metadata['name']}');
    print('Version: ${metadata['version']}');
    print('Author: ${metadata['author']}');
    print('Files: ${(manifest['files'] as List).length}');
    print('Package Version: ${manifest['packageVersion']}');
    
    print('\nPackaging complete! You can now install this plugin through the Markora plugin manager.');
    
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
} 