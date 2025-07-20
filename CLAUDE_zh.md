# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在该代码仓库中工作时提供指导。

## 项目概述

Markora 是一个使用 Flutter 构建的新一代跨平台 Markdown 编辑器，致力于提供类似 Typora 的沉浸式写作体验，并具备 LaTeX 数学公式、Mermaid 图表和可扩展插件系统等高级功能。

## 常用开发命令

### Flutter 开发
```bash
# 获取依赖
flutter pub get

# 为 Hive 模型运行代码生成
flutter packages pub run build_runner build

# 在不同平台上运行
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome --web-port=8080
flutter run -d ios
flutter run -d android

# 启用桌面支持（如需要）
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# 分析和代码检查
flutter analyze

# 运行测试
flutter test
```

### 性能测试
```bash
# 运行性能基准测试
flutter test test/performance_benchmark_test.dart

# 运行数学兼容性测试
flutter test test/plugin_math_compatibility_test.dart
```

## 核心架构

### 清洁架构模式
```
lib/
├── core/                   # 核心工具和共享组件
│   ├── constants/         # 应用常量
│   ├── services/          # 共享服务 (command_service.dart)
│   ├── themes/           # 主题配置
│   └── utils/            # 关键性能工具：
│       ├── markdown_block_parser.dart    # 块级文档解析
│       ├── markdown_block_cache.dart     # LRU 缓存系统
│       ├── plugin_block_processor.dart   # 插件集成
│       └── performance_monitor.dart      # 性能跟踪
├── features/             # 基于功能的模块
│   ├── document/         # 文档管理
│   ├── editor/          # Markdown 编辑
│   ├── preview/         # 文档预览与优化
│   ├── plugins/         # 插件系统
│   ├── settings/        # 应用设置
│   └── syntax_highlighting/ # 代码高亮
├── types/               # 核心类型定义
└── main.dart           # 应用入口点
```

### 性能架构
Markora 为大型文档实现了**块级虚拟化渲染**：
- **MarkdownBlockParser** (`lib/core/utils/markdown_block_parser.dart`)：将 markdown 分割为独立块
- **MarkdownBlockCache** (`lib/core/utils/markdown_block_cache.dart`)：带智能失效的 LRU 缓存
- **PluginBlockProcessor** (`lib/core/utils/plugin_block_processor.dart`)：处理块内插件语法
- **PerformanceMonitor** (`lib/core/utils/performance_monitor.dart`)：实时性能跟踪

## 状态管理

### Riverpod 模式
- 使用 **Riverpod 2.5.1** 进行响应式状态管理
- 提供者位于 `*/presentation/providers/` 目录
- 遵循提供者命名：`[feature]Provider`、`[feature]NotifierProvider`
- 示例：`lib/features/document/presentation/providers/document_providers.dart`

### 关键提供者
- `documentProvider`：文档管理和文件操作
- `settingsProvider`：应用设置和首选项
- `pluginProvider`：插件系统状态

## 插件系统

### 插件架构
- 位于 `lib/features/plugins/domain/`
- 插件接口：`plugin_interface.dart`
- 插件管理器：`plugin_manager.dart`
- `plugins/` 目录中的示例插件

### 插件开发
- 每个插件都有 `plugin.json` 元数据
- 主实现在 `lib/main.dart`
- 内置插件：Mermaid 图表、Pandoc 导出

## 类型系统

### 核心类型 (lib/types/)
- `document.dart`：文档实体和模型
- `editor.dart`：编辑器特定类型
- `plugin.dart`：插件系统类型
- `syntax_highlighting.dart`：代码高亮类型

所有类型使用强类型 - 避免使用 `dynamic` 和 `Object?`。

## 代码质量标准

### 开发规则（来自 .cursor/rules/flutter.mdc）
- **类型安全**：不使用 `dynamic` 或 `Object?`
- **文件大小**：每个文件最大 200 行
- **架构**：遵循清洁架构层次
- **语言**：所有代码和注释使用英文
- **图标**：使用 `phosphor_flutter` 图标库

### 代码组织
- 功能模块遵循 domain/presentation/infrastructure 层次
- 复杂类型放在 `types/` 目录
- 共享工具在 `core/utils/`
- UI 遵循 Material Design 3

## 测试策略

### 测试文件
- `test/markdown_block_parser_test.dart`：块解析测试
- `test/performance_benchmark_test.dart`：性能基准测试
- `test/plugin_math_compatibility_test.dart`：插件兼容性测试
- `test/widget_test.dart`：组件测试

### 运行测试
性能测试包括以下基准：
- 块解析速度（目标：每秒 778 万字符）
- 缓存效率（目标：90%+ 命中率）
- 内存使用（无论文档大小都保持恒定）

## 技术栈

### 依赖项
- **Flutter**: 3.32.1（UI 框架）
- **Riverpod**: 2.5.1（状态管理）
- **GoRouter**: 14.3.0（路由）
- **Hive**: 2.2.3（本地存储）
- **flutter_markdown**: 0.7.4（markdown 渲染）
- **flutter_math_fork**: 0.7.2（LaTeX 公式）
- **webview_flutter**: 4.10.0（Mermaid 图表）
- **code_text_field**: 1.1.0（代码编辑器）

### 主要功能
- **数学公式**：通过 flutter_math_fork 渲染 LaTeX
- **图表**：通过 WebView 集成 Mermaid
- **代码高亮**：支持 27+ 种编程语言
- **导出**：PDF/HTML 导出功能
- **性能**：大型文档的块级虚拟化

## 开发工作流

### 进行更改前
1. 运行 `flutter pub get` 确保依赖项
2. 检查相关功能模块中的现有代码模式
3. 遵循已建立的清洁架构层次
4. 保持与现有 UI 模式的一致性

### 性能考虑
- 大型文档渲染使用块级虚拟化
- 重复渲染采用缓存优先方法
- 调试模式下提供性能监控
- 内存高效设计，内存使用恒定

### 插件开发
- 查看 `plugins/` 目录中的示例
- 遵循 `lib/features/plugins/domain/` 中的插件接口
- 插件支持自定义语法、渲染和 UI 扩展

## 已知问题和限制

### 当前状态
- 核心功能完成（85%+ 功能完成度）
- 插件系统运行正常，支持 Mermaid 和 Pandoc
- 针对 10MB+ 文档进行性能优化
- 已实现移动端响应式设计

### 下一步开发优先级
1. 设置模块增强
2. 导出功能扩展（DOCX、改进的 PDF）
3. 插件生态系统开发
4. 云同步集成

## 调试功能

### 性能监控（仅调试模式）
- 实时性能指标
- 缓存统计和效率报告
- 块级渲染分析
- 内存使用跟踪

在调试模式下运行时，通过预览工具栏分析图标访问。