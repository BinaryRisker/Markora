import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// 简单的MXT打包脚本
Future<void> main() async {
  print('Markora Pandoc Plugin MXT Packager');
  print('==================================');
  
  try {
    // 设置路径
    final currentDir = Directory.current.path;
    final pluginDir = path.join(currentDir, 'plugins', 'pandoc_plugin');
    final outputDir = path.join(currentDir, 'packages');
    
    // 创建输出目录
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }
    
    final outputPath = path.join(outputDir, 'pandoc_plugin.mxt');
    
    print('插件目录: $pluginDir');
    print('输出路径: $outputPath');
    
    // 验证插件目录
    final pluginDirectory = Directory(pluginDir);
    if (!await pluginDirectory.exists()) {
      print('错误: 插件目录不存在: $pluginDir');
      return;
    }
    
    // 读取plugin.json
    final pluginJsonFile = File(path.join(pluginDir, 'plugin.json'));
    if (!await pluginJsonFile.exists()) {
      print('错误: plugin.json文件不存在');
      return;
    }
    
    final pluginJsonContent = await pluginJsonFile.readAsString();
    final pluginJson = jsonDecode(pluginJsonContent) as Map<String, dynamic>;
    
    print('正在收集插件文件...');
    
    // 收集所有文件
    final files = <String>[];
    final assets = <String>[];
    
    await for (final entity in pluginDirectory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: pluginDir);
        files.add(relativePath);
        
        // 识别资源文件
        final extension = path.extension(relativePath).toLowerCase();
        if (['.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.exe', '.html'].contains(extension)) {
          assets.add(relativePath);
        }
      }
    }
    
    print('找到 ${files.length} 个文件，其中 ${assets.length} 个资源文件');
    
    // 创建清单
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
      'packageVersion': '1.0.0',
      'assets': assets,
      'permissions': pluginJson['permissions'] ?? [],
      'platforms': pluginJson['platforms'] ?? ['desktop'],
      'category': pluginJson['category'] ?? 'converter',
    };
    
    print('正在创建MXT包...');
    
    // 创建压缩包
    final archive = Archive();
    
    // 添加清单文件
    final manifestJson = jsonEncode(manifest);
    final manifestBytes = utf8.encode(manifestJson);
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    
    // 添加所有插件文件
    for (final file in files) {
      final filePath = path.join(pluginDir, file);
      final fileEntity = File(filePath);
      if (await fileEntity.exists()) {
        print('添加文件: $file');
        final fileBytes = await fileEntity.readAsBytes();
        archive.addFile(ArchiveFile(file, fileBytes.length, fileBytes));
      }
    }
    
    // 编码压缩包
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    
    if (zipBytes == null) {
      print('错误: 无法创建压缩包');
      return;
    }
    
    // 写入文件
    final packageFile = File(outputPath);
    await packageFile.writeAsBytes(zipBytes);
    
    // 计算文件信息
    final packageSize = await packageFile.length();
    final checksum = sha256.convert(zipBytes).toString();
    
    print('');
    print('🎉 MXT包创建成功!');
    print('文件路径: $outputPath');
    print('文件大小: ${(packageSize / 1024 / 1024).toStringAsFixed(2)} MB');
    print('校验和: $checksum');
    print('');
    print('插件信息:');
    print('- ID: ${pluginJson['id']}');
    print('- 名称: ${pluginJson['name']}');
    print('- 版本: ${pluginJson['version']}');
    print('- 作者: ${pluginJson['author']}');
    print('- 文件数量: ${files.length}');
    print('- 资源文件: ${assets.length}');
    print('');
    print('现在可以通过Markora插件管理器安装此插件包了！');
    
  } catch (e, stackTrace) {
    print('错误: $e');
    print('堆栈跟踪: $stackTrace');
  }
} 