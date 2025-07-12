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
- 支持插件界面的多语言切换
- 包含错误消息、状态提示等的本地化

### ✅ 8. 插件系统集成
- 在插件管理器中注册了Pandoc导出插件
- 支持插件的启用/禁用状态管理
- 插件在启动时自动启用
- 与现有的Mermaid插件并行工作

### ✅ 9. 问题修复和优化

#### 9.1 插件注册问题修复
**问题描述**：插件列表中看不到导出插件，工具栏导出按钮无效
**根本原因**：在非Web环境下，插件管理器的`_scanPlugins`方法没有调用`_scanKnownPlugins`方法，导致内置插件（包括Pandoc导出插件）没有被创建和注册。

**修复方案**：
1. 修改`plugin_manager.dart`中的`_scanPlugins`方法
2. 确保在非Web环境下也调用`_scanKnownPlugins`方法
3. 在扫描完物理插件目录后，额外扫描内置插件

**修复代码**：
```dart
// 在_scanPlugins方法中添加
// Also scan known plugins for non-web environments
debugPrint('Scanning known plugins for non-web environment');
await _scanKnownPlugins();
```

#### 9.2 插件实例化问题修复
**问题描述**：`PandocExportPlugin`类中的`PluginAction`使用问题
**修复方案**：
1. 为`PluginAction`添加`const`关键字
2. 修复插件回调函数的实现
3. 添加详细的调试输出

#### 9.3 导航器访问问题修复
**问题描述**：插件无法显示对话框，因为找不到Navigator
**修复方案**：
1. 创建`NavigatorService`类管理全局导航器
2. 在`main.dart`中设置全局`navigatorKey`
3. 修复`_findNavigator`方法的实现

#### 9.4 调试和日志增强
**改进内容**：
1. 在`PandocExportPlugin`中添加了详细的调试输出
2. 增强了插件加载过程的日志记录
3. 添加了工具栏按钮注册的状态追踪

## 技术特性

### 跨平台支持
- **桌面端**：完整支持（Windows、macOS、Linux）
- **Web端**：显示平台不支持提示
- **移动端**：显示平台不支持提示

### 格式支持
- **导出格式**：17种主流文档格式
- **导入格式**：14种主流文档格式
- **可扩展性**：易于添加新格式支持

### 用户体验
- **智能检测**：自动检测Pandoc安装状态
- **友好提示**：清晰的错误消息和状态反馈
- **多语言**：支持中英文界面
- **响应式**：适配不同屏幕尺寸

### 架构设计
- **模块化**：插件独立于主应用
- **可扩展**：易于添加新功能
- **类型安全**：使用强类型定义
- **错误处理**：完善的异常处理机制

## 测试验证

### 功能测试
- ✅ 插件列表显示正常
- ✅ 工具栏导出按钮可用
- ✅ 导出对话框正常显示
- ✅ 平台检测工作正常
- ✅ Pandoc可用性检测正常
- ✅ 多语言切换正常

### 集成测试
- ✅ 与Mermaid插件并行工作
- ✅ 插件管理界面正常
- ✅ 插件启用/禁用功能正常
- ✅ 应用启动时自动加载插件

### 错误处理测试
- ✅ 未安装Pandoc时的错误提示
- ✅ 不支持平台的友好提示
- ✅ 文件选择取消的处理
- ✅ 导出失败的错误反馈

## 部署说明

### 系统要求
- Flutter 3.32.1+
- Dart 3.8+
- 桌面端：Windows 10+、macOS 10.15+、Ubuntu 18.04+

### 依赖安装
1. 安装Flutter依赖：`flutter pub get`
2. 安装Pandoc（可选）：
   - Windows：`winget install pandoc`
   - macOS：`brew install pandoc`
   - Linux：`sudo apt-get install pandoc`

### 构建部署
1. 清理构建缓存：`flutter clean`
2. 重新获取依赖：`flutter pub get`
3. 构建应用：`flutter build windows/macos/linux`

## 后续计划

### 短期优化
- [ ] 添加更多导出选项配置
- [ ] 优化错误消息显示
- [ ] 添加导出进度显示
- [ ] 支持批量导出功能

### 长期规划
- [ ] 添加云端Pandoc服务支持
- [ ] 支持自定义模板
- [ ] 添加导出预览功能
- [ ] 支持插件市场分发

## 结论

Pandoc导出插件的实现成功地将Markora的导出功能从内置系统迁移到了可扩展的插件架构。通过解决插件注册、实例化、导航器访问等关键问题，插件现在能够正常工作，为用户提供了强大的文档转换功能。

插件系统的模块化设计为未来的功能扩展奠定了坚实基础，同时保持了代码的可维护性和用户体验的一致性。 