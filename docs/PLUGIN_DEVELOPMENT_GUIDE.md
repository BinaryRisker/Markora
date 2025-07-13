# Markora 插件开发指南

## 概述

本指南将帮助开发者创建功能强大的 Markora 插件，涵盖从基础概念到高级功能的完整开发流程。

## 快速开始

### 1. 开发环境准备

#### 1.1 必需工具

```bash
# Flutter SDK (>=3.19.0)
flutter --version

# Dart SDK (>=3.0.0)
dart --version

# Markora CLI 工具
npm install -g @markora/cli

# 或使用 Dart 版本
dart pub global activate markora_cli
```

#### 1.2 创建第一个插件

```bash
# 创建插件项目
markora plugin create my-first-plugin

# 选择插件类型
? Select plugin type: 
  > Dart Plugin (Flutter/Dart code)
    JavaScript Plugin (JS code)
    Hybrid Plugin (Dart + JS)
    WebView Plugin (HTML/CSS/JS)

# 选择插件分类
? Select category:
  > editor (编辑器功能)
    renderer (内容渲染)
    tool (开发工具)
    theme (主题)
    converter (格式转换)

# 进入项目目录
cd my-first-plugin

# 查看项目结构
tree .
```

### 2. 项目结构

```
my-first-plugin/
├── plugin.json              # 插件清单
├── lib/                     # Dart 代码 (可选)
│   └── main.dart           # Dart 入口点
├── src/                     # JavaScript 代码 (可选)
│   └── main.js             # JS 入口点
├── assets/                  # 静态资源
│   ├── icons/              # 图标
│   ├── themes/             # 主题文件
│   └── templates/          # 模板文件
├── locales/                # 国际化
│   ├── en.json
│   └── zh.json
├── webview/                # WebView 资源 (可选)
│   ├── index.html
│   ├── style.css
│   └── script.js
├── test/                   # 测试文件
│   ├── unit/
│   └── integration/
├── docs/                   # 文档
│   └── README.md
├── CHANGELOG.md            # 更新日志
└── pubspec.yaml            # Dart 依赖 (Dart 插件)
```

## 核心概念

### 1. 插件类型

#### 1.1 Dart 插件

适用于需要深度集成 Flutter 功能的插件：

```dart
// lib/main.dart
import 'package:markora_plugin_api/markora_plugin_api.dart';

class MyFirstPlugin extends MarkoraPlugin {
  @override
  PluginMetadata get metadata => PluginMetadata(
    id: 'com.example.my-first-plugin',
    name: 'My First Plugin',
    version: '1.0.0',
    description: 'A simple example plugin',
    author: 'Your Name',
  );

  @override
  Future<void> activate(PluginContext context) async {
    // 注册命令
    context.commandRegistry.register(
      'myFirstPlugin.hello',
      'Say Hello',
      _sayHello,
    );
    
    // 注册工具栏按钮
    context.toolbarRegistry.register(
      PluginAction(
        id: 'myFirstPlugin.hello',
        title: 'Hello',
        icon: PhosphorIcons.heart,
        tooltip: 'Say hello to the world',
      ),
      _sayHello,
    );
  }

  void _sayHello() {
    context.ui.showNotification(
      'Hello from My First Plugin!',
      NotificationType.info,
    );
  }

  @override
  Future<void> deactivate() async {
    // 清理资源
  }
}

// 插件入口点
MarkoraPlugin createPlugin() => MyFirstPlugin();
```

#### 1.2 JavaScript 插件

适用于轻量级功能和快速原型：

```javascript
// src/main.js

class MyFirstPlugin {
  constructor() {
    this.api = null;
  }

  async activate(context) {
    this.api = context.api;
    
    // 注册命令
    await this.api.ui.registerCommand(
      'myFirstPlugin.hello',
      'Say Hello',
      () => this.sayHello()
    );
    
    // 注册工具栏按钮
    await this.api.ui.addToolbarItem({
      id: 'myFirstPlugin.hello',
      icon: 'heart',
      tooltip: 'Say hello to the world',
      command: 'myFirstPlugin.hello'
    });
    
    console.log('My First Plugin activated!');
  }

  async deactivate() {
    console.log('My First Plugin deactivated!');
  }

  async sayHello() {
    await this.api.ui.showNotification(
      'Hello from My First Plugin!',
      'info'
    );
  }
}

// 插件入口点
function activate(context) {
  const plugin = new MyFirstPlugin();
  return plugin.activate(context);
}

function deactivate() {
  // 全局清理
}
```

#### 1.3 混合插件

结合 Dart 和 JavaScript 的优势：

```dart
// lib/main.dart - Dart 部分处理复杂逻辑
class MyHybridPlugin extends MarkoraPlugin {
  @override
  Future<void> activate(PluginContext context) async {
    // 注册复杂的数据处理服务
    context.serviceRegistry.register(
      'dataProcessor',
      DataProcessorService(),
    );
    
    // 通知 JavaScript 部分插件已就绪
    context.jsEngine.emit('dart.ready', {
      'services': ['dataProcessor'],
    });
  }
}
```

```javascript
// src/main.js - JavaScript 部分处理 UI 交互
class MyHybridPlugin {
  async activate(context) {
    this.api = context.api;
    
    // 等待 Dart 部分就绪
    this.api.events.on('dart.ready', (data) => {
      this.setupUI();
    });
  }

  async setupUI() {
    // 注册 UI 命令，调用 Dart 服务
    await this.api.ui.registerCommand(
      'hybrid.processData',
      'Process Data',
      () => this.processData()
    );
  }

  async processData() {
    // 调用 Dart 服务
    const result = await this.api.services.call(
      'dataProcessor',
      'process',
      { data: 'example' }
    );
    
    await this.api.ui.showNotification(
      `Processed: ${result}`,
      'success'
    );
  }
}
```

### 2. 插件 API

#### 2.1 编辑器 API

```dart
// Dart 版本
class EditorExamplePlugin extends MarkoraPlugin {
  @override
  Future<void> activate(PluginContext context) async {
    context.commandRegistry.register(
      'editor.insertTimestamp',
      'Insert Timestamp',
      _insertTimestamp,
    );
  }

  void _insertTimestamp() {
    final timestamp = DateTime.now().toIso8601String();
    context.editor.insertText('Generated at: $timestamp');
  }

  void _setupEditorListeners() {
    // 监听编辑器事件
    context.editor.onContentChanged.listen((content) {
      print('Content changed: ${content.length} characters');
    });
    
    context.editor.onSelectionChanged.listen((selection) {
      print('Selection: ${selection.start}-${selection.end}');
    });
  }
}
```

```javascript
// JavaScript 版本
class EditorExamplePlugin {
  async activate(context) {
    this.api = context.api;
    
    // 注册命令
    await this.api.ui.registerCommand(
      'editor.insertTimestamp',
      'Insert Timestamp',
      () => this.insertTimestamp()
    );
    
    // 监听编辑器事件
    this.api.events.on('editor.contentChanged', (data) => {
      console.log(`Content changed: ${data.content.length} characters`);
    });
    
    this.api.events.on('editor.selectionChanged', (data) => {
      console.log(`Selection: ${data.start}-${data.end}`);
    });
  }

  async insertTimestamp() {
    const timestamp = new Date().toISOString();
    await this.api.editor.insertText(`Generated at: ${timestamp}`);
  }

  async getWordCount() {
    const content = await this.api.editor.getContent();
    const words = content.split(/\s+/).filter(word => word.length > 0);
    return words.length;
  }

  async highlightSelection() {
    const selection = await this.api.editor.getSelection();
    if (selection.text) {
      await this.api.editor.replaceSelection(`**${selection.text}**`);
    }
  }
}
```

#### 2.2 UI 扩展 API

```javascript
// 复杂 UI 扩展示例
class UIExtensionPlugin {
  async activate(context) {
    this.api = context.api;
    
    // 注册多个命令
    await this.registerCommands();
    
    // 创建自定义面板
    await this.createCustomPanel();
    
    // 添加菜单项
    await this.addMenuItems();
  }

  async registerCommands() {
    const commands = [
      {
        id: 'ui.showWordCount',
        title: 'Show Word Count',
        handler: () => this.showWordCount()
      },
      {
        id: 'ui.insertTable',
        title: 'Insert Table',
        handler: () => this.insertTable()
      },
      {
        id: 'ui.formatDocument',
        title: 'Format Document',
        handler: () => this.formatDocument()
      }
    ];

    for (const cmd of commands) {
      await this.api.ui.registerCommand(cmd.id, cmd.title, cmd.handler);
    }
  }

  async createCustomPanel() {
    const panel = await this.api.ui.createWebView({
      title: 'Document Statistics',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI'; }
            .stat { margin: 10px 0; }
            .number { font-size: 24px; font-weight: bold; color: #007ACC; }
          </style>
        </head>
        <body>
          <div id="stats">
            <div class="stat">
              <div class="number" id="words">0</div>
              <div>Words</div>
            </div>
            <div class="stat">
              <div class="number" id="chars">0</div>
              <div>Characters</div>
            </div>
            <div class="stat">
              <div class="number" id="lines">0</div>
              <div>Lines</div>
            </div>
          </div>
          
          <script>
            function updateStats(stats) {
              document.getElementById('words').textContent = stats.words;
              document.getElementById('chars').textContent = stats.characters;
              document.getElementById('lines').textContent = stats.lines;
            }
          </script>
        </body>
        </html>
      `,
      width: 250,
      height: 300
    });

    // 定期更新统计信息
    setInterval(() => this.updateStatistics(panel), 2000);
  }

  async updateStatistics(panel) {
    const content = await this.api.editor.getContent();
    const stats = {
      words: content.split(/\s+/).filter(word => word.length > 0).length,
      characters: content.length,
      lines: content.split('\n').length
    };

    await panel.postMessage({
      type: 'updateStats',
      data: stats
    });
  }

  async addMenuItems() {
    // 添加到编辑器右键菜单
    await this.api.ui.addMenuItem({
      menu: 'editor/context',
      id: 'format.selection',
      title: 'Format Selection',
      command: 'ui.formatSelection',
      when: 'editorHasSelection'
    });

    // 添加到主菜单
    await this.api.ui.addMenuItem({
      menu: 'tools',
      id: 'document.stats',
      title: 'Document Statistics',
      command: 'ui.showWordCount'
    });
  }

  async showWordCount() {
    const stats = await this.calculateStats();
    
    await this.api.ui.showDialog({
      title: 'Document Statistics',
      content: `
        <p><strong>Words:</strong> ${stats.words}</p>
        <p><strong>Characters:</strong> ${stats.characters}</p>
        <p><strong>Lines:</strong> ${stats.lines}</p>
        <p><strong>Paragraphs:</strong> ${stats.paragraphs}</p>
        <p><strong>Reading time:</strong> ${stats.readingTime} min</p>
      `,
      buttons: ['OK']
    });
  }

  async insertTable() {
    const config = await this.api.ui.showInputDialog({
      title: 'Insert Table',
      fields: [
        {
          name: 'rows',
          label: 'Rows',
          type: 'number',
          default: 3,
          min: 1,
          max: 20
        },
        {
          name: 'cols',
          label: 'Columns',
          type: 'number',
          default: 3,
          min: 1,
          max: 10
        },
        {
          name: 'headers',
          label: 'Include headers',
          type: 'boolean',
          default: true
        }
      ]
    });

    if (config) {
      const table = this.generateTable(config.rows, config.cols, config.headers);
      await this.api.editor.insertText(table);
    }
  }

  generateTable(rows, cols, hasHeaders) {
    let table = '';
    
    // 生成表头
    if (hasHeaders) {
      table += '|';
      for (let i = 0; i < cols; i++) {
        table += ` Header ${i + 1} |`;
      }
      table += '\n|';
      for (let i = 0; i < cols; i++) {
        table += '-------------|';
      }
      table += '\n';
      rows--; // 减去表头行
    }
    
    // 生成数据行
    for (let r = 0; r < rows; r++) {
      table += '|';
      for (let c = 0; c < cols; c++) {
        table += ` Cell ${r + 1}.${c + 1} |`;
      }
      table += '\n';
    }
    
    return table;
  }

  async calculateStats() {
    const content = await this.api.editor.getContent();
    const words = content.split(/\s+/).filter(word => word.length > 0);
    const lines = content.split('\n');
    const paragraphs = content.split(/\n\s*\n/).filter(p => p.trim().length > 0);
    
    return {
      words: words.length,
      characters: content.length,
      lines: lines.length,
      paragraphs: paragraphs.length,
      readingTime: Math.ceil(words.length / 200) // 假设每分钟读 200 词
    };
  }
}
```

#### 2.3 存储 API

```javascript
// 数据持久化示例
class StorageExamplePlugin {
  async activate(context) {
    this.api = context.api;
    
    // 恢复保存的状态
    await this.restoreState();
    
    // 注册设置相关命令
    await this.registerSettingsCommands();
    
    // 监听配置变更
    this.api.events.on('config.changed', (config) => {
      this.onConfigChanged(config);
    });
  }

  async restoreState() {
    // 获取保存的设置
    const settings = await this.api.storage.get('settings') || {};
    this.settings = {
      autoSave: true,
      theme: 'default',
      fontSize: 14,
      ...settings
    };

    // 获取使用统计
    this.stats = await this.api.storage.get('stats') || {
      documentsCreated: 0,
      totalWordCount: 0,
      lastUsed: Date.now()
    };

    // 获取用户数据
    this.userData = await this.api.storage.get('userData') || {
      recentFiles: [],
      bookmarks: [],
      customTemplates: []
    };
  }

  async saveSettings() {
    await this.api.storage.set('settings', this.settings);
  }

  async updateStats(wordCount) {
    this.stats.totalWordCount += wordCount;
    this.stats.lastUsed = Date.now();
    await this.api.storage.set('stats', this.stats);
  }

  async addRecentFile(filePath) {
    this.userData.recentFiles.unshift(filePath);
    
    // 保持最近文件列表在 10 个以内
    if (this.userData.recentFiles.length > 10) {
      this.userData.recentFiles = this.userData.recentFiles.slice(0, 10);
    }
    
    await this.api.storage.set('userData', this.userData);
  }

  async registerSettingsCommands() {
    await this.api.ui.registerCommand(
      'storage.showSettings',
      'Show Plugin Settings',
      () => this.showSettings()
    );

    await this.api.ui.registerCommand(
      'storage.exportData',
      'Export Plugin Data',
      () => this.exportData()
    );

    await this.api.ui.registerCommand(
      'storage.clearData',
      'Clear Plugin Data',
      () => this.clearData()
    );
  }

  async showSettings() {
    const result = await this.api.ui.showDialog({
      title: 'Plugin Settings',
      content: `
        <form id="settingsForm">
          <div class="field">
            <label>
              <input type="checkbox" ${this.settings.autoSave ? 'checked' : ''}
                     name="autoSave"> Auto Save
            </label>
          </div>
          <div class="field">
            <label>Theme:</label>
            <select name="theme">
              <option value="default" ${this.settings.theme === 'default' ? 'selected' : ''}>Default</option>
              <option value="dark" ${this.settings.theme === 'dark' ? 'selected' : ''}>Dark</option>
              <option value="light" ${this.settings.theme === 'light' ? 'selected' : ''}>Light</option>
            </select>
          </div>
          <div class="field">
            <label>Font Size:</label>
            <input type="number" name="fontSize" 
                   value="${this.settings.fontSize}" min="10" max="24">
          </div>
        </form>
      `,
      buttons: ['Save', 'Cancel']
    });

    if (result.button === 'Save') {
      const formData = result.formData;
      this.settings = {
        autoSave: formData.autoSave,
        theme: formData.theme,
        fontSize: parseInt(formData.fontSize)
      };
      await this.saveSettings();
    }
  }

  async exportData() {
    const exportData = {
      settings: this.settings,
      stats: this.stats,
      userData: this.userData,
      timestamp: new Date().toISOString()
    };

    const jsonData = JSON.stringify(exportData, null, 2);
    
    await this.api.fs.showSaveDialog({
      defaultName: 'plugin-data-export.json',
      filters: [
        { name: 'JSON Files', extensions: ['json'] }
      ]
    }).then(async (filePath) => {
      if (filePath) {
        await this.api.fs.writeFile(filePath, jsonData);
        await this.api.ui.showNotification(
          'Data exported successfully',
          'success'
        );
      }
    });
  }

  async clearData() {
    const confirmed = await this.api.ui.showConfirmDialog({
      title: 'Clear All Data',
      message: 'This will permanently delete all plugin data. Are you sure?',
      confirmText: 'Clear Data',
      cancelText: 'Cancel'
    });

    if (confirmed) {
      await this.api.storage.remove('settings');
      await this.api.storage.remove('stats');
      await this.api.storage.remove('userData');
      
      // 重置到默认状态
      await this.restoreState();
      
      await this.api.ui.showNotification(
        'All plugin data cleared',
        'info'
      );
    }
  }
}
```

#### 2.4 渲染器 API

```javascript
// 自定义渲染器示例
class CustomRendererPlugin {
  async activate(context) {
    this.api = context.api;
    
    // 注册多个渲染器
    await this.registerRenderers();
  }

  async registerRenderers() {
    // 数学公式渲染器
    await this.api.renderers.register('math', (content) => {
      return this.renderMath(content);
    });

    // 图表渲染器
    await this.api.renderers.register('chart', (content) => {
      return this.renderChart(content);
    });

    // 时序图渲染器
    await this.api.renderers.register('sequence', (content) => {
      return this.renderSequenceDiagram(content);
    });

    // 音乐符号渲染器
    await this.api.renderers.register('music', (content) => {
      return this.renderMusicNotation(content);
    });
  }

  renderMath(content) {
    return {
      type: 'webview',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
          <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
          <script>
            window.MathJax = {
              tex: { inlineMath: [['$', '$'], ['\\\\(', '\\\\)']] },
              chtml: { scale: 1.2 }
            };
          </script>
          <style>
            body { margin: 10px; font-family: 'Times New Roman', serif; }
            .math-container { text-align: center; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="math-container">
            $$${content}$$
          </div>
        </body>
        </html>
      `,
      height: 'auto'
    };
  }

  renderChart(content) {
    const config = this.parseChartConfig(content);
    
    return {
      type: 'webview',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
          <style>
            body { margin: 0; padding: 20px; }
            canvas { max-width: 100%; }
          </style>
        </head>
        <body>
          <canvas id="chart"></canvas>
          <script>
            const ctx = document.getElementById('chart').getContext('2d');
            new Chart(ctx, ${JSON.stringify(config)});
          </script>
        </body>
        </html>
      `,
      height: 400
    };
  }

  renderSequenceDiagram(content) {
    return {
      type: 'webview',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <script src="https://unpkg.com/mermaid/dist/mermaid.min.js"></script>
          <style>
            body { margin: 20px; }
            .sequence-diagram { text-align: center; }
          </style>
        </head>
        <body>
          <div class="sequence-diagram">
            <pre class="mermaid">
sequenceDiagram
${content}
            </pre>
          </div>
          <script>
            mermaid.initialize({ startOnLoad: true, theme: 'default' });
          </script>
        </body>
        </html>
      `,
      height: 300
    };
  }

  renderMusicNotation(content) {
    return {
      type: 'webview',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <script src="https://unpkg.com/abcjs/dist/abcjs-basic-min.js"></script>
          <style>
            body { margin: 20px; background: white; }
            #notation { margin: 20px 0; }
          </style>
        </head>
        <body>
          <div id="notation"></div>
          <script>
            ABCJS.renderAbc("notation", \`${content}\`, {
              responsive: "resize",
              staffwidth: 600
            });
          </script>
        </body>
        </html>
      `,
      height: 200
    };
  }

  parseChartConfig(content) {
    // 解析图表配置
    try {
      return JSON.parse(content);
    } catch (e) {
      // 提供默认配置
      return {
        type: 'bar',
        data: {
          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
          datasets: [{
            label: 'Sample Data',
            data: [10, 20, 30, 40, 50],
            backgroundColor: 'rgba(54, 162, 235, 0.2)',
            borderColor: 'rgba(54, 162, 235, 1)',
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          scales: {
            y: { beginAtZero: true }
          }
        }
      };
    }
  }
}
```

## 高级功能

### 1. 插件间通信

```javascript
// 插件 A - 提供服务
class ServiceProviderPlugin {
  async activate(context) {
    this.api = context.api;
    
    // 注册服务
    await this.api.services.register('dataProcessor', {
      process: this.processData.bind(this),
      validate: this.validateData.bind(this),
      transform: this.transformData.bind(this)
    });
    
    // 发布事件
    this.api.events.emit('service.dataProcessor.ready', {
      version: '1.0.0',
      capabilities: ['process', 'validate', 'transform']
    });
  }

  async processData(data) {
    // 复杂的数据处理逻辑
    return {
      processed: true,
      result: data.toUpperCase(),
      timestamp: Date.now()
    };
  }

  async validateData(data) {
    return data && typeof data === 'string' && data.length > 0;
  }

  async transformData(data, format) {
    switch (format) {
      case 'json':
        return JSON.stringify(data);
      case 'xml':
        return `<data>${data}</data>`;
      default:
        return data;
    }
  }
}

// 插件 B - 消费服务
class ServiceConsumerPlugin {
  async activate(context) {
    this.api = context.api;
    
    // 等待服务就绪
    this.api.events.on('service.dataProcessor.ready', (info) => {
      this.dataProcessorReady = true;
      console.log('Data processor service ready:', info);
    });
    
    await this.api.ui.registerCommand(
      'consumer.processText',
      'Process Selected Text',
      () => this.processSelectedText()
    );
  }

  async processSelectedText() {
    if (!this.dataProcessorReady) {
      await this.api.ui.showNotification(
        'Data processor service not available',
        'warning'
      );
      return;
    }

    const selection = await this.api.editor.getSelection();
    if (!selection.text) {
      await this.api.ui.showNotification(
        'Please select some text first',
        'info'
      );
      return;
    }

    try {
      // 调用其他插件的服务
      const result = await this.api.services.call(
        'dataProcessor',
        'process',
        selection.text
      );

      await this.api.editor.replaceSelection(result.result);
      
      await this.api.ui.showNotification(
        'Text processed successfully',
        'success'
      );
    } catch (error) {
      await this.api.ui.showNotification(
        `Processing failed: ${error.message}`,
        'error'
      );
    }
  }
}
```

### 2. 主题和样式

```javascript
// 主题插件示例
class ThemePlugin {
  async activate(context) {
    this.api = context.api;
    
    // 注册多个主题
    await this.registerThemes();
    
    // 注册主题切换命令
    await this.api.ui.registerCommand(
      'theme.switch',
      'Switch Theme',
      () => this.showThemeSelector()
    );
  }

  async registerThemes() {
    const themes = [
      {
        id: 'ocean-dark',
        name: 'Ocean Dark',
        type: 'dark',
        colors: {
          background: '#001122',
          surface: '#002244',
          primary: '#00aaff',
          text: '#ffffff',
          accent: '#ffaa00'
        }
      },
      {
        id: 'forest-light',
        name: 'Forest Light',
        type: 'light',
        colors: {
          background: '#f8fff8',
          surface: '#ffffff',
          primary: '#228b22',
          text: '#2d4a2d',
          accent: '#ff6b35'
        }
      },
      {
        id: 'sunset-warm',
        name: 'Sunset Warm',
        type: 'dark',
        colors: {
          background: '#2d1b2e',
          surface: '#3e2a3f',
          primary: '#ff6b9d',
          text: '#f7d794',
          accent: '#f38181'
        }
      }
    ];

    for (const theme of themes) {
      await this.api.themes.register(theme.id, {
        name: theme.name,
        type: theme.type,
        styles: this.generateThemeCSS(theme)
      });
    }
  }

  generateThemeCSS(theme) {
    return `
      :root {
        --bg-primary: ${theme.colors.background};
        --bg-secondary: ${theme.colors.surface};
        --color-primary: ${theme.colors.primary};
        --color-text: ${theme.colors.text};
        --color-accent: ${theme.colors.accent};
      }

      .editor {
        background-color: var(--bg-primary);
        color: var(--color-text);
      }

      .toolbar {
        background-color: var(--bg-secondary);
        border-bottom: 1px solid var(--color-primary);
      }

      .button {
        background-color: var(--color-primary);
        color: var(--bg-primary);
        border: none;
        border-radius: 4px;
        padding: 8px 16px;
      }

      .button:hover {
        background-color: var(--color-accent);
      }

      .code-block {
        background-color: var(--bg-secondary);
        border-left: 3px solid var(--color-primary);
        padding: 12px;
        margin: 16px 0;
      }

      .heading {
        color: var(--color-primary);
        border-bottom: 2px solid var(--color-accent);
      }

      .link {
        color: var(--color-accent);
        text-decoration: none;
      }

      .link:hover {
        text-decoration: underline;
      }
    `;
  }

  async showThemeSelector() {
    const availableThemes = await this.api.themes.getAvailable();
    const currentTheme = await this.api.themes.getCurrent();
    
    const selected = await this.api.ui.showQuickPick({
      title: 'Select Theme',
      items: availableThemes.map(theme => ({
        id: theme.id,
        title: theme.name,
        description: theme.type,
        selected: theme.id === currentTheme.id
      }))
    });

    if (selected) {
      await this.api.themes.apply(selected.id);
      await this.api.ui.showNotification(
        `Theme changed to ${selected.title}`,
        'success'
      );
    }
  }
}
```

### 3. 文件系统集成

```javascript
// 文件系统插件示例
class FileSystemPlugin {
  async activate(context) {
    this.api = context.api;
    
    // 注册文件操作命令
    await this.registerFileCommands();
    
    // 监听文件事件
    this.setupFileWatchers();
  }

  async registerFileCommands() {
    const commands = [
      {
        id: 'fs.importFiles',
        title: 'Import Multiple Files',
        handler: () => this.importMultipleFiles()
      },
      {
        id: 'fs.exportToFormats',
        title: 'Export to Multiple Formats',
        handler: () => this.exportToMultipleFormats()
      },
      {
        id: 'fs.createTemplate',
        title: 'Create Template from Current',
        handler: () => this.createTemplate()
      },
      {
        id: 'fs.projectManager',
        title: 'Project Manager',
        handler: () => this.openProjectManager()
      }
    ];

    for (const cmd of commands) {
      await this.api.ui.registerCommand(cmd.id, cmd.title, cmd.handler);
    }
  }

  async importMultipleFiles() {
    const files = await this.api.fs.showOpenDialog({
      multiple: true,
      filters: [
        { name: 'Text Files', extensions: ['txt', 'md', 'rst'] },
        { name: 'Documents', extensions: ['docx', 'odt', 'pdf'] },
        { name: 'All Files', extensions: ['*'] }
      ]
    });

    if (files && files.length > 0) {
      for (const file of files) {
        await this.importSingleFile(file);
      }
      
      await this.api.ui.showNotification(
        `Imported ${files.length} files`,
        'success'
      );
    }
  }

  async importSingleFile(filePath) {
    const content = await this.api.fs.readFile(filePath);
    const fileName = this.getFileName(filePath);
    
    // 根据文件类型转换内容
    let markdownContent = content;
    const extension = this.getFileExtension(filePath);
    
    switch (extension) {
      case 'txt':
        markdownContent = this.convertTextToMarkdown(content);
        break;
      case 'rst':
        markdownContent = this.convertRstToMarkdown(content);
        break;
      case 'html':
        markdownContent = await this.convertHtmlToMarkdown(content);
        break;
    }
    
    // 创建新文档
    await this.api.documents.create({
      title: fileName,
      content: markdownContent
    });
  }

  async exportToMultipleFormats() {
    const formats = await this.api.ui.showCheckboxDialog({
      title: 'Select Export Formats',
      options: [
        { id: 'html', label: 'HTML', checked: true },
        { id: 'pdf', label: 'PDF', checked: true },
        { id: 'docx', label: 'Word Document', checked: false },
        { id: 'epub', label: 'EPUB', checked: false },
        { id: 'latex', label: 'LaTeX', checked: false }
      ]
    });

    if (formats && formats.length > 0) {
      const content = await this.api.editor.getContent();
      const baseName = await this.getExportBaseName();
      
      for (const format of formats) {
        await this.exportToFormat(content, baseName, format);
      }
    }
  }

  async exportToFormat(content, baseName, format) {
    const fileName = `${baseName}.${format}`;
    
    try {
      let exportedContent;
      
      switch (format) {
        case 'html':
          exportedContent = await this.convertToHtml(content);
          break;
        case 'pdf':
          exportedContent = await this.convertToPdf(content);
          break;
        case 'docx':
          exportedContent = await this.convertToDocx(content);
          break;
        case 'epub':
          exportedContent = await this.convertToEpub(content);
          break;
        case 'latex':
          exportedContent = await this.convertToLatex(content);
          break;
      }
      
      const savePath = await this.api.fs.showSaveDialog({
        defaultName: fileName,
        filters: [
          { name: format.toUpperCase(), extensions: [format] }
        ]
      });
      
      if (savePath) {
        await this.api.fs.writeFile(savePath, exportedContent);
      }
    } catch (error) {
      await this.api.ui.showNotification(
        `Failed to export ${format}: ${error.message}`,
        'error'
      );
    }
  }

  async createTemplate() {
    const content = await this.api.editor.getContent();
    
    const templateInfo = await this.api.ui.showInputDialog({
      title: 'Create Template',
      fields: [
        {
          name: 'name',
          label: 'Template Name',
          type: 'text',
          required: true
        },
        {
          name: 'description',
          label: 'Description',
          type: 'textarea'
        },
        {
          name: 'category',
          label: 'Category',
          type: 'select',
          options: ['Document', 'Blog Post', 'Report', 'Letter', 'Other']
        }
      ]
    });

    if (templateInfo) {
      const template = {
        id: this.generateTemplateId(templateInfo.name),
        name: templateInfo.name,
        description: templateInfo.description,
        category: templateInfo.category,
        content: content,
        createdAt: new Date().toISOString()
      };

      await this.saveTemplate(template);
      
      await this.api.ui.showNotification(
        `Template "${templateInfo.name}" created`,
        'success'
      );
    }
  }

  async openProjectManager() {
    const panel = await this.api.ui.createWebView({
      title: 'Project Manager',
      html: await this.generateProjectManagerHTML(),
      width: 600,
      height: 500
    });

    // 设置消息处理
    panel.onMessage(async (message) => {
      switch (message.type) {
        case 'createProject':
          await this.createProject(message.data);
          break;
        case 'openProject':
          await this.openProject(message.data.path);
          break;
        case 'deleteProject':
          await this.deleteProject(message.data.id);
          break;
      }
    });
  }

  setupFileWatchers() {
    // 监听文件变化
    this.api.events.on('file.created', (data) => {
      console.log('File created:', data.path);
    });

    this.api.events.on('file.modified', (data) => {
      console.log('File modified:', data.path);
    });

    this.api.events.on('file.deleted', (data) => {
      console.log('File deleted:', data.path);
    });
  }

  // 工具方法
  getFileName(filePath) {
    return filePath.split('/').pop().split('.')[0];
  }

  getFileExtension(filePath) {
    return filePath.split('.').pop().toLowerCase();
  }

  generateTemplateId(name) {
    return name.toLowerCase().replace(/[^a-z0-9]/g, '-');
  }

  convertTextToMarkdown(text) {
    // 简单的文本到 Markdown 转换
    return text
      .replace(/^(.+)$/gm, '$1\n')  // 确保行结尾
      .replace(/\n\n+/g, '\n\n');  // 清理多余空行
  }

  convertRstToMarkdown(rst) {
    // reStructuredText 到 Markdown 转换
    return rst
      .replace(/^=+$/gm, '') // 移除标题下划线
      .replace(/^-+$/gm, '') // 移除子标题下划线
      .replace(/^\.\. (.+)::$/gm, '<!-- $1 -->') // 转换指令
      .replace(/`([^`]+)`_/g, '[$1]()'); // 转换链接
  }

  // ... 其他转换方法
}
```

## 测试和调试

### 1. 单元测试

```dart
// test/unit/plugin_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:markora_plugin_api/markora_plugin_api.dart';

class MockPluginContext extends Mock implements PluginContext {}
class MockEditorController extends Mock implements EditorController {}

void main() {
  group('MyFirstPlugin', () {
    late MyFirstPlugin plugin;
    late MockPluginContext mockContext;
    late MockEditorController mockEditor;

    setUp(() {
      plugin = MyFirstPlugin();
      mockContext = MockPluginContext();
      mockEditor = MockEditorController();
      
      when(mockContext.editor).thenReturn(mockEditor);
    });

    test('should activate successfully', () async {
      await plugin.activate(mockContext);
      expect(plugin.isActive, isTrue);
    });

    test('should register commands on activation', () async {
      await plugin.activate(mockContext);
      verify(mockContext.commandRegistry.register(
        'myFirstPlugin.hello',
        'Say Hello',
        any,
      )).called(1);
    });

    test('should insert text when hello command is executed', () async {
      await plugin.activate(mockContext);
      
      plugin.sayHello();
      
      verify(mockContext.ui.showNotification(
        'Hello from My First Plugin!',
        NotificationType.info,
      )).called(1);
    });

    test('should deactivate successfully', () async {
      await plugin.activate(mockContext);
      await plugin.deactivate();
      expect(plugin.isActive, isFalse);
    });
  });
}
```

### 2. 集成测试

```javascript
// test/integration/plugin_integration_test.js
describe('Plugin Integration Tests', () => {
  let api;
  let plugin;

  beforeEach(async () => {
    // 设置测试环境
    api = await createTestAPI();
    plugin = new MyFirstPlugin();
  });

  afterEach(async () => {
    // 清理
    if (plugin) {
      await plugin.deactivate();
    }
    await cleanupTestAPI(api);
  });

  test('plugin should integrate with editor', async () => {
    await plugin.activate({ api });
    
    // 模拟编辑器操作
    await api.editor.setContent('Test content');
    const content = await api.editor.getContent();
    
    expect(content).toBe('Test content');
  });

  test('plugin commands should be registered', async () => {
    await plugin.activate({ api });
    
    const commands = await api.ui.getRegisteredCommands();
    expect(commands).toContain('myFirstPlugin.hello');
  });

  test('plugin should handle events correctly', async () => {
    await plugin.activate({ api });
    
    let eventReceived = false;
    api.events.on('test.event', () => {
      eventReceived = true;
    });

    await api.events.emit('test.event', {});
    expect(eventReceived).toBe(true);
  });
});
```

### 3. 调试技巧

```javascript
// 调试工具和技巧
class DebugUtils {
  static enableDebugMode(plugin) {
    // 拦截所有 API 调用
    const originalAPI = plugin.api;
    plugin.api = new Proxy(originalAPI, {
      get(target, prop) {
        const value = target[prop];
        if (typeof value === 'function') {
          return function(...args) {
            console.log(`API Call: ${prop}`, args);
            const result = value.apply(target, args);
            console.log(`API Result: ${prop}`, result);
            return result;
          };
        }
        return value;
      }
    });
  }

  static logPluginState(plugin) {
    console.log('Plugin State:', {
      id: plugin.constructor.name,
      isActive: plugin.isActive,
      registeredCommands: plugin.commands || [],
      eventListeners: plugin.listeners || [],
      storageKeys: plugin.storageKeys || []
    });
  }

  static async measurePerformance(fn, label) {
    const start = performance.now();
    const result = await fn();
    const end = performance.now();
    console.log(`${label}: ${end - start}ms`);
    return result;
  }

  static createErrorBoundary(plugin) {
    const originalMethods = {};
    
    // 包装所有方法以捕获错误
    Object.getOwnPropertyNames(Object.getPrototypeOf(plugin))
      .filter(name => typeof plugin[name] === 'function')
      .forEach(name => {
        originalMethods[name] = plugin[name];
        plugin[name] = async function(...args) {
          try {
            return await originalMethods[name].apply(this, args);
          } catch (error) {
            console.error(`Error in ${name}:`, error);
            if (this.api && this.api.ui) {
              await this.api.ui.showNotification(
                `Plugin error in ${name}: ${error.message}`,
                'error'
              );
            }
            throw error;
          }
        };
      });
  }
}

// 使用调试工具
class DebuggablePlugin {
  async activate(context) {
    this.api = context.api;
    
    // 在开发模式下启用调试
    if (process.env.NODE_ENV === 'development') {
      DebugUtils.enableDebugMode(this);
      DebugUtils.createErrorBoundary(this);
    }
    
    // 性能监控
    await DebugUtils.measurePerformance(
      () => this.initializePlugin(),
      'Plugin Initialization'
    );
  }

  async initializePlugin() {
    // 插件初始化逻辑
    await this.registerCommands();
    await this.setupEventListeners();
    await this.loadSettings();
  }
}
```

## 发布和分发

### 1. 构建插件

```bash
# 使用 Markora CLI 构建
markora plugin build

# 或手动构建过程
flutter packages pub run build_runner build  # Dart 插件
npm run build                                 # JavaScript 插件

# 打包为 MXT 文件
markora plugin package

# 验证插件包
markora plugin validate my-plugin-v1.0.0.mxt

# 测试插件
markora plugin test my-plugin-v1.0.0.mxt
```

### 2. 插件清单完善

```json
{
  "apiVersion": "3.0.0",
  "kind": "Plugin",
  "metadata": {
    "id": "com.yourname.plugin-name",
    "name": "Your Plugin Name",
    "version": "1.0.0",
    "description": "Detailed description of your plugin",
    "author": "Your Name",
    "email": "your.email@example.com",
    "license": "MIT",
    "homepage": "https://github.com/yourname/plugin-name",
    "repository": "https://github.com/yourname/plugin-name",
    "keywords": ["markdown", "editor", "productivity"],
    "categories": ["editor", "utility"]
  },
  "spec": {
    "type": "hybrid",
    "category": "editor",
    "platforms": {
      "windows": { "supported": true },
      "macos": { "supported": true },
      "linux": { "supported": true },
      "web": { "supported": true }
    },
    "activationEvents": [
      "onStartup",
      "onCommand:yourplugin.activate"
    ],
    "contributes": {
      "commands": [
        {
          "id": "yourplugin.mainCommand",
          "title": "Your Plugin: Main Command",
          "category": "Your Plugin"
        }
      ]
    }
  }
}
```

### 3. 发布到插件市场

```bash
# 登录到插件市场
markora auth login

# 发布插件
markora plugin publish my-plugin-v1.0.0.mxt

# 更新插件信息
markora plugin update-info --id com.yourname.plugin-name

# 查看发布状态
markora plugin status com.yourname.plugin-name
```

## 最佳实践

### 1. 代码组织

- 保持插件功能单一且专注
- 使用清晰的命名约定
- 模块化代码结构
- 提供完整的错误处理

### 2. 性能优化

- 懒加载非必需资源
- 使用缓存减少重复计算
- 避免阻塞主线程
- 及时清理资源

### 3. 用户体验

- 提供清晰的用户界面
- 添加合适的提示和帮助
- 支持键盘快捷键
- 响应式设计

### 4. 兼容性

- 明确声明平台支持
- 处理 API 版本差异
- 提供降级方案
- 测试多平台兼容性

这个开发指南为插件开发者提供了从基础到高级的完整知识体系，帮助创建高质量的 Markora 插件。