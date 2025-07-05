## 项目名称：Markora  
**目标**：基于 Flutter 开发跨平台 Markdown 编辑器，支持多端（Windows/macOS/Linux/iOS/Android），核心功能对标 Typora，支持公式/图表/插件扩展。

## 核心需求  
1. **编辑与预览**  
   - 实现 Typora 式实时预览（编辑即渲染）  
   - 支持语法高亮（Markdown/代码块）  
   - 快捷键支持（粗体/斜体/标题等）  

2. **公式与图表**  
   - 数学公式：集成 LaTeX 引擎（如 KaTeX）  
   - 流程图/架构图：集成 Mermaid.js  
   - 绘图白板：支持手绘草图（Excalidraw 风格）  

3. **扩展系统**  
   - 插件机制：允许第三方扩展（如自定义语法/导出格式）  
   - 主题商店：支持安装主题（深色/浅色/自定义 CSS）  

4. **多端能力**  
   - 文件管理：本地存储 + 云同步（可选插件）  
   - 响应式 UI：适配桌面/移动端布局  

## 技术栈规划  
| 组件          | 推荐库/方案                          | 作用                   |
|---------------|--------------------------------------|------------------------|
| Markdown 渲染 | `flutter_markdown` + 自定义解析器    | 基础渲染 + 语法扩展    |
| 公式渲染      | `flutter_math` 或 WebView + KaTeX    | 数学公式支持           |
| 图表渲染      | `mermaid_dart` 或 WebView 嵌入       | 流程图/时序图          |
| 绘图白板      | 集成 `excalidraw` 或自定义 Canvas    | 手绘草图               |
| 插件系统      | Dart FFI + JavaScript 引擎（quickjs）| 动态加载扩展           |
| 持久化        | Hive/SQLite                          | 本地配置/缓存存储      |

## 关键实现步骤  
1. **编辑器核心**  
   - 使用 `CodeMirror`（通过 `flutter_code_editor`）实现编辑区  
   - 拆分屏幕：左侧编辑区 + 右侧预览区（移动端可切换）  

2. **动态渲染**  
   - 自定义 `MarkdownWidget`：拦截 ```mermaid/code 等语法  
   - 图表处理：将 Mermaid 代码发送至 WebView 或 WASM 模块渲染  

3. **插件系统设计**  
   ```dart
   abstract class MarkoraPlugin {
     String get name;
     void onLoad(EditorController controller); // 注入工具栏按钮/语法解析器
   }