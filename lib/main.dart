import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'app.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/document/infrastructure/repositories/hive_document_repository.dart';
import 'features/document/presentation/providers/document_providers.dart';
import 'features/plugins/domain/plugin_manager.dart';
import 'features/plugins/domain/plugin_interface.dart';
import 'features/plugins/domain/plugin_implementations.dart';
import 'types/document.dart';
import 'types/plugin.dart';

// 全局文档仓库实例
late HiveDocumentRepository globalDocumentRepository;

/// 应用入口函数
void main() async {
  // 确保Flutter组件绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive本地存储
  await Hive.initFlutter();
  
  // 清理可能存在的冲突数据
  await _cleanupHiveData();
  
  // 注册Hive适配器
  Hive.registerAdapter(ThemeModeAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(DocumentTypeAdapter());
  Hive.registerAdapter(DocumentAdapter());

  // 初始化文档仓库并创建示例数据
  globalDocumentRepository = HiveDocumentRepository();
  await globalDocumentRepository.init();
  await _createSampleDocuments(globalDocumentRepository);

  // 初始化插件管理器
  await _initializePluginManager();

  // 运行应用
  runApp(
    // Riverpod状态管理容器
    ProviderScope(
      overrides: [
        // 使用已初始化的仓库实例
        documentRepositoryProvider.overrideWithValue(globalDocumentRepository),
      ],
      child: const MarkoraApp(),
    ),
  );
}

/// 清理Hive数据（防止TypeId冲突）
Future<void> _cleanupHiveData() async {
  try {
    // 删除可能存在冲突的Box
    if (await Hive.boxExists('documents')) {
      await Hive.deleteBoxFromDisk('documents');
    }
  } catch (e) {
    // 忽略清理错误
    print('清理Hive数据时出错: $e');
  }
}

// 全局插件系统实例
late SyntaxRegistryImpl globalSyntaxRegistry;
late ToolbarRegistryImpl globalToolbarRegistry;
late MenuRegistryImpl globalMenuRegistry;

/// 初始化插件管理器
Future<void> _initializePluginManager() async {
  try {
    final pluginManager = PluginManager.instance;
    
    // 创建真正的插件系统实例
    globalSyntaxRegistry = SyntaxRegistryImpl();
    globalToolbarRegistry = ToolbarRegistryImpl();
    globalMenuRegistry = MenuRegistryImpl();
    
    final context = PluginContext(
      editorController: _SimpleEditorController(),
      syntaxRegistry: globalSyntaxRegistry,
      toolbarRegistry: globalToolbarRegistry,
      menuRegistry: globalMenuRegistry,
    );
    
    // 初始化插件管理器
    await pluginManager.initialize(context);
    
    print('插件管理器初始化完成');
  } catch (e) {
    print('插件管理器初始化失败: $e');
  }
}

/// 简单的编辑器控制器实现
class _SimpleEditorController implements EditorController {
  @override
  String get content => '';
  
  @override
  void setContent(String content) {}
  
  @override
  void insertText(String text) {}
  
  @override
  String get selectedText => '';
  
  @override
  void replaceSelection(String text) {}
  
  @override
  int get cursorPosition => 0;
  
  @override
  void setCursorPosition(int position) {}
}



/// 创建示例文档
Future<void> _createSampleDocuments(HiveDocumentRepository repo) async {
  final existingDocs = await repo.getAllDocuments();
  
  // 如果已有文档，则不创建示例文档
  if (existingDocs.isNotEmpty) return;

  // 创建示例文档
  await repo.createDocument(
    title: '欢迎使用Markora',
    content: '''# 欢迎使用 Markora

这是一个功能强大的 Markdown 编辑器，支持：

## 核心功能

- **实时预览** - 所见即所得的编辑体验
- **语法高亮** - 支持多种编程语言
- **数学公式** - 支持 LaTeX 数学公式
- **图表支持** - 集成 Mermaid 图表

## 快速开始

1. 在左侧编辑器中输入 Markdown 内容
2. 右侧会实时显示预览效果
3. 使用工具栏快速插入格式

### 代码示例

```dart
void main() {
  print('Hello, Markora!');
}
```

### 数学公式

行内公式：\$E = mc^2\$

块级公式：
\$\$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}\$\$

### 表格

| 功能 | 状态 | 说明 |
|------|------|------|
| 编辑器 | ✅ | 完成 |
| 预览 | ✅ | 完成 |
| 数学公式 | ✅ | 完成 |

> 开始你的 Markdown 创作之旅吧！''',
  );

  await repo.createDocument(
    title: '快速入门指南',
    content: '''# Markora 快速入门指南

## 基本操作

### 文件操作
- **新建文档**: Ctrl+N
- **打开文档**: Ctrl+O
- **保存文档**: Ctrl+S
- **另存为**: Ctrl+Shift+S

### 编辑操作
- **撤销**: Ctrl+Z
- **重做**: Ctrl+Y
- **复制**: Ctrl+C
- **粘贴**: Ctrl+V

### 格式化
- **粗体**: **文本** 或 Ctrl+B
- **斜体**: *文本* 或 Ctrl+I
- **代码**: `代码` 或 Ctrl+`

## 高级功能

### Mermaid 图表

```mermaid
graph TD
    A[开始] --> B{是否理解?}
    B -->|是| C[继续学习]
    B -->|否| D[重新阅读]
    D --> B
    C --> E[完成]
```

### 数学公式

二次方程求根公式：
\$\$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}\$\$

祝你使用愉快！''',
  );

  await repo.createDocument(
    title: '我的笔记',
    content: '''# 我的学习笔记

## 今日任务
- [ ] 学习Flutter开发
- [ ] 完成项目文档
- [x] 测试Markora编辑器

## 重要概念

### Widget
Flutter中的一切都是Widget，包括：
- StatelessWidget: 无状态组件
- StatefulWidget: 有状态组件

### 状态管理
推荐使用Riverpod进行状态管理。

## 代码片段

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello World'),
    );
  }
}
```

## 总结
今天学到了很多新知识！''',
  );
}

/// Markora应用主类
class MarkoraApp extends ConsumerWidget {
  const MarkoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听设置变化
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      // 应用基本信息
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // 主题配置 - 响应设置变化
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,

      // 应用主页
      home: const AppShell(),
    );
  }
}
