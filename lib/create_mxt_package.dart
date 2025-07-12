import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

/// MXT包创建工具
class MxtPackageCreator {
  static Future<String> createPandocPluginPackage() async {
    print('开始创建Pandoc插件MXT包...');
    
    // 获取项目根目录
    final currentDir = Directory.current.path;
    final pluginDir = path.join(currentDir, 'plugins', 'pandoc_plugin');
    final outputDir = path.join(currentDir, 'packages');
    
    // 创建输出目录
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }
    
    final outputPath = path.join(outputDir, 'pandoc_plugin_v1.0.0.mxt');
    
    // 读取插件配置
    final pluginJsonFile = File(path.join(pluginDir, 'plugin.json'));
    final pluginJsonContent = await pluginJsonFile.readAsString();
    final pluginJson = jsonDecode(pluginJsonContent) as Map<String, dynamic>;
    
    // 收集文件
    final files = <String>[];
    final assets = <String>[];
    
    final pluginDirectory = Directory(pluginDir);
    await for (final entity in pluginDirectory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: pluginDir);
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
      final filePath = path.join(pluginDir, file);
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
void main() async {
  try {
    final packagePath = await MxtPackageCreator.createPandocPluginPackage();
    
    print('\n📋 验证包内容...');
    final manifest = await MxtPackageCreator.validatePackage(packagePath);
    final metadata = manifest['metadata'] as Map<String, dynamic>;
    
    print('✅ 验证成功！');
    print('🏷️  插件ID: ${metadata['id']}');
    print('📝 插件名称: ${metadata['name']}');
    print('🔢 版本: ${metadata['version']}');
    print('👤 作者: ${metadata['author']}');
    print('📄 描述: ${metadata['description']}');
    print('🏷️  标签: ${metadata['tags']}');
    print('⚙️  权限: ${manifest['permissions']}');
    print('🖥️  平台: ${manifest['platforms']}');
    
    print('\n🎉 Pandoc插件MXT包已准备就绪！');
    print('现在可以通过Markora插件管理器安装此插件了。');
    
  } catch (e, stackTrace) {
    print('❌ 错误: $e');
    print('堆栈跟踪: $stackTrace');
  }
} 