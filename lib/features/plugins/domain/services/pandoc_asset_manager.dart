import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Pandoc资源管理器
/// 负责管理内置的Pandoc可执行文件，包括提取、权限设置等
class PandocAssetManager {
  static const String _assetBasePath = 'assets/pandoc';
  static const String _pandocVersion = '3.1.9'; // 内置Pandoc版本
  
  // 单例模式
  static final PandocAssetManager _instance = PandocAssetManager._internal();
  factory PandocAssetManager() => _instance;
  PandocAssetManager._internal();
  
  String? _pandocPath;
  bool _isInitialized = false;
  
  /// 获取当前平台的Pandoc可执行文件路径
  String? get pandocPath => _pandocPath;
  
  /// 是否已初始化
  bool get isInitialized => _isInitialized;
  
  /// 内置Pandoc版本
  String get version => _pandocVersion;
  
  /// 初始化Pandoc资源
  Future<bool> initialize() async {
    if (_isInitialized) {
      return _pandocPath != null;
    }
    
    try {
      debugPrint('PandocAssetManager: Initializing Pandoc resources...');
      
      // 获取当前平台信息
      final platformInfo = _getPlatformInfo();
      if (platformInfo == null) {
        debugPrint('PandocAssetManager: Unsupported platform');
        return false;
      }
      
      // 检查是否已有提取的Pandoc文件
      final extractedPath = await _getExtractedPandocPath(platformInfo);
      if (await _isValidPandocExecutable(extractedPath)) {
        _pandocPath = extractedPath;
        _isInitialized = true;
        debugPrint('PandocAssetManager: Using existing Pandoc at $extractedPath');
        return true;
      }
      
      // 提取Pandoc可执行文件
      final success = await _extractPandocAsset(platformInfo);
      if (success) {
        _pandocPath = extractedPath;
        _isInitialized = true;
        debugPrint('PandocAssetManager: Pandoc extracted successfully to $extractedPath');
        return true;
      }
      
      debugPrint('PandocAssetManager: Failed to extract Pandoc asset');
      return false;
      
    } catch (e) {
      debugPrint('PandocAssetManager: Error initializing Pandoc resources: $e');
      return false;
    }
  }
  
  /// 检查内置Pandoc是否可用
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return _pandocPath != null && await _isValidPandocExecutable(_pandocPath!);
  }
  
  /// 获取Pandoc版本信息
  Future<String?> getPandocVersion() async {
    if (!await isAvailable()) {
      return null;
    }
    
    try {
      final result = await Process.run(_pandocPath!, ['--version']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final versionMatch = RegExp(r'pandoc (\d+\.\d+(?:\.\d+)?)').firstMatch(output);
        return versionMatch?.group(1);
      }
    } catch (e) {
      debugPrint('PandocAssetManager: Error getting Pandoc version: $e');
    }
    
    return null;
  }
  
  /// 获取平台信息
  _PlatformInfo? _getPlatformInfo() {
    if (Platform.isWindows) {
      return _PlatformInfo('windows', 'pandoc.exe');
    } else if (Platform.isMacOS) {
      return _PlatformInfo('macos', 'pandoc');
    } else if (Platform.isLinux) {
      return _PlatformInfo('linux', 'pandoc');
    }
    return null;
  }
  
  /// 获取提取后的Pandoc路径
  Future<String> _getExtractedPandocPath(_PlatformInfo platformInfo) async {
    final appDir = await getApplicationSupportDirectory();
    final pandocDir = Directory(path.join(appDir.path, 'pandoc', _pandocVersion));
    
    if (!await pandocDir.exists()) {
      await pandocDir.create(recursive: true);
    }
    
    return path.join(pandocDir.path, platformInfo.executable);
  }
  
  /// 提取Pandoc资源文件
  Future<bool> _extractPandocAsset(_PlatformInfo platformInfo) async {
    try {
      final assetPath = '$_assetBasePath/${platformInfo.platform}/${platformInfo.executable}';
      debugPrint('PandocAssetManager: Extracting asset from $assetPath');
      
      // 检查资源是否存在
      try {
        final assetData = await rootBundle.load(assetPath);
        final extractedPath = await _getExtractedPandocPath(platformInfo);
        
        // 写入文件
        final file = File(extractedPath);
        await file.writeAsBytes(assetData.buffer.asUint8List());
        
        // 设置执行权限（Unix系统）
        if (!Platform.isWindows) {
          await Process.run('chmod', ['+x', extractedPath]);
        }
        
        debugPrint('PandocAssetManager: Asset extracted to $extractedPath');
        return true;
        
      } catch (e) {
        debugPrint('PandocAssetManager: Asset not found or extraction failed: $e');
        return false;
      }
      
    } catch (e) {
      debugPrint('PandocAssetManager: Error extracting Pandoc asset: $e');
      return false;
    }
  }
  
  /// 验证Pandoc可执行文件是否有效
  Future<bool> _isValidPandocExecutable(String executablePath) async {
    try {
      final file = File(executablePath);
      if (!await file.exists()) {
        return false;
      }
      
      // 尝试运行 --version 命令
      final result = await Process.run(executablePath, ['--version']);
      return result.exitCode == 0 && result.stdout.toString().contains('pandoc');
      
    } catch (e) {
      debugPrint('PandocAssetManager: Error validating Pandoc executable: $e');
      return false;
    }
  }
  
  /// 清理提取的资源
  Future<void> cleanup() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final pandocDir = Directory(path.join(appDir.path, 'pandoc'));
      
      if (await pandocDir.exists()) {
        await pandocDir.delete(recursive: true);
        debugPrint('PandocAssetManager: Cleaned up Pandoc resources');
      }
      
      _pandocPath = null;
      _isInitialized = false;
      
    } catch (e) {
      debugPrint('PandocAssetManager: Error cleaning up resources: $e');
    }
  }
  
  /// 重新初始化资源
  Future<bool> reinitialize() async {
    await cleanup();
    return await initialize();
  }
}

/// 平台信息
class _PlatformInfo {
  final String platform;
  final String executable;
  
  const _PlatformInfo(this.platform, this.executable);
} 