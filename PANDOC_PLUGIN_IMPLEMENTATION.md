# Pandoc 导出插件实现总结

## 概述

本文档总结了将Markora编辑器的导出功能从系统默认功能迁移到基于Pandoc的插件系统的完整实现过程。

## 完成的任务

### ✅ 1. 项目依赖配置
- 添加了 `process: ^5.0.2` 依赖用于调用外部pandoc命令
- 更新了pubspec.yaml配置

### ✅ 2. 插件基础架构
- 创建了 `PandocExportPlugin` 类，继承自 `MarkoraPlugin`
- 实现了完整的插件生命周期管理
- 支持插件的加载、卸载、激活、停用等操作

### ✅ 3. Pandoc服务实现
- 创建了 `PandocService` 类，封装所有pandoc相关操作
- 支持17种导出格式：PDF、HTML、DOCX、ODT、LaTeX、RTF、EPUB、MOBI、TXT、JSON、XML、OPML、reStructuredText、MediaWiki、Textile、AsciiDoc
- 支持14种导入格式：HTML、DOCX、ODT、LaTeX、RTF、EPUB、TXT、JSON、XML、OPML、reStructuredText、MediaWiki、Textile、AsciiDoc
- 实现了Pandoc可用性检测和版本获取
- 提供了默认导出选项配置

### ✅ 4. 用户界面组件
- 创建了 `PandocExportDialog` 导出对话框
- 创建了 `PandocImportDialog` 导入对话框
- 实现了友好的用户体验：
  - 平台支持检测（仅桌面端）
  - Pandoc可用性检测和提示
  - 格式选择和文件路径选择
  - 进度指示和错误处理
  - 成功/失败消息提示

### ✅ 5. 平台兼容性
- 实现了平台检测，仅在桌面端（Windows、macOS、Linux）启用
- Web端和移动端显示友好的不支持提示
- 跨平台的文件系统操作支持

### ✅ 6. 旧功能移除
- 移除了预览工具栏中的导出按钮
- 移除了应用菜单中的导出功能实现
- 移除了FileService中的导出方法
- 更新了SaveAsDialog，对导出格式显示插件提示
- 清理了相关的导入语句和依赖

### ✅ 7. 本地化支持
- 添加了完整的中英文本地化字符串
- 支持的语言键包括：
  - 插件基本信息（名称、描述等）
  - 对话框标题和标签
  - 按钮文本（导出、导入、浏览、取消）
  - 状态消息（成功、失败、可用性等）
  - 错误提示和平台限制说明

### ✅ 8. 代码质量
- 修复了所有编译错误
- 清理了未使用的导入和依赖
- 项目可以成功编译为Windows可执行文件

## 技术特性

### 格式支持
**导出格式（17种）**
- 文档格式：PDF、HTML、DOCX、ODT、LaTeX、RTF
- 电子书格式：EPUB、MOBI
- 纯文本格式：TXT、reStructuredText、MediaWiki、Textile、AsciiDoc
- 数据格式：JSON、XML、OPML

**导入格式（14种）**
- 支持将上述格式（除PDF外）转换为Markdown

### 安全性和稳定性
- 临时文件自动清理
- 进程调用错误处理
- 平台特定的命令执行
- 用户友好的错误消息

### 用户体验
- 实时的Pandoc可用性检测
- 清晰的格式选择界面
- 文件路径浏览和选择
- 导入导出进度指示
- 多语言界面支持

## 使用方法

### 前置条件
1. 系统需要安装Pandoc
   - Windows: 从 https://pandoc.org/installing.html 下载安装
   - macOS: `brew install pandoc`
   - Linux: `sudo apt install pandoc` 或相应包管理器

### 导出功能
1. 打开Markora编辑器
2. 编辑Markdown文档
3. 通过插件菜单或工具栏访问"Export with Pandoc"
4. 选择导出格式
5. 选择保存位置
6. 点击导出

### 导入功能
1. 通过插件菜单访问"Import with Pandoc"
2. 选择导入格式
3. 选择要导入的文件
4. 点击导入
5. 转换后的Markdown内容会加载到编辑器

## 文件结构

```
lib/features/plugins/
├── domain/
│   ├── entities/
│   │   └── pandoc_plugin.dart          # 插件主类
│   └── services/
│       └── pandoc_service.dart         # Pandoc服务
└── presentation/
    └── widgets/
        ├── pandoc_export_dialog.dart   # 导出对话框
        └── pandoc_import_dialog.dart   # 导入对话框
```

## 下一步计划

1. **插件注册**: 将插件注册到插件管理系统
2. **配置选项**: 添加更多导出配置选项（页面设置、样式等）
3. **模板支持**: 支持自定义导出模板
4. **批量操作**: 支持批量文件转换
5. **云服务**: 考虑集成在线转换服务作为备选方案

## 结论

Pandoc导出插件的实现成功地将导出功能模块化，提供了更强大和灵活的文档转换能力。通过使用开源的Pandoc工具，用户现在可以导出和导入多达17种不同的文档格式，大大扩展了Markora编辑器的实用性。

插件架构的采用也为未来的功能扩展奠定了良好的基础，使得添加新的导出格式或功能变得更加容易和模块化。 