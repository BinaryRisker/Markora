# Mermaid 插件增强实施方案

## 概述

基于新的插件系统架构，将现有的 Mermaid 插件重构为完全独立的 MXT 包，实现完整的图表预览功能和用户交互体验。

## 当前状态分析

### 现有功能
- ✅ 基础的 Mermaid 代码块插入
- ✅ 插件注册和激活机制
- ❌ Mermaid 图表预览渲染
- ❌ 图表类型选择
- ❌ 实时预览更新
- ❌ 图表导出功能

### 目标功能
1. **完整图表渲染**: 支持所有 Mermaid 图表类型的实时渲染
2. **交互式编辑**: 图表代码和预览的双向同步
3. **模板系统**: 提供常用图表模板
4. **导出功能**: 支持 SVG、PNG 格式导出
5. **主题支持**: 适配 Markora 主题系统

## 重构架构设计

### 1. 插件结构

```
mermaid_plugin_v3.0.0.mxt
├── manifest.json              # 插件清单
├── main.js                    # JavaScript 主入口
├── main.dart                  # Dart 渲染器 (可选)
├── assets/                    # 静态资源
│   ├── icons/
│   │   ├── mermaid-icon.svg
│   │   ├── flowchart.svg
│   │   ├── sequence.svg
│   │   └── gantt.svg
│   ├── templates/             # 图表模板
│   │   ├── flowchart.mmd
│   │   ├── sequence.mmd
│   │   ├── class.mmd
│   │   ├── gantt.mmd
│   │   └── pie.mmd
│   └── themes/                # 主题文件
│       ├── markora-light.json
│       └── markora-dark.json
├── webview/                   # WebView 渲染器
│   ├── index.html
│   ├── mermaid-renderer.js
│   ├── styles.css
│   └── themes.css
├── locales/                   # 国际化
│   ├── en.json
│   └── zh.json
└── docs/
    └── README.md
```

### 2. 插件清单更新

```json
{
  "apiVersion": "3.0.0",
  "kind": "Plugin",
  "metadata": {
    "id": "com.markora.mermaid",
    "name": "Mermaid Diagrams",
    "displayName": "Mermaid 图表",
    "version": "3.0.0",
    "description": "Create beautiful diagrams and flowcharts using Mermaid syntax",
    "author": "Markora Team",
    "license": "MIT",
    "homepage": "https://markora.dev/plugins/mermaid",
    "repository": "https://github.com/markora/mermaid-plugin",
    "keywords": ["diagram", "flowchart", "sequence", "gantt", "visualization"],
    "icon": "assets/icons/mermaid-icon.svg",
    "category": "renderer"
  },
  "spec": {
    "type": "hybrid",
    "platforms": {
      "windows": { "supported": true },
      "macos": { "supported": true },
      "linux": { "supported": true },
      "web": { "supported": true },
      "android": { "supported": false, "reason": "WebView performance limitations" },
      "ios": { "supported": false, "reason": "WebView performance limitations" }
    },
    "entryPoints": {
      "javascript": "main.js",
      "dart": "main.dart"
    },
    "permissions": [
      "editor.read",
      "editor.write",
      "ui.toolbar",
      "ui.menu",
      "ui.webview",
      "storage.local",
      "filesystem.read",
      "filesystem.write"
    ],
    "dependencies": {
      "core": ">=3.0.0",
      "plugins": {
        "markdown-renderer": ">=2.0.0"
      }
    },
    "activationEvents": [
      "onLanguage:mermaid",
      "onCommand:mermaid.insert",
      "onCommand:mermaid.preview",
      "onStartup"
    ],
    "contributes": {
      "commands": [
        {
          "id": "mermaid.insert",
          "title": "Insert Mermaid Diagram",
          "category": "Mermaid",
          "description": "Insert a new Mermaid diagram"
        },
        {
          "id": "mermaid.insertTemplate",
          "title": "Insert from Template",
          "category": "Mermaid",
          "description": "Insert a Mermaid diagram from template"
        },
        {
          "id": "mermaid.preview",
          "title": "Preview Diagram",
          "category": "Mermaid",
          "description": "Preview the current Mermaid diagram"
        },
        {
          "id": "mermaid.export",
          "title": "Export Diagram",
          "category": "Mermaid",
          "description": "Export diagram as image"
        }
      ],
      "toolbar": [
        {
          "id": "mermaid.toolbar",
          "group": "editor",
          "priority": 150,
          "items": [
            {
              "command": "mermaid.insert",
              "icon": "assets/icons/mermaid-icon.svg",
              "tooltip": "Insert Mermaid Diagram"
            },
            {
              "command": "mermaid.insertTemplate",
              "icon": "assets/icons/flowchart.svg",
              "tooltip": "Insert from Template"
            }
          ]
        }
      ],
      "menus": {
        "editor/context": [
          {
            "command": "mermaid.preview",
            "when": "editorLangId == mermaid",
            "group": "mermaid@1"
          },
          {
            "command": "mermaid.export",
            "when": "editorLangId == mermaid",
            "group": "mermaid@2"
          }
        ],
        "editor/insert": [
          {
            "command": "mermaid.insert",
            "group": "diagrams@1"
          },
          {
            "command": "mermaid.insertTemplate",
            "group": "diagrams@2"
          }
        ]
      },
      "languages": [
        {
          "id": "mermaid",
          "aliases": ["Mermaid", "mermaid"],
          "extensions": [".mmd", ".mermaid"],
          "configuration": "language-configuration.json"
        }
      ],
      "renderers": [
        {
          "id": "mermaid-renderer",
          "displayName": "Mermaid Renderer",
          "languages": ["mermaid"],
          "entrypoint": "webview/index.html"
        }
      ]
    },
    "configuration": {
      "title": "Mermaid Settings",
      "properties": {
        "mermaid.theme": {
          "type": "string",
          "default": "auto",
          "enum": ["auto", "default", "dark", "forest", "neutral"],
          "enumDescriptions": [
            "Auto-detect from editor theme",
            "Default Mermaid theme",
            "Dark theme",
            "Forest theme",
            "Neutral theme"
          ],
          "description": "Mermaid diagram theme"
        },
        "mermaid.enableInteraction": {
          "type": "boolean",
          "default": true,
          "description": "Enable diagram interaction and zoom"
        },
        "mermaid.autoPreview": {
          "type": "boolean",
          "default": false,
          "description": "Automatically preview diagrams while editing"
        },
        "mermaid.maxTextSize": {
          "type": "integer",
          "default": 50000,
          "minimum": 1000,
          "maximum": 200000,
          "description": "Maximum text size for diagram rendering"
        },
        "mermaid.exportFormat": {
          "type": "string",
          "default": "svg",
          "enum": ["svg", "png"],
          "description": "Default export format"
        }
      }
    }
  }
}
```

### 3. JavaScript 主实现

```javascript
// main.js
class MermaidPlugin {
  constructor() {
    this.isActive = false;
    this.renderers = new Map();
    this.templates = new Map();
    this.config = {};
  }

  async activate(context) {
    this.api = context.api;
    this.pluginId = context.pluginId;
    this.isActive = true;
    
    console.log('Mermaid plugin activating...');
    
    try {
      // 加载配置
      await this.loadConfiguration();
      
      // 加载模板
      await this.loadTemplates();
      
      // 注册命令
      await this.registerCommands();
      
      // 注册渲染器
      await this.registerRenderer();
      
      // 设置事件监听
      this.setupEventListeners();
      
      console.log('Mermaid plugin activated successfully');
    } catch (error) {
      console.error('Failed to activate Mermaid plugin:', error);
      throw error;
    }
  }

  async deactivate() {
    console.log('Mermaid plugin deactivating...');
    
    // 清理渲染器
    for (const [id, renderer] of this.renderers) {
      renderer.destroy();
    }
    this.renderers.clear();
    
    this.isActive = false;
  }

  async loadConfiguration() {
    this.config = {
      theme: await this.api.storage.get('mermaid.theme') || 'auto',
      enableInteraction: await this.api.storage.get('mermaid.enableInteraction') ?? true,
      autoPreview: await this.api.storage.get('mermaid.autoPreview') ?? false,
      maxTextSize: await this.api.storage.get('mermaid.maxTextSize') || 50000,
      exportFormat: await this.api.storage.get('mermaid.exportFormat') || 'svg'
    };
  }

  async loadTemplates() {
    const templateFiles = [
      'flowchart.mmd',
      'sequence.mmd',
      'class.mmd',
      'gantt.mmd',
      'pie.mmd',
      'state.mmd',
      'journey.mmd',
      'git.mmd'
    ];

    for (const file of templateFiles) {
      try {
        const content = await this.api.fs.readFile(`assets/templates/${file}`);
        const name = file.replace('.mmd', '');
        this.templates.set(name, {
          name: this.formatTemplateName(name),
          content: content.trim(),
          description: await this.getTemplateDescription(name)
        });
      } catch (error) {
        console.warn(`Failed to load template ${file}:`, error);
      }
    }
  }

  formatTemplateName(name) {
    return name.charAt(0).toUpperCase() + name.slice(1) + ' Diagram';
  }

  async getTemplateDescription(name) {
    const descriptions = {
      flowchart: 'A flowchart showing process flow and decision points',
      sequence: 'A sequence diagram showing interactions between entities',
      class: 'A class diagram showing object-oriented relationships',
      gantt: 'A Gantt chart for project timeline visualization',
      pie: 'A pie chart for displaying proportional data',
      state: 'A state diagram showing system states and transitions',
      journey: 'A user journey map showing user experience flow',
      git: 'A Git workflow diagram showing branch operations'
    };
    return descriptions[name] || `A ${name} diagram template`;
  }

  async registerCommands() {
    // 插入 Mermaid 图表
    await this.api.ui.registerCommand(
      'mermaid.insert',
      'Insert Mermaid Diagram',
      () => this.insertDiagram()
    );

    // 从模板插入
    await this.api.ui.registerCommand(
      'mermaid.insertTemplate',
      'Insert from Template',
      () => this.insertFromTemplate()
    );

    // 预览图表
    await this.api.ui.registerCommand(
      'mermaid.preview',
      'Preview Diagram',
      () => this.previewDiagram()
    );

    // 导出图表
    await this.api.ui.registerCommand(
      'mermaid.export',
      'Export Diagram',
      () => this.exportDiagram()
    );
  }

  async registerRenderer() {
    await this.api.renderers.register('mermaid', (content, element) => {
      return this.renderMermaidDiagram(content, element);
    });
  }

  setupEventListeners() {
    // 监听编辑器内容变化
    this.api.events.on('editor.contentChanged', (data) => {
      if (this.config.autoPreview) {
        this.updatePreview(data.content);
      }
    });

    // 监听主题变化
    this.api.events.on('theme.changed', (theme) => {
      this.updateTheme(theme);
    });

    // 监听配置变化
    this.api.events.on('settings.changed', (settings) => {
      if (settings.key.startsWith('mermaid.')) {
        this.updateConfig(settings.key, settings.value);
      }
    });
  }

  async insertDiagram() {
    const diagramTypes = [
      { label: 'Flowchart', value: 'flowchart', description: 'Process flow diagram' },
      { label: 'Sequence Diagram', value: 'sequence', description: 'Interaction timeline' },
      { label: 'Class Diagram', value: 'class', description: 'Object relationships' },
      { label: 'State Diagram', value: 'state', description: 'State transitions' },
      { label: 'Gantt Chart', value: 'gantt', description: 'Project timeline' },
      { label: 'Pie Chart', value: 'pie', description: 'Proportional data' },
      { label: 'User Journey', value: 'journey', description: 'User experience flow' },
      { label: 'Git Graph', value: 'git', description: 'Version control flow' }
    ];

    const selectedType = await this.api.ui.showQuickPick({
      items: diagramTypes,
      placeholder: 'Select diagram type',
      title: 'Insert Mermaid Diagram'
    });

    if (selectedType) {
      const template = this.getBasicTemplate(selectedType.value);
      await this.api.editor.insertText(template);
      
      // 自动打开预览
      if (this.config.autoPreview) {
        setTimeout(() => this.previewDiagram(), 500);
      }
    }
  }

  getBasicTemplate(type) {
    const templates = {
      flowchart: '```mermaid\nflowchart TD\n    A[Start] --> B{Decision}\n    B -->|Yes| C[Action 1]\n    B -->|No| D[Action 2]\n    C --> E[End]\n    D --> E\n```',
      sequence: '```mermaid\nsequenceDiagram\n    participant A as Alice\n    participant B as Bob\n    A->>B: Hello Bob, how are you?\n    B-->>A: Great! How about you?\n    A->>B: I\'m good, thanks!\n```',
      class: '```mermaid\nclassDiagram\n    class Animal {\n        +String name\n        +int age\n        +eat()\n        +sleep()\n    }\n    class Dog {\n        +bark()\n    }\n    Animal <|-- Dog\n```',
      state: '```mermaid\nstateDiagram-v2\n    [*] --> Still\n    Still --> [*]\n    Still --> Moving\n    Moving --> Still\n    Moving --> Crash\n    Crash --> [*]\n```',
      gantt: '```mermaid\ngantt\n    title Project Timeline\n    dateFormat YYYY-MM-DD\n    section Phase 1\n    Task 1: 2024-01-01, 7d\n    Task 2: 2024-01-08, 5d\n    section Phase 2\n    Task 3: 2024-01-15, 10d\n```',
      pie: '```mermaid\npie title Survey Results\n    "Satisfied" : 75\n    "Neutral" : 15\n    "Dissatisfied" : 10\n```',
      journey: '```mermaid\njourney\n    title User Journey\n    section Discovery\n      Find website: 5: User\n      Browse products: 4: User\n    section Purchase\n      Add to cart: 3: User\n      Checkout: 2: User\n      Payment: 1: User\n```',
      git: '```mermaid\ngitgraph\n    commit\n    branch develop\n    checkout develop\n    commit\n    commit\n    checkout main\n    merge develop\n    commit\n```'
    };

    return templates[type] || templates.flowchart;
  }

  async insertFromTemplate() {
    const templateItems = Array.from(this.templates.entries()).map(([key, template]) => ({
      label: template.name,
      value: key,
      description: template.description
    }));

    const selected = await this.api.ui.showQuickPick({
      items: templateItems,
      placeholder: 'Select a template',
      title: 'Mermaid Templates'
    });

    if (selected) {
      const template = this.templates.get(selected.value);
      const wrappedContent = `\`\`\`mermaid\n${template.content}\n\`\`\``;
      await this.api.editor.insertText(wrappedContent);
    }
  }

  async previewDiagram() {
    const content = await this.api.editor.getContent();
    const mermaidBlocks = this.extractMermaidBlocks(content);

    if (mermaidBlocks.length === 0) {
      await this.api.ui.showNotification('No Mermaid diagrams found in the current document', 'warning');
      return;
    }

    // 如果只有一个图表，直接预览
    if (mermaidBlocks.length === 1) {
      await this.showPreview(mermaidBlocks[0]);
      return;
    }

    // 多个图表，让用户选择
    const blockItems = mermaidBlocks.map((block, index) => ({
      label: `Diagram ${index + 1}`,
      value: index,
      description: this.getDiagramType(block.content)
    }));

    const selected = await this.api.ui.showQuickPick({
      items: blockItems,
      placeholder: 'Select diagram to preview',
      title: 'Multiple Diagrams Found'
    });

    if (selected !== undefined) {
      await this.showPreview(mermaidBlocks[selected.value]);
    }
  }

  extractMermaidBlocks(content) {
    const regex = /```mermaid\n([\s\S]*?)\n```/g;
    const blocks = [];
    let match;

    while ((match = regex.exec(content)) !== null) {
      blocks.push({
        content: match[1].trim(),
        fullMatch: match[0],
        startIndex: match.index,
        endIndex: match.index + match[0].length
      });
    }

    return blocks;
  }

  getDiagramType(content) {
    const lines = content.split('\n');
    const firstLine = lines[0].trim().toLowerCase();
    
    if (firstLine.includes('flowchart') || firstLine.includes('graph')) return 'Flowchart';
    if (firstLine.includes('sequencediagram')) return 'Sequence Diagram';
    if (firstLine.includes('classdiagram')) return 'Class Diagram';
    if (firstLine.includes('statediagram')) return 'State Diagram';
    if (firstLine.includes('gantt')) return 'Gantt Chart';
    if (firstLine.includes('pie')) return 'Pie Chart';
    if (firstLine.includes('journey')) return 'User Journey';
    if (firstLine.includes('gitgraph')) return 'Git Graph';
    
    return 'Mermaid Diagram';
  }

  async showPreview(block) {
    const webview = await this.api.ui.createWebView({
      id: 'mermaid.preview',
      title: 'Mermaid Preview',
      html: this.generatePreviewHTML(block.content),
      enableScripts: true,
      retainContextWhenHidden: true,
      width: '80%',
      height: '70%'
    });

    // 处理 WebView 消息
    webview.onMessage((message) => {
      this.handlePreviewMessage(message, block);
    });

    this.currentPreviewWebView = webview;
  }

  generatePreviewHTML(mermaidContent) {
    const theme = this.getEffectiveTheme();
    
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Mermaid Preview</title>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
        <style>
          body {
            margin: 0;
            padding: 20px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--bg-color, #ffffff);
            color: var(--text-color, #000000);
          }
          
          .container {
            max-width: 100%;
            margin: 0 auto;
            text-align: center;
          }
          
          .mermaid-container {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin: 20px 0;
            overflow: auto;
          }
          
          .toolbar {
            margin-bottom: 20px;
            display: flex;
            justify-content: center;
            gap: 10px;
          }
          
          .btn {
            padding: 8px 16px;
            background: #007acc;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
          }
          
          .btn:hover {
            background: #005a9e;
          }
          
          .error {
            color: #d73a49;
            background: #ffeaea;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
          }
          
          .loading {
            padding: 40px;
            color: #666;
          }
          
          @media (prefers-color-scheme: dark) {
            body {
              --bg-color: #1e1e1e;
              --text-color: #cccccc;
            }
            .mermaid-container {
              background: #252526;
            }
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="toolbar">
            <button class="btn" onclick="exportSVG()">Export SVG</button>
            <button class="btn" onclick="exportPNG()">Export PNG</button>
            <button class="btn" onclick="refreshDiagram()">Refresh</button>
          </div>
          
          <div class="mermaid-container">
            <div class="loading">Rendering diagram...</div>
            <div id="mermaid-diagram" style="display: none;"></div>
            <div id="error-container" style="display: none;" class="error"></div>
          </div>
        </div>

        <script>
          // 配置 Mermaid
          mermaid.initialize({
            startOnLoad: false,
            theme: '${theme}',
            securityLevel: 'loose',
            flowchart: {
              useMaxWidth: true,
              htmlLabels: true
            },
            sequence: {
              useMaxWidth: true
            },
            gantt: {
              useMaxWidth: true
            }
          });

          // 渲染图表
          function renderDiagram() {
            const diagramContainer = document.getElementById('mermaid-diagram');
            const errorContainer = document.getElementById('error-container');
            const loadingDiv = document.querySelector('.loading');
            
            const mermaidContent = \`${mermaidContent.replace(/`/g, '\\`')}\`;
            
            try {
              // 清除之前的内容
              diagramContainer.innerHTML = '';
              errorContainer.style.display = 'none';
              diagramContainer.style.display = 'none';
              loadingDiv.style.display = 'block';
              
              // 渲染新图表
              mermaid.render('mermaid-svg', mermaidContent).then(({ svg }) => {
                diagramContainer.innerHTML = svg;
                diagramContainer.style.display = 'block';
                loadingDiv.style.display = 'none';
                
                // 发送渲染完成消息
                window.postMessage({ type: 'renderComplete' });
              }).catch(error => {
                showError(error.message);
              });
              
            } catch (error) {
              showError(error.message);
            }
          }
          
          function showError(message) {
            const errorContainer = document.getElementById('error-container');
            const loadingDiv = document.querySelector('.loading');
            const diagramContainer = document.getElementById('mermaid-diagram');
            
            errorContainer.textContent = 'Error rendering diagram: ' + message;
            errorContainer.style.display = 'block';
            loadingDiv.style.display = 'none';
            diagramContainer.style.display = 'none';
          }
          
          function exportSVG() {
            const svgElement = document.querySelector('#mermaid-diagram svg');
            if (svgElement) {
              const svgData = new XMLSerializer().serializeToString(svgElement);
              window.postMessage({
                type: 'export',
                format: 'svg',
                data: svgData
              });
            }
          }
          
          function exportPNG() {
            const svgElement = document.querySelector('#mermaid-diagram svg');
            if (svgElement) {
              const canvas = document.createElement('canvas');
              const ctx = canvas.getContext('2d');
              const svgData = new XMLSerializer().serializeToString(svgElement);
              const img = new Image();
              
              img.onload = function() {
                canvas.width = img.width;
                canvas.height = img.height;
                ctx.fillStyle = 'white';
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                ctx.drawImage(img, 0, 0);
                
                const pngData = canvas.toDataURL('image/png');
                window.postMessage({
                  type: 'export',
                  format: 'png',
                  data: pngData
                });
              };
              
              img.src = 'data:image/svg+xml;base64,' + btoa(svgData);
            }
          }
          
          function refreshDiagram() {
            renderDiagram();
          }
          
          // 初始渲染
          document.addEventListener('DOMContentLoaded', renderDiagram);
        </script>
      </body>
      </html>
    `;
  }

  getEffectiveTheme() {
    if (this.config.theme === 'auto') {
      // 根据编辑器主题自动选择
      return this.api.theme.isDark() ? 'dark' : 'default';
    }
    return this.config.theme;
  }

  async handlePreviewMessage(message, block) {
    switch (message.type) {
      case 'export':
        await this.handleExport(message, block);
        break;
      case 'renderComplete':
        console.log('Mermaid diagram rendered successfully');
        break;
      case 'error':
        console.error('Mermaid rendering error:', message.error);
        await this.api.ui.showNotification(`Diagram error: ${message.error}`, 'error');
        break;
    }
  }

  async handleExport(message, block) {
    const defaultName = `mermaid-diagram.${message.format}`;
    
    const savePath = await this.api.fs.showSaveDialog({
      title: `Export ${message.format.toUpperCase()}`,
      defaultName: defaultName,
      filters: [
        { 
          name: message.format.toUpperCase(), 
          extensions: [message.format] 
        }
      ]
    });

    if (savePath) {
      try {
        if (message.format === 'svg') {
          await this.api.fs.writeFile(savePath, message.data);
        } else if (message.format === 'png') {
          // 将 base64 转换为二进制数据
          const base64Data = message.data.split(',')[1];
          const binaryData = atob(base64Data);
          const bytes = new Uint8Array(binaryData.length);
          for (let i = 0; i < binaryData.length; i++) {
            bytes[i] = binaryData.charCodeAt(i);
          }
          await this.api.fs.writeBytes(savePath, bytes);
        }
        
        await this.api.ui.showNotification(
          `Diagram exported to ${savePath}`,
          'success'
        );
      } catch (error) {
        await this.api.ui.showNotification(
          `Export failed: ${error.message}`,
          'error'
        );
      }
    }
  }

  async exportDiagram() {
    // 检查当前是否有活动的预览窗口
    if (this.currentPreviewWebView) {
      await this.currentPreviewWebView.postMessage({ type: 'requestExport' });
    } else {
      await this.api.ui.showNotification(
        'Please open diagram preview first',
        'warning'
      );
    }
  }

  async renderMermaidDiagram(content, element) {
    // 在 Markdown 预览中渲染 Mermaid 图表
    const rendererId = `mermaid-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    const renderer = await this.api.ui.createWebView({
      id: rendererId,
      html: this.generateInlineHTML(content),
      enableScripts: true,
      parent: element,
      seamless: true
    });

    this.renderers.set(rendererId, renderer);
    
    return renderer.element;
  }

  generateInlineHTML(content) {
    const theme = this.getEffectiveTheme();
    
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
        <style>
          body { 
            margin: 0; 
            padding: 10px; 
            background: transparent;
            overflow: hidden;
          }
          .mermaid { 
            text-align: center; 
            max-width: 100%;
          }
        </style>
      </head>
      <body>
        <div class="mermaid">${content}</div>
        <script>
          mermaid.initialize({
            startOnLoad: true,
            theme: '${theme}',
            securityLevel: 'loose'
          });
        </script>
      </body>
      </html>
    `;
  }

  updatePreview(content) {
    // 实时预览更新逻辑
    if (this.currentPreviewWebView) {
      const mermaidBlocks = this.extractMermaidBlocks(content);
      if (mermaidBlocks.length > 0) {
        this.currentPreviewWebView.postMessage({
          type: 'updateContent',
          content: mermaidBlocks[0].content
        });
      }
    }
  }

  updateTheme(theme) {
    // 更新所有渲染器的主题
    for (const [id, renderer] of this.renderers) {
      renderer.postMessage({
        type: 'updateTheme',
        theme: this.getEffectiveTheme()
      });
    }
  }

  async updateConfig(key, value) {
    const configKey = key.replace('mermaid.', '');
    this.config[configKey] = value;
    await this.api.storage.set(key, value);
    
    // 应用配置更改
    if (configKey === 'theme') {
      this.updateTheme(value);
    }
  }
}

// 插件入口点
function activate(context) {
  const plugin = new MermaidPlugin();
  plugin.activate(context);
  return plugin;
}

function deactivate() {
  // 全局清理
}

// CommonJS/ES Module 兼容性
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { activate, deactivate };
}
```

### 4. 图表模板文件

```mermaid
# assets/templates/flowchart.mmd
flowchart TD
    Start([开始]) --> Input[获取输入]
    Input --> Process{处理数据}
    Process -->|成功| Success[显示结果]
    Process -->|失败| Error[显示错误]
    Success --> End([结束])
    Error --> End
    
    classDef startEnd fill:#e1f5fe
    classDef process fill:#f3e5f5
    classDef decision fill:#fff3e0
    classDef success fill:#e8f5e8
    classDef error fill:#ffebee
    
    class Start,End startEnd
    class Input,Success process
    class Process decision
    class Error error
```

```mermaid
# assets/templates/sequence.mmd
sequenceDiagram
    participant User as 用户
    participant Client as 客户端
    participant Server as 服务器
    participant DB as 数据库
    
    User->>+Client: 发起请求
    Client->>+Server: API 调用
    Server->>+DB: 查询数据
    DB-->>-Server: 返回数据
    Server-->>-Client: 响应结果
    Client-->>-User: 显示内容
    
    Note over User,DB: 完整的请求响应流程
    
    alt 成功情况
        Server->>Client: 200 OK
    else 错误情况
        Server->>Client: 500 Error
        Client->>User: 显示错误信息
    end
```

### 5. 国际化文件

```json
// locales/zh.json
{
  "commands": {
    "insert": "插入 Mermaid 图表",
    "insertTemplate": "从模板插入",
    "preview": "预览图表",
    "export": "导出图表"
  },
  "templates": {
    "flowchart": "流程图",
    "sequence": "时序图",
    "class": "类图",
    "state": "状态图",
    "gantt": "甘特图",
    "pie": "饼图",
    "journey": "用户旅程图",
    "git": "Git 流程图"
  },
  "messages": {
    "nodiagram": "当前文档中未找到 Mermaid 图表",
    "exportSuccess": "图表已导出到 {path}",
    "exportFailed": "导出失败：{error}",
    "renderError": "图表渲染出错：{error}"
  },
  "settings": {
    "theme": "图表主题",
    "enableInteraction": "启用图表交互",
    "autoPreview": "自动预览",
    "exportFormat": "默认导出格式"
  }
}
```

### 6. 语言配置

```json
// language-configuration.json
{
  "comments": {
    "lineComment": "%%"
  },
  "brackets": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"]
  ],
  "autoClosingPairs": [
    { "open": "{", "close": "}" },
    { "open": "[", "close": "]" },
    { "open": "(", "close": ")" },
    { "open": "\"", "close": "\"" }
  ],
  "surroundingPairs": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"],
    ["\"", "\""]
  ],
  "wordPattern": "(-?\\d*\\.\\d\\w*)|([^\\s\\[\\]{}()\"']+)"
}
```

## 实施步骤

### 第一阶段：基础重构 (1 周)
1. ✅ 更新插件清单文件
2. ✅ 重构 JavaScript 主实现
3. ✅ 实现基础命令注册
4. ✅ 添加图表模板系统

### 第二阶段：渲染引擎 (1 周)  
1. ✅ 实现 WebView 渲染器
2. ✅ 添加主题支持
3. ✅ 实现错误处理
4. ✅ 添加交互功能

### 第三阶段：高级功能 (1 周)
1. 🔄 实现实时预览
2. 🔄 添加导出功能
3. 🔄 完善配置系统
4. 🔄 添加国际化支持

### 第四阶段：优化和测试 (3 天)
1. ⏳ 性能优化
2. ⏳ 用户体验改进
3. ⏳ 全面测试
4. ⏳ 文档完善

## 技术亮点

1. **完全解耦**: 与主程序零依赖，独立的 MXT 包
2. **实时渲染**: 支持图表的实时预览和更新
3. **主题适配**: 自动适配 Markora 的主题系统
4. **模板系统**: 丰富的预制图表模板
5. **多格式导出**: 支持 SVG 和 PNG 格式导出
6. **错误处理**: 完善的错误提示和调试支持
7. **性能优化**: 缓存和懒加载机制
8. **国际化**: 完整的多语言支持

## 用户体验改进

1. **直观的操作**: 一键插入和预览
2. **丰富的模板**: 覆盖常用图表类型
3. **实时反馈**: 编辑时的即时预览
4. **灵活导出**: 多种格式和质量选项
5. **主题一致性**: 与编辑器主题保持同步

这个增强版的 Mermaid 插件将为用户提供专业级的图表创作体验，完全符合新插件系统的架构要求。