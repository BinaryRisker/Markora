# Markora 插件架构文档

## 概述

Markora 插件系统是一个灵活、可扩展的架构，支持多种类型的插件来扩展编辑器功能。本文档描述了当前实现状态、架构设计原则以及未来发展规划。

## 当前实现状态

### 插件类型

当前支持以下插件类型：

- **语法插件 (syntax)**: 扩展 Markdown 语法支持
- **渲染器插件 (renderer)**: 自定义内容渲染
- **主题插件 (theme)**: 编辑器主题和样式
- **导出插件 (export)**: 文档导出功能
- **导入插件 (import)**: 文档导入功能
- **工具插件 (tool)**: 通用工具功能
- **扩展插件 (extension)**: 其他扩展功能

### 插件状态管理

插件具有以下状态：
- `enabled`: 已启用
- `disabled`: 已禁用
- `installed`: 已安装但未启用
- `error`: 错误状态
- `loading`: 加载中
- `notInstalled`: 未安装

### 插件元数据结构

每个插件必须包含 `plugin.json` 文件，定义插件元数据：

```json
{
  "id": "plugin_unique_id",
  "name": "插件显示名称",
  "version": "1.0.0",
  "description": "插件功能描述",
  "author": "作者信息",
  "homepage": "https://plugin-homepage.com",
  "repository": "https://github.com/author/plugin.git",
  "license": "MIT",
  "type": "syntax|renderer|theme|export|import|tool|extension",
  "category": "插件分类",
  "tags": ["标签1", "标签2"],
  "minVersion": "1.0.0",
  "dependencies": [],
  "supportedPlatforms": ["windows", "macos", "linux", "web", "android", "ios"],
  "permissions": ["file_system", "process", "network"],
  "config": {
    "configKey": {
      "type": "string|boolean|number",
      "default": "默认值",
      "options": ["选项1", "选项2"]
    }
  },
  "entryPoint": "lib/main.dart",
  "assets": ["assets/"]
}
```

### 插件目录结构

```
plugin_name/
├── plugin.json          # 插件元数据
├── lib/
│   └── main.dart        # 插件入口点
├── assets/              # 静态资源
│   └── ...
└── pubspec.yaml         # Dart 依赖配置（可选）
```

### 插件包格式 (.mxt)

插件以 `.mxt` (Markora eXTension) 格式分发，本质上是包含插件文件的 ZIP 压缩包。

## 核心组件

### 1. PluginManager

主要的插件管理器，负责：
- 插件生命周期管理
- 插件安装/卸载
- 插件状态跟踪
- 开发插件保护机制

```dart
class PluginManager extends ChangeNotifier {
  // 插件注册表
  final Map<String, PluginMetadata> _plugins = {};
  
  // 初始化插件系统
  Future<void> initialize();
  
  // 安装插件（带开发保护）
  Future<void> installPlugin(String mtxPath);
  
  // 卸载插件（保留文件）
  Future<void> uninstallPlugin(String pluginId);
}
```

### 2. PluginPackageService

处理插件包的创建、安装和验证：

```dart
class PluginPackageService {
  // 创建 .mxt 包
  Future<void> createPackage(String pluginDir, String outputPath);
  
  // 安装插件包
  Future<void> installPackage(String packagePath, String targetDir);
  
  // 验证插件包
  Future<bool> validatePackage(String packagePath);
}
```

### 3. PluginLoaderLegacy

传统插件加载器，处理插件发现和配置：

```dart
class PluginLoaderLegacy {
  // 扫描插件目录
  Future<void> scanPlugins();
  
  // 加载插件配置
  Future<void> loadPluginConfigurations();
}
```

## 安全机制

### 开发插件保护

系统会检测开发中的插件目录（包含 `lib/main.dart`），防止被包安装覆盖：

```dart
// 检查是否为开发插件目录
final devMainFile = File(path.join(pluginDir.path, 'lib', 'main.dart'));
if (await devMainFile.exists()) {
  throw Exception('Cannot install over development plugin: ${metadata.id}');
}
```

### 权限系统

插件可以声明所需权限：
- `file_system`: 文件系统访问
- `process`: 进程执行
- `network`: 网络访问
- `ui`: UI 修改权限

## 插件开发指南

### 1. 创建插件

```bash
# 创建插件目录
mkdir my_plugin
cd my_plugin

# 创建基本结构
mkdir lib assets
touch plugin.json lib/main.dart
```

### 2. 实现插件入口

```dart
// lib/main.dart
import 'package:flutter/material.dart';

class MyPlugin {
  static void initialize() {
    // 插件初始化逻辑
  }
  
  static Widget createWidget() {
    // 返回插件 UI 组件
    return Container();
  }
}
```

### 3. 打包插件

```bash
# 使用 PluginPackageService 创建 .mxt 包
# 或手动创建 ZIP 文件并重命名为 .mxt
```

## 未来发展规划

### 短期目标 (高优先级)

1. **统一插件管理架构**
   - 合并 `PluginManager` 和 `PluginLoaderLegacy`
   - 实现统一的插件生命周期管理
   - 标准化插件接口

2. **增强错误处理**
   - 实现统一的插件异常类型
   - 改善用户错误反馈
   - 添加错误恢复机制

3. **完善类型安全**
   - 强化插件配置验证
   - 实现强类型配置类
   - 改进 Hive 配置管理

### 中期目标 (中优先级)

1. **性能优化**
   - 实现插件缓存机制
   - 懒加载插件系统
   - 优化插件扫描性能

2. **开发者工具**
   - 插件开发脚手架
   - 插件调试工具
   - 热重载支持

3. **插件生态**
   - 插件市场/仓库
   - 插件版本管理
   - 依赖解析系统

### 长期目标 (低优先级)

1. **安全增强**
   - 插件沙箱机制
   - 插件签名验证
   - 权限管理系统
   - 代码审查机制

2. **跨平台支持**
   - Web 平台插件支持
   - 移动端插件适配
   - 云端插件同步

3. **高级功能**
   - 插件间通信机制
   - 插件 API 版本控制
   - 插件性能监控
   - 自动更新系统

## 最佳实践

### 插件开发

1. **遵循命名约定**: 使用描述性的插件 ID
2. **版本管理**: 遵循语义化版本控制
3. **文档完整**: 提供详细的使用说明
4. **错误处理**: 优雅处理异常情况
5. **性能考虑**: 避免阻塞主线程

### 插件分发

1. **测试充分**: 在多平台测试插件
2. **依赖最小**: 减少外部依赖
3. **资源优化**: 压缩静态资源
4. **权限最小**: 只申请必要权限

### 插件维护

1. **定期更新**: 保持与主程序兼容
2. **安全审查**: 定期检查安全漏洞
3. **用户反馈**: 及时响应用户问题
4. **向后兼容**: 保持 API 稳定性

## 故障排除

### 常见问题

1. **插件无法加载**
   - 检查 `plugin.json` 格式
   - 验证插件目录结构
   - 查看控制台错误信息

2. **安装失败**
   - 确认不是开发插件目录
   - 检查文件权限
   - 验证 `.mxt` 包完整性

3. **配置错误**
   - 检查配置类型匹配
   - 验证默认值设置
   - 清除插件缓存

### 调试技巧

1. 启用详细日志输出
2. 使用开发者工具检查插件状态
3. 手动验证插件文件结构
4. 检查平台兼容性

## 结论

Markora 插件系统正在持续发展中，当前实现已经提供了基础的插件管理功能和安全保护机制。通过逐步实施规划中的改进，将构建一个更加强大、安全、易用的插件生态系统。

开发者可以基于当前架构开始插件开发，同时关注未来的架构演进，确保插件的长期兼容性和可维护性。