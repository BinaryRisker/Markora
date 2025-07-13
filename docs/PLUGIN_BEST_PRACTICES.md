# Markora 插件开发最佳实践

## 概述

本文档为 Markora 插件开发者提供全面的最佳实践指南，涵盖代码质量、性能优化、安全性、用户体验和维护性等方面。

## 代码组织与架构

### 1. 项目结构标准化

#### 推荐的目录结构

```
my_plugin/
├── lib/
│   ├── main.dart              # 插件入口点
│   ├── core/
│   │   ├── plugin_base.dart   # 插件基类
│   │   └── constants.dart     # 常量定义
│   ├── models/
│   │   ├── config.dart        # 配置模型
│   │   └── data_models.dart   # 数据模型
│   ├── services/
│   │   ├── plugin_service.dart # 核心业务逻辑
│   │   └── api_service.dart   # API 服务
│   ├── widgets/
│   │   ├── plugin_widget.dart # UI 组件
│   │   └── dialogs/           # 对话框组件
│   └── utils/
│       ├── helpers.dart       # 工具函数
│       └── validators.dart    # 验证器
├── assets/
│   ├── icons/                 # 图标资源
│   ├── images/                # 图片资源
│   ├── templates/             # 模板文件
│   └── localization/          # 本地化文件
├── test/
│   ├── unit/                  # 单元测试
│   ├── integration/           # 集成测试
│   └── mocks/                 # 模拟对象
├── docs/
│   ├── README.md              # 插件说明
│   ├── API.md                 # API 文档
│   └── CHANGELOG.md           # 变更日志
├── plugin.json                # 插件元数据
├── pubspec.yaml               # Dart 依赖
└── .gitignore                 # Git 忽略文件
```

#### 文件命名约定

```dart
// 使用 snake_case 命名文件
my_plugin_service.dart
user_config_model.dart
markdown_renderer.dart

// 使用 PascalCase 命名类
class MyPluginService {}
class UserConfigModel {}
class MarkdownRenderer {}

// 使用 camelCase 命名变量和方法
String pluginName = 'My Plugin';
void initializePlugin() {}
```

### 2. 插件基类设计

#### 标准插件基类

```dart
// lib/core/plugin_base.dart
abstract class MarkoraPluginBase {
  /// 插件唯一标识符
  String get pluginId;
  
  /// 插件显示名称
  String get pluginName;
  
  /// 插件版本
  String get version;
  
  /// 插件初始化
  Future<void> initialize();
  
  /// 插件清理
  Future<void> dispose();
  
  /// 处理错误
  void handleError(Object error, StackTrace stackTrace) {
    debugPrint('[$pluginName] Error: $error');
    debugPrint('Stack trace: $stackTrace');
  }
  
  /// 记录日志
  void log(String message, {LogLevel level = LogLevel.info}) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] [$pluginName] [${level.name}] $message');
  }
}

enum LogLevel { debug, info, warning, error }
```

#### 具体插件实现

```dart
// lib/main.dart
import 'core/plugin_base.dart';

class MyAwesomePlugin extends MarkoraPluginBase {
  static const String _pluginId = 'my_awesome_plugin';
  static const String _pluginName = 'My Awesome Plugin';
  static const String _version = '1.0.0';
  
  @override
  String get pluginId => _pluginId;
  
  @override
  String get pluginName => _pluginName;
  
  @override
  String get version => _version;
  
  @override
  Future<void> initialize() async {
    try {
      log('Initializing plugin...');
      await _loadConfiguration();
      await _setupServices();
      log('Plugin initialized successfully');
    } catch (e, stackTrace) {
      handleError(e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Future<void> dispose() async {
    try {
      log('Disposing plugin...');
      await _cleanupServices();
      log('Plugin disposed successfully');
    } catch (e, stackTrace) {
      handleError(e, stackTrace);
    }
  }
  
  Future<void> _loadConfiguration() async {
    // 加载配置逻辑
  }
  
  Future<void> _setupServices() async {
    // 设置服务逻辑
  }
  
  Future<void> _cleanupServices() async {
    // 清理服务逻辑
  }
}
```

## 配置管理最佳实践

### 1. 强类型配置模型

```dart
// lib/models/config.dart
class PluginConfig {
  final String outputFormat;
  final bool enableCache;
  final int maxFileSize;
  final Duration timeout;
  final List<String> allowedExtensions;
  
  const PluginConfig({
    required this.outputFormat,
    required this.enableCache,
    required this.maxFileSize,
    required this.timeout,
    required this.allowedExtensions,
  });
  
  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      outputFormat: json['outputFormat'] as String? ?? 'html',
      enableCache: json['enableCache'] as bool? ?? true,
      maxFileSize: json['maxFileSize'] as int? ?? 1048576,
      timeout: Duration(
        milliseconds: json['timeoutMs'] as int? ?? 30000,
      ),
      allowedExtensions: List<String>.from(
        json['allowedExtensions'] as List? ?? ['md', 'txt'],
      ),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'outputFormat': outputFormat,
      'enableCache': enableCache,
      'maxFileSize': maxFileSize,
      'timeoutMs': timeout.inMilliseconds,
      'allowedExtensions': allowedExtensions,
    };
  }
  
  PluginConfig copyWith({
    String? outputFormat,
    bool? enableCache,
    int? maxFileSize,
    Duration? timeout,
    List<String>? allowedExtensions,
  }) {
    return PluginConfig(
      outputFormat: outputFormat ?? this.outputFormat,
      enableCache: enableCache ?? this.enableCache,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      timeout: timeout ?? this.timeout,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
    );
  }
}
```

### 2. 配置验证

```dart
// lib/utils/validators.dart
class ConfigValidator {
  static ValidationResult validateConfig(PluginConfig config) {
    final errors = <String>[];
    
    // 验证输出格式
    const validFormats = ['html', 'pdf', 'docx', 'txt'];
    if (!validFormats.contains(config.outputFormat)) {
      errors.add('Invalid output format: ${config.outputFormat}');
    }
    
    // 验证文件大小
    if (config.maxFileSize <= 0 || config.maxFileSize > 100 * 1024 * 1024) {
      errors.add('Max file size must be between 1 byte and 100MB');
    }
    
    // 验证超时时间
    if (config.timeout.inMilliseconds < 1000 || 
        config.timeout.inMilliseconds > 300000) {
      errors.add('Timeout must be between 1 second and 5 minutes');
    }
    
    // 验证文件扩展名
    if (config.allowedExtensions.isEmpty) {
      errors.add('At least one file extension must be allowed');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
}
```

## 错误处理与日志记录

### 1. 分层错误处理

```dart
// lib/core/exceptions.dart
abstract class PluginException implements Exception {
  final String message;
  final String pluginId;
  final Object? originalError;
  final StackTrace? stackTrace;
  
  const PluginException(
    this.message,
    this.pluginId, {
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() {
    return '$runtimeType: $message (Plugin: $pluginId)';
  }
}

class PluginInitializationException extends PluginException {
  const PluginInitializationException(
    String message,
    String pluginId, {
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, pluginId, originalError: originalError, stackTrace: stackTrace);
}

class PluginConfigurationException extends PluginException {
  const PluginConfigurationException(
    String message,
    String pluginId, {
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, pluginId, originalError: originalError, stackTrace: stackTrace);
}

class PluginProcessingException extends PluginException {
  const PluginProcessingException(
    String message,
    String pluginId, {
    Object? originalError,
    StackTrace? stackTrace,
  }) : super(message, pluginId, originalError: originalError, stackTrace: stackTrace);
}
```

### 2. 统一错误处理器

```dart
// lib/core/error_handler.dart
class PluginErrorHandler {
  static void handleError(
    Object error,
    StackTrace stackTrace,
    String pluginId, {
    String? context,
    bool showToUser = false,
  }) {
    // 记录错误
    _logError(error, stackTrace, pluginId, context);
    
    // 发送错误报告（如果启用）
    _sendErrorReport(error, stackTrace, pluginId, context);
    
    // 显示用户友好的错误信息
    if (showToUser) {
      _showUserError(error, pluginId);
    }
  }
  
  static void _logError(
    Object error,
    StackTrace stackTrace,
    String pluginId,
    String? context,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final contextInfo = context != null ? ' [$context]' : '';
    
    debugPrint('[$timestamp] [ERROR] [$pluginId]$contextInfo $error');
    debugPrint('Stack trace: $stackTrace');
  }
  
  static Future<void> _sendErrorReport(
    Object error,
    StackTrace stackTrace,
    String pluginId,
    String? context,
  ) async {
    // 实现错误报告逻辑
    // 注意：需要用户同意才能发送
  }
  
  static void _showUserError(Object error, String pluginId) {
    String userMessage;
    
    if (error is PluginException) {
      userMessage = error.message;
    } else {
      userMessage = '插件 $pluginId 发生了未知错误，请联系开发者。';
    }
    
    // 显示错误对话框或通知
    // 具体实现取决于 UI 框架
  }
}
```

## 性能优化

### 1. 异步操作最佳实践

```dart
// lib/services/plugin_service.dart
class PluginService {
  final Map<String, dynamic> _cache = {};
  final Duration _cacheTimeout = const Duration(minutes: 5);
  
  /// 异步处理内容，支持取消
  Future<String> processContent(
    String content, {
    CancellationToken? cancellationToken,
  }) async {
    // 检查缓存
    final cacheKey = _generateCacheKey(content);
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey];
      if (cached['timestamp'].add(_cacheTimeout).isAfter(DateTime.now())) {
        return cached['result'] as String;
      }
    }
    
    // 检查取消令牌
    cancellationToken?.throwIfCancelled();
    
    try {
      // 分块处理大内容
      final result = await _processInChunks(
        content,
        cancellationToken: cancellationToken,
      );
      
      // 缓存结果
      _cache[cacheKey] = {
        'result': result,
        'timestamp': DateTime.now(),
      };
      
      return result;
    } catch (e) {
      // 清理失败的缓存项
      _cache.remove(cacheKey);
      rethrow;
    }
  }
  
  Future<String> _processInChunks(
    String content, {
    CancellationToken? cancellationToken,
    int chunkSize = 1024,
  }) async {
    final buffer = StringBuffer();
    
    for (int i = 0; i < content.length; i += chunkSize) {
      // 定期检查取消令牌
      cancellationToken?.throwIfCancelled();
      
      final end = math.min(i + chunkSize, content.length);
      final chunk = content.substring(i, end);
      
      // 处理块
      final processedChunk = await _processChunk(chunk);
      buffer.write(processedChunk);
      
      // 让出控制权，避免阻塞 UI
      if (i % (chunkSize * 10) == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    
    return buffer.toString();
  }
  
  Future<String> _processChunk(String chunk) async {
    // 实际的块处理逻辑
    return chunk.toUpperCase(); // 示例
  }
  
  String _generateCacheKey(String content) {
    return content.hashCode.toString();
  }
  
  void clearCache() {
    _cache.clear();
  }
}

// 取消令牌实现
class CancellationToken {
  bool _isCancelled = false;
  
  bool get isCancelled => _isCancelled;
  
  void cancel() {
    _isCancelled = true;
  }
  
  void throwIfCancelled() {
    if (_isCancelled) {
      throw OperationCancelledException();
    }
  }
}

class OperationCancelledException implements Exception {
  const OperationCancelledException();
  
  @override
  String toString() => 'Operation was cancelled';
}
```

### 2. 内存管理

```dart
// lib/core/resource_manager.dart
class ResourceManager {
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Timer> _timers = {};
  final List<Completer> _completers = [];
  
  /// 注册需要清理的资源
  void registerSubscription(String key, StreamSubscription subscription) {
    _subscriptions[key]?.cancel();
    _subscriptions[key] = subscription;
  }
  
  void registerTimer(String key, Timer timer) {
    _timers[key]?.cancel();
    _timers[key] = timer;
  }
  
  void registerCompleter(Completer completer) {
    _completers.add(completer);
  }
  
  /// 清理所有资源
  Future<void> dispose() async {
    // 取消所有订阅
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    
    // 取消所有定时器
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    
    // 完成所有未完成的 Completer
    for (final completer in _completers) {
      if (!completer.isCompleted) {
        completer.completeError(
          const OperationCancelledException(),
        );
      }
    }
    _completers.clear();
  }
}
```

## 安全性最佳实践

### 1. 输入验证与清理

```dart
// lib/utils/security.dart
class SecurityUtils {
  /// 清理用户输入，防止注入攻击
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>'), '')
        .replaceAll(RegExp(r'javascript:'), '')
        .replaceAll(RegExp(r'on\w+\s*='), '')
        .trim();
  }
  
  /// 验证文件路径安全性
  static bool isPathSafe(String path) {
    // 防止路径遍历攻击
    if (path.contains('..') || 
        path.contains('~') ||
        path.startsWith('/') ||
        path.contains('\\')) {
      return false;
    }
    
    // 检查危险文件扩展名
    const dangerousExtensions = ['.exe', '.bat', '.cmd', '.scr', '.com'];
    final extension = path.toLowerCase().split('.').last;
    if (dangerousExtensions.contains('.$extension')) {
      return false;
    }
    
    return true;
  }
  
  /// 验证 URL 安全性
  static bool isUrlSafe(String url) {
    try {
      final uri = Uri.parse(url);
      
      // 只允许 HTTP 和 HTTPS
      if (!['http', 'https'].contains(uri.scheme)) {
        return false;
      }
      
      // 防止访问本地地址
      if (uri.host == 'localhost' || 
          uri.host == '127.0.0.1' ||
          uri.host.startsWith('192.168.') ||
          uri.host.startsWith('10.') ||
          uri.host.startsWith('172.')) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

### 2. 权限检查

```dart
// lib/core/permissions.dart
enum Permission {
  fileSystem,
  network,
  process,
  ui,
}

class PermissionManager {
  final Map<Permission, bool> _grantedPermissions = {};
  
  bool hasPermission(Permission permission) {
    return _grantedPermissions[permission] ?? false;
  }
  
  void requirePermission(Permission permission) {
    if (!hasPermission(permission)) {
      throw PermissionDeniedException(
        'Permission ${permission.name} is required but not granted',
      );
    }
  }
  
  void grantPermission(Permission permission) {
    _grantedPermissions[permission] = true;
  }
  
  void revokePermission(Permission permission) {
    _grantedPermissions[permission] = false;
  }
}

class PermissionDeniedException implements Exception {
  final String message;
  
  const PermissionDeniedException(this.message);
  
  @override
  String toString() => 'PermissionDeniedException: $message';
}
```

## 用户界面最佳实践

### 1. 响应式设计

```dart
// lib/widgets/responsive_plugin_widget.dart
class ResponsivePluginWidget extends StatelessWidget {
  final Widget child;
  
  const ResponsivePluginWidget({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileLayout(context);
        } else if (constraints.maxWidth < 1200) {
          return _buildTabletLayout(context);
        } else {
          return _buildDesktopLayout(context);
        }
      },
    );
  }
  
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context, compact: true),
        Expanded(child: child),
      ],
    );
  }
  
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(context),
        Expanded(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context, {bool compact = false}) {
    // 实现头部组件
    return Container();
  }
  
  Widget _buildSidebar(BuildContext context) {
    // 实现侧边栏组件
    return Container();
  }
}
```

### 2. 无障碍支持

```dart
// lib/widgets/accessible_plugin_button.dart
class AccessiblePluginButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final IconData? icon;
  
  const AccessiblePluginButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(text),
    );
    
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: onPressed != null,
      child: button,
    );
  }
}
```

## 测试策略

### 1. 单元测试

```dart
// test/unit/plugin_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_plugin/services/plugin_service.dart';

class MockDependency extends Mock implements SomeDependency {}

void main() {
  group('PluginService', () {
    late PluginService service;
    late MockDependency mockDependency;
    
    setUp(() {
      mockDependency = MockDependency();
      service = PluginService(dependency: mockDependency);
    });
    
    tearDown(() {
      service.dispose();
    });
    
    group('processContent', () {
      test('should process content correctly', () async {
        // Arrange
        const input = 'test content';
        const expectedOutput = 'PROCESSED: test content';
        when(mockDependency.process(any))
            .thenAnswer((_) async => expectedOutput);
        
        // Act
        final result = await service.processContent(input);
        
        // Assert
        expect(result, equals(expectedOutput));
        verify(mockDependency.process(input)).called(1);
      });
      
      test('should handle empty input', () async {
        // Arrange
        const input = '';
        
        // Act & Assert
        expect(
          () => service.processContent(input),
          throwsA(isA<ArgumentError>()),
        );
      });
      
      test('should cache results', () async {
        // Arrange
        const input = 'test content';
        const output = 'processed';
        when(mockDependency.process(any))
            .thenAnswer((_) async => output);
        
        // Act
        await service.processContent(input);
        await service.processContent(input); // Second call
        
        // Assert
        verify(mockDependency.process(input)).called(1); // Only called once
      });
    });
  });
}
```

### 2. 集成测试

```dart
// test/integration/plugin_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_plugin/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Plugin Integration Tests', () {
    testWidgets('should initialize and process content', (tester) async {
      // Arrange
      final plugin = MyAwesomePlugin();
      
      // Act
      await plugin.initialize();
      final result = await plugin.processContent('test input');
      
      // Assert
      expect(result, isNotEmpty);
      expect(result, contains('test input'));
      
      // Cleanup
      await plugin.dispose();
    });
    
    testWidgets('should handle configuration changes', (tester) async {
      // Test configuration management
    });
    
    testWidgets('should handle errors gracefully', (tester) async {
      // Test error handling
    });
  });
}
```

## 文档与维护

### 1. API 文档

```dart
/// Markora 插件的核心服务类
/// 
/// 提供内容处理、配置管理和缓存功能。
/// 
/// 使用示例：
/// ```dart
/// final service = PluginService();
/// await service.initialize();
/// final result = await service.processContent('# Hello World');
/// print(result); // 输出处理后的内容
/// ```
class PluginService {
  /// 处理输入内容并返回处理结果
  /// 
  /// [content] 要处理的原始内容
  /// [options] 可选的处理选项
  /// 
  /// 返回处理后的内容字符串
  /// 
  /// 抛出 [ArgumentError] 如果内容为空
  /// 抛出 [PluginProcessingException] 如果处理失败
  Future<String> processContent(
    String content, {
    ProcessingOptions? options,
  }) async {
    // 实现
  }
}
```

### 2. 变更日志

```markdown
# Changelog

## [1.2.0] - 2024-01-15

### Added
- 新增批量处理功能
- 支持自定义输出格式
- 添加配置验证机制

### Changed
- 改进错误处理逻辑
- 优化缓存性能
- 更新依赖版本

### Fixed
- 修复内存泄漏问题
- 解决配置加载错误
- 修正文档中的示例代码

### Deprecated
- `oldMethod()` 将在 v2.0 中移除，请使用 `newMethod()`

## [1.1.0] - 2024-01-01

### Added
- 初始版本发布
- 基础内容处理功能
- 配置管理系统
```

## 发布与分发

### 1. 版本管理

```yaml
# pubspec.yaml
name: my_awesome_plugin
version: 1.2.0+3  # 版本号+构建号
description: A comprehensive plugin for Markora

environment:
  sdk: '>=2.17.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  # 锁定依赖版本以确保稳定性
  http: ^0.13.5
  path: ^1.8.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.3.2
  build_runner: ^2.3.3
```

### 2. 发布检查清单

```bash
#!/bin/bash
# scripts/pre_release_check.sh

echo "🔍 Running pre-release checks..."

# 运行测试
echo "📋 Running tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed!"
    exit 1
fi

# 检查代码格式
echo "🎨 Checking code format..."
flutter format --set-exit-if-changed .
if [ $? -ne 0 ]; then
    echo "❌ Code format check failed!"
    exit 1
fi

# 静态分析
echo "🔍 Running static analysis..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ Static analysis failed!"
    exit 1
fi

# 验证插件元数据
echo "📄 Validating plugin metadata..."
if [ ! -f "plugin.json" ]; then
    echo "❌ plugin.json not found!"
    exit 1
fi

# 检查文档
echo "📚 Checking documentation..."
if [ ! -f "README.md" ]; then
    echo "❌ README.md not found!"
    exit 1
fi

echo "✅ All checks passed! Ready for release."
```

## 性能监控

### 1. 性能指标收集

```dart
// lib/core/performance_monitor.dart
class PerformanceMonitor {
  static final Map<String, List<Duration>> _metrics = {};
  
  static Future<T> measure<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await function();
      return result;
    } finally {
      stopwatch.stop();
      _recordMetric(operation, stopwatch.elapsed);
    }
  }
  
  static void _recordMetric(String operation, Duration duration) {
    _metrics.putIfAbsent(operation, () => []).add(duration);
    
    // 保持最近 100 次记录
    final list = _metrics[operation]!;
    if (list.length > 100) {
      list.removeAt(0);
    }
  }
  
  static Map<String, PerformanceStats> getStats() {
    return _metrics.map((operation, durations) {
      return MapEntry(operation, PerformanceStats.fromDurations(durations));
    });
  }
}

class PerformanceStats {
  final Duration average;
  final Duration min;
  final Duration max;
  final int count;
  
  const PerformanceStats({
    required this.average,
    required this.min,
    required this.max,
    required this.count,
  });
  
  factory PerformanceStats.fromDurations(List<Duration> durations) {
    if (durations.isEmpty) {
      return const PerformanceStats(
        average: Duration.zero,
        min: Duration.zero,
        max: Duration.zero,
        count: 0,
      );
    }
    
    final totalMicroseconds = durations
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);
    
    return PerformanceStats(
      average: Duration(microseconds: totalMicroseconds ~/ durations.length),
      min: durations.reduce((a, b) => a < b ? a : b),
      max: durations.reduce((a, b) => a > b ? a : b),
      count: durations.length,
    );
  }
}
```

## 总结

遵循这些最佳实践将帮助您创建高质量、可维护、安全的 Markora 插件：

1. **代码组织**: 使用清晰的项目结构和命名约定
2. **配置管理**: 实现强类型配置和验证
3. **错误处理**: 建立分层的错误处理机制
4. **性能优化**: 使用异步操作、缓存和资源管理
5. **安全性**: 验证输入、检查权限、防止攻击
6. **用户界面**: 支持响应式设计和无障碍访问
7. **测试**: 编写全面的单元测试和集成测试
8. **文档**: 提供清晰的 API 文档和使用指南
9. **发布**: 建立规范的版本管理和发布流程
10. **监控**: 收集性能指标和错误报告

通过遵循这些实践，您的插件将更加稳定、高效，并为 Markora 生态系统做出有价值的贡献。