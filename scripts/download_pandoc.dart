#!/usr/bin/env dart
// Pandoc 可执行文件下载脚本
// 使用方法: dart run scripts/download_pandoc.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

const String pandocVersion = '3.1.9';
const String githubApiUrl = 'https://api.github.com/repos/jgm/pandoc/releases/tags/$pandocVersion';

// 平台配置
const Map<String, PlatformConfig> platformConfigs = {
  'windows': PlatformConfig(
    assetPattern: 'pandoc-$pandocVersion-windows-x86_64.zip',
    executableName: 'pandoc.exe',
    extractPath: 'pandoc-$pandocVersion/pandoc.exe',
  ),
  'macos': PlatformConfig(
    assetPattern: 'pandoc-$pandocVersion-macOS.zip',
    executableName: 'pandoc',
    extractPath: 'pandoc-$pandocVersion/bin/pandoc',
  ),
  'linux': PlatformConfig(
    assetPattern: 'pandoc-$pandocVersion-linux-amd64.tar.gz',
    executableName: 'pandoc',
    extractPath: 'pandoc-$pandocVersion/bin/pandoc',
  ),
};

class PlatformConfig {
  final String assetPattern;
  final String executableName;
  final String extractPath;
  
  const PlatformConfig({
    required this.assetPattern,
    required this.executableName,
    required this.extractPath,
  });
}

void main(List<String> args) async {
  print('🚀 Pandoc 可执行文件下载器 v$pandocVersion');
  print('=' * 50);
  
  // 解析命令行参数
  final platforms = args.isEmpty ? platformConfigs.keys.toList() : args;
  
  for (final platform in platforms) {
    if (!platformConfigs.containsKey(platform)) {
      print('❌ 不支持的平台: $platform');
      print('支持的平台: ${platformConfigs.keys.join(', ')}');
      continue;
    }
    
    try {
      await downloadPandocForPlatform(platform);
    } catch (e) {
      print('❌ 下载 $platform 版本失败: $e');
    }
  }
  
  print('\n✅ 下载完成！');
  print('现在可以运行应用，插件将自动使用内置的Pandoc。');
}

Future<void> downloadPandocForPlatform(String platform) async {
  final config = platformConfigs[platform]!;
  
  print('\n📦 正在下载 $platform 版本...');
  
  // 获取发布信息
  final releaseInfo = await getReleaseInfo();
  final asset = findAssetByPattern(releaseInfo, config.assetPattern);
  
  if (asset == null) {
    throw Exception('找不到匹配的资源文件: ${config.assetPattern}');
  }
  
  print('📥 下载: ${asset['name']}');
  print('大小: ${formatBytes(asset['size'])}');
  
  // 下载文件
  final downloadUrl = asset['browser_download_url'];
  final response = await http.get(Uri.parse(downloadUrl));
  
  if (response.statusCode != 200) {
    throw Exception('下载失败: HTTP ${response.statusCode}');
  }
  
  // 创建临时文件
  final tempDir = Directory.systemTemp.createTempSync('pandoc_download_');
  final tempFile = File(path.join(tempDir.path, asset['name']));
  await tempFile.writeAsBytes(response.bodyBytes);
  
  print('📂 解压文件...');
  
  // 解压并提取可执行文件
  final executable = await extractExecutable(tempFile, config, platform);
  
  if (executable == null) {
    throw Exception('找不到可执行文件: ${config.extractPath}');
  }
  
  // 复制到目标位置
  final targetDir = Directory('assets/pandoc/$platform');
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }
  
  final targetFile = File(path.join(targetDir.path, config.executableName));
  await targetFile.writeAsBytes(executable);
  
  // 设置执行权限（Unix系统）
  if (platform != 'windows') {
    await Process.run('chmod', ['+x', targetFile.path]);
  }
  
  // 清理临时文件
  await tempDir.delete(recursive: true);
  
  print('✅ $platform 版本下载完成: ${targetFile.path}');
  
  // 验证文件
  if (await verifyExecutable(targetFile.path)) {
    print('✅ 文件验证成功');
  } else {
    print('⚠️  文件验证失败，但已下载');
  }
}

Future<Map<String, dynamic>> getReleaseInfo() async {
  print('🔍 获取发布信息...');
  
  final response = await http.get(
    Uri.parse(githubApiUrl),
    headers: {'Accept': 'application/vnd.github.v3+json'},
  );
  
  if (response.statusCode != 200) {
    throw Exception('获取发布信息失败: HTTP ${response.statusCode}');
  }
  
  return json.decode(response.body);
}

Map<String, dynamic>? findAssetByPattern(Map<String, dynamic> releaseInfo, String pattern) {
  final assets = releaseInfo['assets'] as List;
  
  for (final asset in assets) {
    if (asset['name'].contains(pattern.replaceAll('pandoc-$pandocVersion-', ''))) {
      return asset;
    }
  }
  
  return null;
}

Future<List<int>?> extractExecutable(File archiveFile, PlatformConfig config, String platform) async {
  final bytes = await archiveFile.readAsBytes();
  
  if (archiveFile.path.endsWith('.zip')) {
    final archive = ZipDecoder().decodeBytes(bytes);
    
    for (final file in archive) {
      if (file.name.endsWith(config.extractPath.split('/').last) && 
          file.name.contains('pandoc')) {
        return file.content as List<int>;
      }
    }
  } else if (archiveFile.path.endsWith('.tar.gz')) {
    final archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    
    for (final file in archive) {
      if (file.name.endsWith(config.extractPath.split('/').last) && 
          file.name.contains('pandoc')) {
        return file.content as List<int>;
      }
    }
  }
  
  return null;
}

Future<bool> verifyExecutable(String executablePath) async {
  try {
    final result = await Process.run(executablePath, ['--version']);
    return result.exitCode == 0 && result.stdout.toString().contains('pandoc');
  } catch (e) {
    return false;
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
} 