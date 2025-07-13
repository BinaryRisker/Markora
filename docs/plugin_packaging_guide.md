# Markora 插件打包与开发指南

## 概述

本指南详细说明了如何为 Markora 开发、打包和分发插件。Markora 使用 `.mxt` (Markora eXTension) 格式来分发插件，这是一个基于 ZIP 的压缩包格式。

## 插件包格式 (.mxt)

### 格式规范

`.mxt` 文件本质上是一个 ZIP 压缩包，包含插件的所有文件和资源。文件扩展名为 `.mxt` 以便于识别和管理。

### 标准目录结构

```
my_plugin.mxt (ZIP 压缩包)
├── plugin.json          # 插件元数据文件 (必需)
├── lib/                  # 插件代码目录
│   └── main.dart        # 插件入口点 (必需)
├── assets/               # 静态资源目录 (可选)
│   ├── icons/
│   ├── templates/
│   └── styles/
├── pubspec.yaml          # Dart 依赖配置 (可选)
└── README.md             # 插件说明文档 (推荐)
```

## 插件元数据 (plugin.json)

### 完整格式规范

```json
{
  "id": "unique_plugin_id",
  "name": "插件显示名称",
  "version": "1.0.0",
  "description": "插件功能的详细描述",
  "author": "作者姓名或组织",
  "homepage": "https://plugin-homepage.com",
  "repository": "https://github.com/author/plugin.git",
  "license": "MIT",
  "type": "syntax",
  "category": "visualization",
  "tags": ["chart", "diagram", "visualization"],
  "minVersion": "1.0.0",
  "dependencies": [],
  "supportedPlatforms": ["windows", "macos", "linux", "web", "android", "ios"],
  "permissions": ["file_system", "process"],
  "config": {
    "defaultFormat": {
      "type": "string",
      "default": "svg",
      "options": ["svg", "png", "pdf"]
    },
    "enableCache": {
      "type": "boolean",
      "default": true
    },
    "maxFileSize": {
      "type": "number",
      "default": 1048576,
      "min": 1024,
      "max": 10485760
    }
  },
  "entryPoint": "lib/main.dart",
  "assets": ["assets/"]
}
```

### 字段详细说明

#### 基本信息
- **id** (必需): 插件唯一标识符，建议使用下划线分隔的小写字母
- **name** (必需): 插件的显示名称
- **version** (必需): 插件版本，遵循 [语义化版本控制](https://semver.org/)
- **description** (必需): 插件功能描述
- **author** (必需): 插件作者信息

#### 可选信息
- **homepage**: 插件主页 URL
- **repository**: 源代码仓库 URL
- **license**: 许可证类型 (如 MIT, Apache-2.0, GPL-3.0)

#### 分类信息
- **type** (必需): 插件类型，可选值：
  - `syntax`: 语法扩展插件
  - `renderer`: 渲染器插件
  - `theme`: 主题插件
  - `export`: 导出插件
  - `import`: 导入插件
  - `tool`: 工具插件
  - `extension`: 扩展插件

- **category**: 插件分类 (如 visualization, converter, editor)
- **tags**: 插件标签数组，用于搜索和分类

#### 兼容性
- **minVersion**: 要求的 Markora 最低版本
- **dependencies**: 插件依赖列表
- **supportedPlatforms**: 支持的平台列表

#### 权限系统
- **permissions**: 插件所需权限列表：
  - `file_system`: 文件系统访问
  - `process`: 进程执行权限
  - `network`: 网络访问权限
  - `ui`: UI 修改权限

#### 配置选项
- **config**: 插件配置项定义，支持的类型：
  - `string`: 字符串类型
  - `boolean`: 布尔类型
  - `number`: 数字类型
  - 每个配置项可以定义默认值、选项列表、最小/最大值等

#### 技术信息
- **entryPoint**: 插件入口文件路径 (默认: "lib/main.dart")
- **assets**: 静态资源目录列表

## 插件开发

### 1. 创建插件项目

```bash
# 创建插件目录
mkdir my_awesome_plugin
cd my_awesome_plugin

# 创建基本目录结构
mkdir lib assets
touch plugin.json lib/main.dart README.md
```

### 2. 实现插件入口点

```dart
// lib/main.dart
import 'package:flutter/material.dart';

/// 插件主类
class MyAwesomePlugin {
  static const String pluginId = 'my_awesome_plugin';
  static const String pluginName = 'My Awesome Plugin';
  
  /// 插件初始化方法
  static Future<void> initialize() async {
    print('$pluginName initialized');
    // 执行插件初始化逻辑
  }
  
  /// 创建插件 UI 组件
  static Widget createWidget() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            pluginName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('这是一个示例插件'),
        ],
      ),
    );
  }
  
  /// 处理插件特定功能
  static Future<String> processContent(String input) async {
    // 实现插件的核心功能
    return 'Processed: $input';
  }
  
  /// 插件清理方法
  static Future<void> dispose() async {
    print('$pluginName disposed');
    // 执行清理逻辑
  }
}
```

### 3. 配置插件元数据

```json
{
  "id": "my_awesome_plugin",
  "name": "My Awesome Plugin",
  "version": "1.0.0",
  "description": "一个展示插件开发的示例插件",
  "author": "Your Name",
  "license": "MIT",
  "type": "tool",
  "category": "utility",
  "tags": ["example", "demo", "utility"],
  "minVersion": "1.0.0",
  "supportedPlatforms": ["windows", "macos", "linux"],
  "permissions": [],
  "entryPoint": "lib/main.dart"
}
```

## 插件打包

### 方法一：使用 PluginPackageService (推荐)

```dart
// 在 Markora 应用中使用
import 'package:markora/services/plugin_package_service.dart';

final packageService = PluginPackageService();

// 创建插件包
await packageService.createPackage(
  '/path/to/plugin/directory',
  '/path/to/output/my_plugin.mxt'
);
```

### 方法二：手动打包

```bash
# 进入插件目录
cd my_awesome_plugin

# 创建 ZIP 压缩包
zip -r my_awesome_plugin.mxt .

# 或使用 7-Zip (Windows)
7z a my_awesome_plugin.mxt *

# 或使用 tar (Unix/Linux/macOS)
tar -czf my_awesome_plugin.mxt.tar.gz .
mv my_awesome_plugin.mxt.tar.gz my_awesome_plugin.mxt
```

### 方法三：使用打包脚本

```bash
#!/bin/bash
# package_plugin.sh

PLUGIN_DIR="$1"
OUTPUT_FILE="$2"

if [ -z "$PLUGIN_DIR" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <plugin_directory> <output_file>"
    exit 1
fi

# 验证插件目录
if [ ! -f "$PLUGIN_DIR/plugin.json" ]; then
    echo "Error: plugin.json not found in $PLUGIN_DIR"
    exit 1
fi

if [ ! -f "$PLUGIN_DIR/lib/main.dart" ]; then
    echo "Error: lib/main.dart not found in $PLUGIN_DIR"
    exit 1
fi

# 创建压缩包
cd "$PLUGIN_DIR"
zip -r "$OUTPUT_FILE" . -x "*.git*" "*.DS_Store" "node_modules/*"

echo "Plugin packaged successfully: $OUTPUT_FILE"
```

## 插件安装

### 通过插件管理器安装

1. 打开 Markora 应用
2. 进入设置 → 插件管理
3. 点击"安装插件"按钮
4. 选择 `.mxt` 文件
5. 确认安装

### 程序化安装

```dart
import 'package:markora/services/plugin_manager.dart';

final pluginManager = PluginManager();

try {
  await pluginManager.installPlugin('/path/to/plugin.mxt');
  print('插件安装成功');
} catch (e) {
  print('插件安装失败: $e');
}
```

## 插件开发最佳实践

### 1. 代码组织

```
my_plugin/
├── lib/
│   ├── main.dart           # 插件入口
│   ├── models/             # 数据模型
│   ├── services/           # 业务逻辑
│   ├── widgets/            # UI 组件
│   └── utils/              # 工具函数
├── assets/
│   ├── icons/              # 图标资源
│   ├── images/             # 图片资源
│   └── templates/          # 模板文件
├── test/                   # 测试文件
├── plugin.json
├── pubspec.yaml
└── README.md
```

### 2. 错误处理

```dart
class MyPlugin {
  static Future<String> processContent(String input) async {
    try {
      // 插件逻辑
      return processedContent;
    } catch (e) {
      // 记录错误
      print('Plugin error: $e');
      
      // 返回友好的错误信息
      throw PluginException('处理内容时发生错误: ${e.toString()}');
    }
  }
}

class PluginException implements Exception {
  final String message;
  PluginException(this.message);
  
  @override
  String toString() => 'PluginException: $message';
}
```

### 3. 配置管理

```dart
class PluginConfig {
  final String defaultFormat;
  final bool enableCache;
  final int maxFileSize;
  
  PluginConfig({
    required this.defaultFormat,
    required this.enableCache,
    required this.maxFileSize,
  });
  
  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      defaultFormat: json['defaultFormat'] ?? 'svg',
      enableCache: json['enableCache'] ?? true,
      maxFileSize: json['maxFileSize'] ?? 1048576,
    );
  }
}
```

### 4. 资源管理

```dart
class PluginAssets {
  static const String iconPath = 'assets/icons/plugin_icon.svg';
  static const String templatePath = 'assets/templates/default.html';
  
  static Future<String> loadTemplate(String name) async {
    final path = 'assets/templates/$name.html';
    // 加载模板文件
    return templateContent;
  }
}
```

## 权限系统

### 权限声明

在 `plugin.json` 中声明所需权限：

```json
{
  "permissions": [
    "file_system",
    "process",
    "network"
  ]
}
```

### 权限使用

```dart
class FileSystemPlugin {
  static Future<String> readFile(String path) async {
    // 检查权限
    if (!hasPermission('file_system')) {
      throw PermissionException('需要文件系统访问权限');
    }
    
    // 执行文件操作
    final file = File(path);
    return await file.readAsString();
  }
}
```

## 测试

### 单元测试

```dart
// test/plugin_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  group('MyAwesomePlugin', () {
    test('should process content correctly', () async {
      const input = 'test input';
      final result = await MyAwesomePlugin.processContent(input);
      expect(result, equals('Processed: test input'));
    });
    
    test('should handle empty input', () async {
      const input = '';
      final result = await MyAwesomePlugin.processContent(input);
      expect(result, isNotEmpty);
    });
  });
}
```

### 集成测试

```dart
// test/integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:markora/services/plugin_manager.dart';

void main() {
  group('Plugin Integration', () {
    late PluginManager pluginManager;
    
    setUp(() {
      pluginManager = PluginManager();
    });
    
    test('should install plugin successfully', () async {
      await pluginManager.installPlugin('test_plugin.mxt');
      expect(pluginManager.plugins.length, greaterThan(0));
    });
  });
}
```

## 调试

### 开发模式

在开发过程中，可以直接在 `plugins` 目录中创建插件文件夹进行调试：

```
Markora/plugins/
├── my_plugin/              # 开发中的插件
│   ├── plugin.json
│   ├── lib/
│   │   └── main.dart
│   └── assets/
└── installed_plugin/       # 已安装的插件
```

### 日志记录

```dart
class PluginLogger {
  static void debug(String message) {
    print('[DEBUG] MyPlugin: $message');
  }
  
  static void error(String message, [dynamic error]) {
    print('[ERROR] MyPlugin: $message');
    if (error != null) {
      print('[ERROR] Details: $error');
    }
  }
}
```

## 故障排除

### 常见问题

1. **插件无法加载**
   - 检查 `plugin.json` 格式是否正确
   - 验证 `lib/main.dart` 是否存在
   - 查看控制台错误信息

2. **安装失败**
   - 确认 `.mxt` 文件完整性
   - 检查插件 ID 是否唯一
   - 验证平台兼容性

3. **权限错误**
   - 确认在 `plugin.json` 中声明了所需权限
   - 检查权限使用是否正确

4. **配置问题**
   - 验证配置项类型匹配
   - 检查默认值设置
   - 确认配置项名称正确

### 调试技巧

1. **启用详细日志**
   ```dart
   debugPrint('Plugin debug info: $details');
   ```

2. **使用断点调试**
   - 在 IDE 中设置断点
   - 使用调试模式运行 Markora

3. **检查插件状态**
   ```dart
   final plugins = PluginManager().plugins;
   for (final plugin in plugins) {
     print('Plugin: ${plugin.name}, Status: ${plugin.status}');
   }
   ```

## 发布与分发

### 版本管理

遵循 [语义化版本控制](https://semver.org/)：
- **主版本号**: 不兼容的 API 修改
- **次版本号**: 向下兼容的功能性新增
- **修订号**: 向下兼容的问题修正

### 发布清单

- [ ] 更新版本号
- [ ] 更新 CHANGELOG.md
- [ ] 运行所有测试
- [ ] 验证插件包完整性
- [ ] 测试安装和卸载
- [ ] 更新文档
- [ ] 创建发布标签

### 分发渠道

1. **GitHub Releases**: 在仓库中发布 `.mxt` 文件
2. **插件市场**: 提交到 Markora 官方插件市场（规划中）
3. **直接分发**: 通过网站或其他渠道分发

## 未来规划

### 即将推出的功能

1. **插件开发脚手架**: 自动生成插件项目模板
2. **热重载支持**: 开发时实时更新插件
3. **插件调试工具**: 专用的调试界面和工具
4. **插件市场**: 官方插件仓库和分发平台
5. **依赖管理**: 插件间依赖关系管理
6. **签名验证**: 插件安全性验证机制

### 长期目标

1. **沙箱机制**: 插件安全隔离运行
2. **插件 API**: 标准化的插件开发 API
3. **跨平台优化**: 更好的平台特定功能支持
4. **性能监控**: 插件性能分析和优化工具

## 结论

Markora 插件系统为开发者提供了强大而灵活的扩展能力。通过遵循本指南的最佳实践，您可以创建高质量、可维护的插件，为 Markora 生态系统做出贡献。

随着插件系统的不断发展，我们将持续改进开发体验和功能支持。建议开发者关注官方文档更新，以获取最新的开发指南和 API 变更信息。