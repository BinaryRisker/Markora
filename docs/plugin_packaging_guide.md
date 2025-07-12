# Markora 插件打包指南

## 概述

Markora 支持使用 `.mxt` 格式的插件包来分发和安装插件。这个格式是一个压缩包，包含了插件的所有文件和元数据。

## MXT 格式规范

### 文件结构

一个 `.mxt` 插件包包含以下内容：

```
plugin.mxt
├── manifest.json          # 插件包清单文件
├── plugin.json           # 插件元数据文件
├── lib/                  # 插件源代码
│   └── main.dart        # 插件主文件
├── assets/              # 资源文件（可选）
└── README.md            # 插件说明（可选）
```

### manifest.json 格式

```json
{
  "metadata": {
    "id": "pandoc_plugin",
    "name": "Pandoc Export Plugin",
    "version": "1.0.0",
    "description": "Universal document converter using Pandoc",
    "author": "Markora Team",
    "homepage": "https://github.com/markora/pandoc-plugin",
    "repository": "https://github.com/markora/pandoc-plugin.git",
    "license": "MIT",
    "type": "export",
    "tags": ["export", "import", "pandoc", "converter"],
    "minVersion": "1.0.0",
    "maxVersion": null,
    "dependencies": []
  },
  "files": [
    "plugin.json",
    "lib/main.dart",
    "assets/icon.png"
  ],
  "packageVersion": "1.0.0",
  "dependencies": [],
  "assets": ["assets/icon.png"],
  "permissions": [
    "ui.dialog",
    "editor.access",
    "file.read",
    "file.write"
  ]
}
```

## 打包插件

### 1. 准备插件目录

确保你的插件目录包含以下必要文件：

- `plugin.json` - 插件元数据
- `lib/main.dart` - 插件主实现文件

### 2. 使用打包脚本

运行以下命令来打包 Pandoc 插件：

```bash
dart scripts/package_pandoc_plugin.dart
```

这将创建一个 `packages/pandoc_plugin.mxt` 文件。

### 3. 手动打包（可选）

你也可以使用 PluginPackageService 来手动打包：

```dart
import 'package:markora/features/plugins/domain/plugin_package_service.dart';

final packagePath = await PluginPackageService.createPackage(
  pluginDir: 'plugins/your_plugin',
  outputPath: 'packages/your_plugin.mxt',
);
```

## 安装插件包

### 通过插件管理器安装

1. 打开 Markora 应用程序
2. 进入 "插件管理" 页面
3. 点击右上角的 "+" 按钮
4. 选择 "Install MXT Package"
5. 选择你的 `.mxt` 文件
6. 确认安装信息
7. 点击 "Install" 完成安装

### 程序化安装

```dart
import 'package:markora/features/plugins/domain/plugin_package_service.dart';

final installedPath = await PluginPackageService.installPackage(
  packagePath: 'path/to/plugin.mxt',
  installDir: 'plugins',
);
```

## 插件开发指南

### 基本插件结构

```dart
import 'package:flutter/material.dart';

class YourPlugin extends MarkoraPlugin {
  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'your_plugin',
    name: 'Your Plugin Name',
    version: '1.0.0',
    description: 'Plugin description',
    author: 'Your Name',
    license: 'MIT',
    type: PluginType.tool,
    tags: ['tag1', 'tag2'],
    minVersion: '1.0.0',
  );

  @override
  Future<void> onLoad(PluginContext context) async {
    // 注册工具栏按钮
    context.toolbarRegistry.registerAction(
      const PluginAction(
        id: 'your_action',
        title: 'Your Action',
        description: 'Action description',
        icon: 'icon_name',
      ),
      () => _handleAction(context),
    );
  }

  void _handleAction(PluginContext context) {
    // 处理用户操作
    showDialog(
      context: context.context!,
      builder: (context) => AlertDialog(
        title: const Text('Your Plugin'),
        content: const Text('Plugin is working!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### plugin.json 示例

```json
{
  "id": "your_plugin",
  "name": "Your Plugin Name",
  "version": "1.0.0",
  "description": "Plugin description",
  "author": "Your Name",
  "homepage": "https://your-website.com",
  "repository": "https://github.com/your-username/your-plugin.git",
  "license": "MIT",
  "type": "tool",
  "tags": ["tag1", "tag2"],
  "minVersion": "1.0.0",
  "dependencies": []
}
```

## 权限系统

插件可以请求以下权限：

- `ui.dialog` - 显示对话框
- `editor.access` - 访问编辑器内容
- `file.read` - 读取文件
- `file.write` - 写入文件
- `network.access` - 网络访问

## 最佳实践

1. **版本控制**: 使用语义化版本号
2. **错误处理**: 添加适当的错误处理和用户反馈
3. **性能**: 避免阻塞 UI 线程的长时间操作
4. **兼容性**: 指定支持的 Markora 版本范围
5. **文档**: 提供清晰的插件说明和使用指南

## 故障排除

### 常见问题

1. **插件无法加载**
   - 检查 `plugin.json` 格式是否正确
   - 确保 `lib/main.dart` 存在且语法正确
   - 检查插件 ID 是否唯一

2. **权限错误**
   - 确保在 manifest.json 中声明了所需权限
   - 检查权限名称是否正确

3. **版本不兼容**
   - 检查 `minVersion` 和 `maxVersion` 设置
   - 确保使用的 API 在目标版本中可用

## 示例插件

参考 `plugins/pandoc_plugin/` 目录中的 Pandoc 插件实现，了解完整的插件开发示例。 