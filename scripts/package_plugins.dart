import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

// 简化的插件元数据类（不依赖主应用）
class SimplePluginMetadata {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final List<String> supportedPlatforms;

  SimplePluginMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.supportedPlatforms,
  });

  factory SimplePluginMetadata.fromJson(Map<String, dynamic> json) {
    return SimplePluginMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      supportedPlatforms: List<String>.from(json['supportedPlatforms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      'supportedPlatforms': supportedPlatforms,
    };
  }
}

class PluginPackager {
  static Future<String> createPackage(String pluginDir) async {
    try {
      print('Creating plugin package from: $pluginDir');
      
      final pluginJsonFile = File(path.join(pluginDir, 'plugin.json'));
      if (!pluginJsonFile.existsSync()) {
        throw Exception('plugin.json not found in $pluginDir');
      }

      // 读取插件元数据
      final jsonContent = await pluginJsonFile.readAsString();
      final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;
      final metadata = SimplePluginMetadata.fromJson(jsonData);

      // 创建输出目录
      final outputDir = Directory(path.join('..', 'build', 'packages'));
      if (!outputDir.existsSync()) {
        await outputDir.create(recursive: true);
      }

      // 创建压缩包
      final archive = Archive();
      
      // 添加插件文件到压缩包
      await _addDirectoryToArchive(archive, pluginDir, '');
      
      // 生成压缩包数据
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('Failed to create zip data');
      }

      // 计算文件哈希
      final hash = sha256.convert(zipData).toString();

      // 创建包清单
      final manifest = {
        'metadata': metadata.toJson(),
        'packageInfo': {
          'size': zipData.length,
          'hash': hash,
          'createdAt': DateTime.now().toIso8601String(),
        },
      };

      // 保存文件
      final outputPath = path.join(outputDir.path, '${metadata.id}.mxt');
      final outputFile = File(outputPath);
      
      // 写入清单（JSON 头部）
      final manifestJson = jsonEncode(manifest);
      final manifestBytes = utf8.encode(manifestJson);
      final manifestLength = manifestBytes.length;
      
      // 创建最终文件：4字节长度 + JSON清单 + ZIP数据
      final finalData = <int>[];
      
      // 添加清单长度（4字节，大端序）
      finalData.addAll([
        (manifestLength >> 24) & 0xFF,
        (manifestLength >> 16) & 0xFF,
        (manifestLength >> 8) & 0xFF,
        manifestLength & 0xFF,
      ]);
      
      // 添加清单数据
      finalData.addAll(manifestBytes);
      
      // 添加ZIP数据
      finalData.addAll(zipData);
      
      await outputFile.writeAsBytes(finalData);

      print('Plugin package created: $outputPath');
      return outputPath;
    } catch (e) {
      print('Failed to create plugin package: $e');
      rethrow;
    }
  }

  static Future<void> _addDirectoryToArchive(Archive archive, String dirPath, String archivePath) async {
    final dir = Directory(dirPath);
    
    await for (final entity in dir.list(recursive: false)) {
      final entityName = path.basename(entity.path);
      final entityArchivePath = archivePath.isEmpty ? entityName : '$archivePath/$entityName';
      
      if (entity is File) {
        final fileData = await entity.readAsBytes();
        final archiveFile = ArchiveFile(entityArchivePath, fileData.length, fileData);
        archive.addFile(archiveFile);
      } else if (entity is Directory) {
        // 递归添加子目录
        await _addDirectoryToArchive(archive, entity.path, entityArchivePath);
      }
    }
  }
}

Future<void> main() async {
  try {
    print('Starting plugin packaging...');
    
    // 获取插件目录
    final pluginsDir = Directory(path.join('..', 'plugins'));
    if (!pluginsDir.existsSync()) {
      print('Plugins directory not found: ${pluginsDir.path}');
      return;
    }

    final pluginDirs = <String>[];
    await for (final entity in pluginsDir.list()) {
      if (entity is Directory) {
        final pluginJsonFile = File(path.join(entity.path, 'plugin.json'));
        if (pluginJsonFile.existsSync()) {
          pluginDirs.add(entity.path);
        }
      }
    }

    if (pluginDirs.isEmpty) {
      print('No valid plugins found');
      return;
    }

    print('Found ${pluginDirs.length} plugins to package');

    // 打包每个插件
    for (final pluginDir in pluginDirs) {
      final pluginName = path.basename(pluginDir);
      print('\nPackaging plugin: $pluginName');
      
      try {
        final packagePath = await PluginPackager.createPackage(pluginDir);
        print('✓ Successfully packaged: $packagePath');
      } catch (e) {
        print('✗ Failed to package $pluginName: $e');
      }
    }

    print('\nPlugin packaging completed!');
  } catch (e) {
    print('Error during packaging: $e');
    exit(1);
  }
} 