# Flutter开发规则 - Markora项目

## 核心原则
- **高效协作**: 主动完成任务，减少来回确认
- **代码质量**: 追求简洁、可维护的代码
- **项目一致性**: 遵循现有架构和代码风格

## 开发规范

### 1. 代码质量
- 禁止使用 `dynamic` 和 `Object?`，追求类型安全
- 单文件不超过200行，超出时立即重构拆分
- 遵循 Clean Architecture 分层架构
- 使用 Riverpod 进行状态管理
- 所有代码、注释使用中文

### 2. 项目结构
- 复杂类型定义统一放在 `types/` 目录
- 功能模块按 `features/` 目录组织
- 遵循现有的 domain/presentation/infrastructure 分层

### 3. UI开发
- 遵循 Material Design 3 规范
- 保持与现有 Typora 风格界面一致
- 实现响应式布局适配多端
- 使用 `phosphor_flutter` 图标库

### 4. 技术栈约束
- Flutter 3.32.1 + Dart 3.8+
- 状态管理: Riverpod
- 路由: GoRouter
- 本地存储: Hive
- Markdown: flutter_markdown
- 数学公式: flutter_math_fork
- 图表: WebView + Mermaid

### 5. 工作流程
- 理解需求 → 分析现有代码 → 实现功能 → 测试验证
- 优先复用现有组件和服务
- 保持与现有代码风格一致
- 添加必要的错误处理和日志

## 交互优化
- 直接执行代码修改，无需过度确认
- 遇到问题时提供具体解决方案
- 完成后简要说明修改内容和影响
- 完成计划需要实时更新到readme中
- 每一个阶段完成都需要确保可以编译运行并提交git commit
- follow mcp-feedback-enhanced instructions

## 项目上下文
Markora 是一个跨平台 Markdown 编辑器，对标 Typora，支持数学公式、Mermaid图表、代码高亮等功能。项目已有完整架构，当前处于功能完善和优化阶段。 