import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// MXT包创建工具
class MxtPackageCreator {
  static Future<String> createPluginPackage(String pluginPath) async {
    final pluginDir = Directory(pluginPath);
    if (!await pluginDir.exists()) {
      throw Exception('Plugin directory not found: $pluginPath');
    }

    final pluginName = path.basename(pluginPath);
    print('开始创建 $pluginName 插件 MXT 包...');

    // 获取项目根目录
    final currentDir = Directory.current.path;
    final outputDir = path.join(currentDir, 'packages');
    
    // 创建输出目录
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }
    
    // 读取插件配置
    final pluginJsonFile = File(path.join(pluginDir.path, 'plugin.json'));
    final pluginJsonContent = await pluginJsonFile.readAsString();
    final pluginJson = jsonDecode(pluginJsonContent) as Map<String, dynamic>;
    final version = pluginJson['version'];
 
    final outputPath = path.join(outputDir, '${pluginName}_v$version.mxt');
    
    // 收集文件
    final files = <String>[];
    final assets = <String>[];
    
    await for (final entity in pluginDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: pluginDir.path);
        files.add(relativePath);
        
        // 标识资源文件
        final extension = path.extension(relativePath).toLowerCase();
        if (['.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.exe', '.html'].contains(extension)) {
          assets.add(relativePath);
        }
      }
    }
    
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
      'config': pluginJson['config'] ?? {},
      'entryPoint': pluginJson['entryPoint'] ?? 'lib/main.dart',
    };
    
    // 创建压缩包
    final archive = Archive();
    
    // 添加清单
    final manifestJson = jsonEncode(manifest);
    final manifestBytes = utf8.encode(manifestJson);
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    
    // 添加所有文件
    for (final file in files) {
      final filePath = path.join(pluginDir.path, file);
      final fileEntity = File(filePath);
      if (await fileEntity.exists()) {
        final fileBytes = await fileEntity.readAsBytes();
        archive.addFile(ArchiveFile(file, fileBytes.length, fileBytes));
      }
    }
    
    // 生成压缩包
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive)!;
    
    // 写入文件
    final packageFile = File(outputPath);
    await packageFile.writeAsBytes(zipBytes);
    
    // 计算信息
    final packageSize = await packageFile.length();
    final checksum = sha256.convert(zipBytes).toString();
    
    print('✅ MXT包创建成功！');
    print('📁 文件路径: $outputPath');
    print('📊 文件大小: ${(packageSize / 1024 / 1024).toStringAsFixed(2)} MB');
    print('🔒 校验和: ${checksum.substring(0, 16)}...');
    print('📦 包含文件: ${files.length} 个');
    print('🎨 资源文件: ${assets.length} 个');
    
    return outputPath;
  }
  
  /// 验证MXT包
  static Future<Map<String, dynamic>> validatePackage(String packagePath) async {
    final packageFile = File(packagePath);
    final packageBytes = await packageFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(packageBytes);
    
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw Exception('清单文件不存在');
    }
    
    final manifestJson = utf8.decode(manifestFile.content as List<int>);
    return jsonDecode(manifestJson) as Map<String, dynamic>;
  }
}

/// 主函数 - 可以直接运行
/// 支持单个插件打包或批量打包所有插件
void main(List<String> args) async {
  if (args.isEmpty) {
    // 批量打包模式
    await _batchPackagePlugins();
  } else {
    // 单个插件打包模式
    final pluginPath = args[0];
    await _packageSinglePlugin(pluginPath);
  }
}

Future<void> _packageSinglePlugin(String pluginPath) async {
  try {
    final packagePath = await MxtPackageCreator.createPluginPackage(pluginPath);

    print('\n📋 验证包内容...');
    final manifest = await MxtPackageCreator.validatePackage(packagePath);
    final metadata = manifest['metadata'] as Map<String, dynamic>;

    print('✅ 验证成功！');
    print('🏷️  插件ID: ${metadata['id']}');
    print('📝 插件名称: ${metadata['name']}');
    print('🔢 版本: ${metadata['version']}');
    print('👤 作者: ${metadata['author']}');
    print('📄 描述: ${metadata['description']}');

    print('\n🎉 插件 MXT 包已准备就绪！');
  } catch (e, stackTrace) {
    print('❌ 错误: $e');
    print('堆栈跟踪: $stackTrace');
    exit(1);
  }
}

Future<void> _batchPackagePlugins() async {
  try {
    print('🚀 开始批量打包所有插件...');
    final pluginsDir = Directory(path.join(Directory.current.path, 'plugins'));
    if (!await pluginsDir.exists()) {
      print('❌ 错误: 插件目录 \'plugins\' 不存在。');
      return;
    }

    final pluginDirs = <String>[];
    await for (final entity in pluginsDir.list()) {
      if (entity is Directory) {
        final pluginJsonFile = File(path.join(entity.path, 'plugin.json'));
        if (await pluginJsonFile.exists()) {
          pluginDirs.add(entity.path);
        }
      }
    }

    if (pluginDirs.isEmpty) {
      print('🟡 未找到有效的插件。');
      return;
    }

    print('🔍 找到 ${pluginDirs.length} 个插件准备打包。');

    for (final pluginDir in pluginDirs) {
      final pluginName = path.basename(pluginDir);
      print('\n打包插件: $pluginName');
      await _packageSinglePlugin(pluginDir);
    }

    print('\n✅ 所有插件打包完成！');
  } catch (e, stackTrace) {
    print('❌ 批量打包过程中发生错误: $e');
    print('堆栈跟踪: $stackTrace');
    exit(1);
  }
}