# Pandoc 通用转换器插件实施方案

## 概述

基于新的插件系统架构，实现一个功能完整的 Pandoc 通用文档转换器插件，支持 Markdown 与多种文档格式之间的双向转换，包括 PDF、DOCX、HTML、LaTeX、EPUB 等格式。

## 功能规划

### 核心功能
1. **格式转换**: 支持 20+ 种文档格式互转
2. **批量处理**: 支持多文件批量转换
3. **模板系统**: 提供预制转换模板
4. **预览功能**: 转换前的格式预览
5. **配置管理**: 灵活的转换参数配置
6. **进度追踪**: 实时显示转换进度

### 支持格式

#### 输入格式
- Markdown (.md, .markdown, .mdown)
- HTML (.html, .htm)
- LaTeX (.tex, .latex)
- reStructuredText (.rst)
- AsciiDoc (.asciidoc, .adoc)
- Textile (.textile)
- MediaWiki (.wiki)
- DokuWiki
- TWiki
- TikiWiki
- Creole
- Haddock markup
- OPML (.opml)
- Word docx (.docx)
- LibreOffice ODT (.odt)
- EPUB (.epub)
- JSON (.json)
- CSV (.csv)

#### 输出格式
- PDF (via LaTeX, wkhtmltopdf, weasyprint)
- HTML (.html)
- DOCX (.docx)
- ODT (.odt)
- RTF (.rtf)
- LaTeX (.tex)
- ConTeXt (.ctx)
- EPUB (.epub)
- EPUB3 (.epub)
- FictionBook2 (.fb2)
- AZW3 (.azw3)
- PowerPoint (.pptx)
- Slidy slides (.html)
- Slideous (.html)
- DZSlides (.html)
- reveal.js (.html)
- S5 (.html)
- Beamer PDF (.pdf)
- GNU Texinfo (.texi)
- Groff man page (.1)
- InDesign ICML (.icml)

## 插件架构设计

### 1. 插件结构

```
pandoc_plugin_v3.0.0.mxt
├── manifest.json              # 插件清单
├── main.js                    # JavaScript 主入口
├── main.dart                  # Dart 服务层
├── assets/                    # 静态资源
│   ├── icons/
│   │   ├── pandoc-icon.svg
│   │   ├── import.svg
│   │   ├── export.svg
│   │   └── convert.svg
│   ├── templates/             # 转换模板
│   │   ├── academic-paper.yaml
│   │   ├── business-report.yaml
│   │   ├── presentation.yaml
│   │   └── ebook.yaml
│   └── pandoc/               # Pandoc 二进制文件
│       ├── windows/
│       │   └── pandoc.exe
│       ├── macos/
│       │   └── pandoc
│       ├── linux/
│       │   └── pandoc
│       └── README.md
├── webview/                  # WebView 界面
│   ├── convert-dialog.html
│   ├── progress-dialog.html
│   ├── preview-panel.html
│   └── styles.css
├── locales/                  # 国际化
│   ├── en.json
│   └── zh.json
├── schemas/                  # 配置架构
│   └── pandoc-options.json
└── docs/
    ├── README.md
    ├── FORMATS.md
    └── EXAMPLES.md
```

### 2. 插件清单

```json
{
  "apiVersion": "3.0.0",
  "kind": "Plugin",
  "metadata": {
    "id": "com.markora.pandoc",
    "name": "Pandoc Universal Converter",
    "displayName": "Pandoc 通用转换器",
    "version": "3.0.0",
    "description": "Universal document converter using Pandoc. Convert between Markdown and 20+ formats including PDF, DOCX, HTML, LaTeX, and more.",
    "author": "Markora Team",
    "license": "MIT",
    "homepage": "https://markora.dev/plugins/pandoc",
    "repository": "https://github.com/markora/pandoc-plugin",
    "keywords": ["pandoc", "converter", "pdf", "docx", "html", "latex", "export", "import"],
    "icon": "assets/icons/pandoc-icon.svg",
    "category": "converter"
  },
  "spec": {
    "type": "hybrid",
    "platforms": {
      "windows": { 
        "supported": true,
        "native": "assets/pandoc/windows/pandoc.exe"
      },
      "macos": { 
        "supported": true,
        "native": "assets/pandoc/macos/pandoc"
      },
      "linux": { 
        "supported": true,
        "native": "assets/pandoc/linux/pandoc"
      },
      "web": { "supported": false, "reason": "Requires local file system access" },
      "android": { "supported": false, "reason": "Pandoc not available" },
      "ios": { "supported": false, "reason": "Pandoc not available" }
    },
    "entryPoints": {
      "javascript": "main.js",
      "dart": "main.dart"
    },
    "permissions": [
      "filesystem.read",
      "filesystem.write",
      "process.spawn",
      "ui.dialogs",
      "ui.notifications",
      "ui.webview",
      "storage.local",
      "network.http"
    ],
    "dependencies": {
      "core": ">=3.0.0",
      "system": {
        "pandoc": ">=2.19.0"
      }
    },
    "activationEvents": [
      "onCommand:pandoc.export",
      "onCommand:pandoc.import",
      "onCommand:pandoc.convert",
      "onFileType:md",
      "onFileType:docx",
      "onFileType:html"
    ],
    "contributes": {
      "commands": [
        {
          "id": "pandoc.export",
          "title": "Export Document",
          "category": "Pandoc",
          "description": "Export current document to various formats"
        },
        {
          "id": "pandoc.import",
          "title": "Import Document", 
          "category": "Pandoc",
          "description": "Import document from various formats"
        },
        {
          "id": "pandoc.convert",
          "title": "Convert Files",
          "category": "Pandoc", 
          "description": "Batch convert multiple files"
        },
        {
          "id": "pandoc.preview",
          "title": "Preview Conversion",
          "category": "Pandoc",
          "description": "Preview conversion result"
        }
      ],
      "toolbar": [
        {
          "id": "pandoc.toolbar",
          "group": "file",
          "priority": 200,
          "items": [
            {
              "command": "pandoc.export",
              "icon": "assets/icons/export.svg",
              "tooltip": "Export Document"
            },
            {
              "command": "pandoc.import",
              "icon": "assets/icons/import.svg", 
              "tooltip": "Import Document"
            }
          ]
        }
      ],
      "menus": {
        "file/export": [
          {
            "command": "pandoc.export",
            "title": "Export with Pandoc...",
            "group": "pandoc@1"
          }
        ],
        "file/import": [
          {
            "command": "pandoc.import",
            "title": "Import with Pandoc...",
            "group": "pandoc@1"
          }
        ],
        "editor/context": [
          {
            "command": "pandoc.export",
            "when": "editorLangId == markdown",
            "group": "export@1"
          },
          {
            "command": "pandoc.preview",
            "when": "editorLangId == markdown", 
            "group": "export@2"
          }
        ]
      },
      "keybindings": [
        {
          "command": "pandoc.export",
          "key": "ctrl+shift+e",
          "mac": "cmd+shift+e",
          "when": "editorTextFocus"
        },
        {
          "command": "pandoc.import",
          "key": "ctrl+shift+i",
          "mac": "cmd+shift+i"
        }
      ]
    },
    "configuration": {
      "title": "Pandoc Settings",
      "properties": {
        "pandoc.executablePath": {
          "type": "string",
          "default": "",
          "description": "Path to Pandoc executable (leave empty to use bundled version)"
        },
        "pandoc.defaultExportFormat": {
          "type": "string",
          "default": "pdf",
          "enum": ["pdf", "html", "docx", "odt", "latex", "epub"],
          "description": "Default export format"
        },
        "pandoc.pdfEngine": {
          "type": "string", 
          "default": "auto",
          "enum": ["auto", "pdflatex", "xelatex", "lualatex", "wkhtmltopdf", "weasyprint"],
          "description": "PDF generation engine"
        },
        "pandoc.enableBibliography": {
          "type": "boolean",
          "default": true,
          "description": "Enable bibliography processing"
        },
        "pandoc.enableMath": {
          "type": "boolean",
          "default": true,
          "description": "Enable math formula processing"
        },
        "pandoc.templatePath": {
          "type": "string",
          "default": "",
          "description": "Path to custom templates directory"
        },
        "pandoc.extraArgs": {
          "type": "array",
          "items": { "type": "string" },
          "default": [],
          "description": "Additional Pandoc command line arguments"
        }
      }
    }
  }
}
```

### 3. JavaScript 主实现

```javascript
// main.js
class PandocPlugin {
  constructor() {
    this.isActive = false;
    this.pandocService = null;
    this.config = {};
    this.formatSupport = new Map();
    this.conversionQueue = [];
    this.isConverting = false;
  }

  async activate(context) {
    this.api = context.api;
    this.pluginId = context.pluginId;
    this.pluginPath = context.extensionPath;
    
    console.log('Pandoc plugin activating...');
    
    try {
      // 初始化 Pandoc 服务
      await this.initializePandocService();
      
      // 加载配置
      await this.loadConfiguration();
      
      // 检测格式支持
      await this.detectFormatSupport();
      
      // 注册命令
      await this.registerCommands();
      
      // 设置事件监听
      this.setupEventListeners();
      
      this.isActive = true;
      console.log('Pandoc plugin activated successfully');
      
      // 显示启动通知
      await this.api.ui.showNotification(
        `Pandoc converter ready (${this.formatSupport.size} formats supported)`,
        'info'
      );
      
    } catch (error) {
      console.error('Failed to activate Pandoc plugin:', error);
      await this.api.ui.showNotification(
        `Pandoc plugin activation failed: ${error.message}`,
        'error'
      );
      throw error;
    }
  }

  async deactivate() {
    console.log('Pandoc plugin deactivating...');
    
    // 取消所有进行中的转换
    this.conversionQueue = [];
    this.isConverting = false;
    
    // 清理资源
    if (this.pandocService) {
      await this.pandocService.cleanup();
    }
    
    this.isActive = false;
  }

  async initializePandocService() {
    // 通过 Dart 端初始化 Pandoc 服务
    this.pandocService = await this.api.bridge.createService('PandocService', {
      pluginPath: this.pluginPath,
      executablePath: await this.getPandocExecutablePath()
    });
  }

  async getPandocExecutablePath() {
    // 优先使用用户配置的路径
    const userPath = await this.api.storage.get('pandoc.executablePath');
    if (userPath && await this.api.fs.exists(userPath)) {
      return userPath;
    }
    
    // 使用捆绑的 Pandoc
    const platform = await this.api.system.getPlatform();
    const bundledPath = `${this.pluginPath}/assets/pandoc/${platform}/pandoc${platform === 'windows' ? '.exe' : ''}`;
    
    if (await this.api.fs.exists(bundledPath)) {
      return bundledPath;
    }
    
    // 尝试系统路径
    try {
      const systemPath = await this.api.process.which('pandoc');
      if (systemPath) return systemPath;
    } catch (error) {
      console.warn('Pandoc not found in system PATH');
    }
    
    throw new Error('Pandoc executable not found. Please install Pandoc or configure the path in settings.');
  }

  async loadConfiguration() {
    this.config = {
      executablePath: await this.api.storage.get('pandoc.executablePath') || '',
      defaultExportFormat: await this.api.storage.get('pandoc.defaultExportFormat') || 'pdf',
      pdfEngine: await this.api.storage.get('pandoc.pdfEngine') || 'auto',
      enableBibliography: await this.api.storage.get('pandoc.enableBibliography') ?? true,
      enableMath: await this.api.storage.get('pandoc.enableMath') ?? true,
      templatePath: await this.api.storage.get('pandoc.templatePath') || '',
      extraArgs: await this.api.storage.get('pandoc.extraArgs') || []
    };
  }

  async detectFormatSupport() {
    try {
      const formats = await this.pandocService.getSupportedFormats();
      
      for (const format of formats) {
        this.formatSupport.set(format.name, {
          name: format.name,
          displayName: format.displayName,
          extension: format.extension,
          canRead: format.canRead,
          canWrite: format.canWrite,
          description: format.description
        });
      }
      
      console.log(`Detected ${this.formatSupport.size} supported formats`);
    } catch (error) {
      console.error('Failed to detect format support:', error);
      // 使用预定义的格式列表作为后备
      this.loadDefaultFormats();
    }
  }

  loadDefaultFormats() {
    const defaultFormats = [
      { name: 'markdown', displayName: 'Markdown', extension: 'md', canRead: true, canWrite: true },
      { name: 'html', displayName: 'HTML', extension: 'html', canRead: true, canWrite: true },
      { name: 'latex', displayName: 'LaTeX', extension: 'tex', canRead: true, canWrite: true },
      { name: 'docx', displayName: 'Word Document', extension: 'docx', canRead: true, canWrite: true },
      { name: 'odt', displayName: 'OpenDocument Text', extension: 'odt', canRead: true, canWrite: true },
      { name: 'rtf', displayName: 'Rich Text Format', extension: 'rtf', canRead: true, canWrite: true },
      { name: 'epub', displayName: 'EPUB', extension: 'epub', canRead: true, canWrite: true },
      { name: 'pdf', displayName: 'PDF', extension: 'pdf', canRead: false, canWrite: true },
      { name: 'rst', displayName: 'reStructuredText', extension: 'rst', canRead: true, canWrite: true },
      { name: 'asciidoc', displayName: 'AsciiDoc', extension: 'adoc', canRead: true, canWrite: true }
    ];
    
    for (const format of defaultFormats) {
      this.formatSupport.set(format.name, format);
    }
  }

  async registerCommands() {
    // 导出文档
    await this.api.ui.registerCommand(
      'pandoc.export',
      'Export Document',
      () => this.showExportDialog()
    );

    // 导入文档
    await this.api.ui.registerCommand(
      'pandoc.import',
      'Import Document',
      () => this.showImportDialog()
    );

    // 批量转换
    await this.api.ui.registerCommand(
      'pandoc.convert',
      'Convert Files',
      () => this.showBatchConvertDialog()
    );

    // 预览转换
    await this.api.ui.registerCommand(
      'pandoc.preview',
      'Preview Conversion',
      () => this.showPreviewDialog()
    );
  }

  setupEventListeners() {
    // 监听设置变化
    this.api.events.on('settings.changed', (settings) => {
      if (settings.key.startsWith('pandoc.')) {
        this.updateConfig(settings.key, settings.value);
      }
    });

    // 监听文件拖放
    this.api.events.on('file.dropped', (files) => {
      this.handleFileDropped(files);
    });
  }

  async showExportDialog() {
    const currentContent = await this.api.editor.getContent();
    if (!currentContent || currentContent.trim().length === 0) {
      await this.api.ui.showNotification('No content to export', 'warning');
      return;
    }

    const webview = await this.api.ui.createWebView({
      id: 'pandoc.export-dialog',
      title: 'Export Document',
      html: this.generateExportDialogHTML(),
      width: '600px',
      height: '500px',
      enableScripts: true
    });

    webview.onMessage(async (message) => {
      await this.handleExportDialogMessage(message, webview, currentContent);
    });

    // 发送初始数据
    webview.postMessage({
      type: 'init',
      data: {
        formats: this.getWritableFormats(),
        config: this.config,
        currentFormat: 'markdown'
      }
    });
  }

  async showImportDialog() {
    const supportedFiles = this.getReadableFormats()
      .map(format => ({
        name: format.displayName,
        extensions: [format.extension]
      }));

    const filePaths = await this.api.fs.showOpenDialog({
      title: 'Import Document',
      allowMultiple: false,
      filters: [
        { name: 'All Supported', extensions: supportedFiles.flatMap(f => f.extensions) },
        ...supportedFiles
      ]
    });

    if (filePaths && filePaths.length > 0) {
      await this.importFile(filePaths[0]);
    }
  }

  async showBatchConvertDialog() {
    const webview = await this.api.ui.createWebView({
      id: 'pandoc.batch-convert-dialog',
      title: 'Batch Convert Files',
      html: this.generateBatchConvertDialogHTML(),
      width: '700px',
      height: '600px',
      enableScripts: true
    });

    webview.onMessage(async (message) => {
      await this.handleBatchConvertMessage(message, webview);
    });

    webview.postMessage({
      type: 'init',
      data: {
        readableFormats: this.getReadableFormats(),
        writableFormats: this.getWritableFormats()
      }
    });
  }

  async showPreviewDialog() {
    const content = await this.api.editor.getContent();
    if (!content || content.trim().length === 0) {
      await this.api.ui.showNotification('No content to preview', 'warning');
      return;
    }

    const formats = ['html', 'latex', 'docx'].filter(format => 
      this.formatSupport.has(format) && this.formatSupport.get(format).canWrite
    );

    const selectedFormat = await this.api.ui.showQuickPick({
      items: formats.map(format => ({
        label: this.formatSupport.get(format).displayName,
        value: format,
        description: `Preview as ${this.formatSupport.get(format).displayName}`
      })),
      placeholder: 'Select format to preview',
      title: 'Preview Conversion'
    });

    if (selectedFormat) {
      await this.previewConversion(content, selectedFormat.value);
    }
  }

  getReadableFormats() {
    return Array.from(this.formatSupport.values()).filter(format => format.canRead);
  }

  getWritableFormats() {
    return Array.from(this.formatSupport.values()).filter(format => format.canWrite);
  }

  generateExportDialogHTML() {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Export Document</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: var(--vscode-editor-background);
            color: var(--vscode-editor-foreground);
          }
          
          .form-group {
            margin-bottom: 20px;
          }
          
          label {
            display: block;
            margin-bottom: 5px;
            font-weight: 500;
          }
          
          select, input {
            width: 100%;
            padding: 8px;
            border: 1px solid var(--vscode-input-border);
            background: var(--vscode-input-background);
            color: var(--vscode-input-foreground);
            border-radius: 4px;
          }
          
          .checkbox-group {
            display: flex;
            align-items: center;
            gap: 8px;
          }
          
          .checkbox-group input[type="checkbox"] {
            width: auto;
          }
          
          .buttons {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 30px;
          }
          
          button {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
          }
          
          .primary {
            background: var(--vscode-button-background);
            color: var(--vscode-button-foreground);
          }
          
          .secondary {
            background: var(--vscode-button-secondaryBackground);
            color: var(--vscode-button-secondaryForeground);
          }
          
          .advanced {
            margin-top: 20px;
            padding: 15px;
            border: 1px solid var(--vscode-panel-border);
            border-radius: 4px;
          }
          
          .advanced-toggle {
            cursor: pointer;
            color: var(--vscode-textLink-foreground);
          }
          
          .advanced-content {
            display: none;
            margin-top: 15px;
          }
          
          .advanced.expanded .advanced-content {
            display: block;
          }
          
          textarea {
            width: 100%;
            height: 80px;
            padding: 8px;
            border: 1px solid var(--vscode-input-border);
            background: var(--vscode-input-background);
            color: var(--vscode-input-foreground);
            border-radius: 4px;
            resize: vertical;
          }
        </style>
      </head>
      <body>
        <div class="form-group">
          <label for="format">Export Format:</label>
          <select id="format">
            <option value="">Select format...</option>
          </select>
        </div>
        
        <div class="form-group">
          <label for="output-path">Output File:</label>
          <input type="text" id="output-path" placeholder="Choose output location..." readonly>
          <button type="button" onclick="selectOutputPath()" style="margin-top: 5px;">Browse...</button>
        </div>
        
        <div class="form-group" id="pdf-engine-group" style="display: none;">
          <label for="pdf-engine">PDF Engine:</label>
          <select id="pdf-engine">
            <option value="auto">Auto</option>
            <option value="pdflatex">pdfLaTeX</option>
            <option value="xelatex">XeLaTeX</option>
            <option value="lualatex">LuaLaTeX</option>
            <option value="wkhtmltopdf">wkhtmltopdf</option>
            <option value="weasyprint">WeasyPrint</option>
          </select>
        </div>
        
        <div class="checkbox-group">
          <input type="checkbox" id="enable-math" checked>
          <label for="enable-math">Enable math formulas</label>
        </div>
        
        <div class="checkbox-group">
          <input type="checkbox" id="enable-bibliography" checked>
          <label for="enable-bibliography">Process bibliography</label>
        </div>
        
        <div class="advanced">
          <div class="advanced-toggle" onclick="toggleAdvanced()">⚙️ Advanced Options</div>
          <div class="advanced-content">
            <div class="form-group">
              <label for="template">Template:</label>
              <select id="template">
                <option value="">Default</option>
                <option value="academic">Academic Paper</option>
                <option value="business">Business Report</option>
                <option value="presentation">Presentation</option>
              </select>
            </div>
            
            <div class="form-group">
              <label for="extra-args">Additional Arguments:</label>
              <textarea id="extra-args" placeholder="Additional Pandoc arguments (one per line)"></textarea>
            </div>
          </div>
        </div>
        
        <div class="buttons">
          <button type="button" class="secondary" onclick="cancel()">Cancel</button>
          <button type="button" class="primary" onclick="preview()">Preview</button>
          <button type="button" class="primary" onclick="export()">Export</button>
        </div>

        <script>
          let currentData = {};
          
          window.addEventListener('message', (event) => {
            const message = event.data;
            
            if (message.type === 'init') {
              currentData = message.data;
              populateFormats(message.data.formats);
              loadConfig(message.data.config);
            }
          });
          
          function populateFormats(formats) {
            const select = document.getElementById('format');
            select.innerHTML = '<option value="">Select format...</option>';
            
            formats.forEach(format => {
              const option = document.createElement('option');
              option.value = format.name;
              option.textContent = format.displayName;
              select.appendChild(option);
            });
            
            // 设置默认格式
            if (currentData.config?.defaultExportFormat) {
              select.value = currentData.config.defaultExportFormat;
              handleFormatChange();
            }
          }
          
          function loadConfig(config) {
            document.getElementById('pdf-engine').value = config.pdfEngine || 'auto';
            document.getElementById('enable-math').checked = config.enableMath ?? true;
            document.getElementById('enable-bibliography').checked = config.enableBibliography ?? true;
            
            if (config.extraArgs?.length > 0) {
              document.getElementById('extra-args').value = config.extraArgs.join('\\n');
            }
          }
          
          function handleFormatChange() {
            const format = document.getElementById('format').value;
            const pdfEngineGroup = document.getElementById('pdf-engine-group');
            
            if (format === 'pdf') {
              pdfEngineGroup.style.display = 'block';
            } else {
              pdfEngineGroup.style.display = 'none';
            }
            
            // 自动设置输出文件名
            if (format) {
              const formatInfo = currentData.formats.find(f => f.name === format);
              if (formatInfo) {
                const extension = formatInfo.extension;
                const outputPath = \`document.\${extension}\`;
                document.getElementById('output-path').value = outputPath;
              }
            }
          }
          
          function selectOutputPath() {
            window.postMessage({
              type: 'selectOutputPath',
              format: document.getElementById('format').value
            });
          }
          
          function toggleAdvanced() {
            const advanced = document.querySelector('.advanced');
            advanced.classList.toggle('expanded');
          }
          
          function cancel() {
            window.postMessage({ type: 'cancel' });
          }
          
          function preview() {
            const options = getExportOptions();
            window.postMessage({
              type: 'preview',
              options: options
            });
          }
          
          function export() {
            const options = getExportOptions();
            
            if (!options.format) {
              alert('Please select an export format');
              return;
            }
            
            if (!options.outputPath) {
              alert('Please select an output file');
              return;
            }
            
            window.postMessage({
              type: 'export',
              options: options
            });
          }
          
          function getExportOptions() {
            const extraArgsText = document.getElementById('extra-args').value.trim();
            const extraArgs = extraArgsText ? extraArgsText.split('\\n').filter(arg => arg.trim()) : [];
            
            return {
              format: document.getElementById('format').value,
              outputPath: document.getElementById('output-path').value,
              pdfEngine: document.getElementById('pdf-engine').value,
              enableMath: document.getElementById('enable-math').checked,
              enableBibliography: document.getElementById('enable-bibliography').checked,
              template: document.getElementById('template').value,
              extraArgs: extraArgs
            };
          }
          
          // 事件监听
          document.getElementById('format').addEventListener('change', handleFormatChange);
        </script>
      </body>
      </html>
    `;
  }

  async handleExportDialogMessage(message, webview, content) {
    switch (message.type) {
      case 'selectOutputPath':
        await this.handleSelectOutputPath(message, webview);
        break;
        
      case 'preview':
        await this.handlePreviewExport(message.options, content);
        break;
        
      case 'export':
        await this.handleExportDocument(message.options, content);
        webview.close();
        break;
        
      case 'cancel':
        webview.close();
        break;
    }
  }

  async handleSelectOutputPath(message, webview) {
    const format = this.formatSupport.get(message.format);
    if (!format) return;

    const savePath = await this.api.fs.showSaveDialog({
      title: `Export as ${format.displayName}`,
      defaultName: `document.${format.extension}`,
      filters: [
        { name: format.displayName, extensions: [format.extension] }
      ]
    });

    if (savePath) {
      webview.postMessage({
        type: 'outputPathSelected',
        path: savePath
      });
    }
  }

  async handlePreviewExport(options, content) {
    try {
      const previewFormat = options.format === 'pdf' ? 'html' : options.format;
      const result = await this.pandocService.convert({
        content: content,
        fromFormat: 'markdown',
        toFormat: previewFormat,
        options: this.buildPandocOptions(options)
      });

      // 显示预览
      const previewWebView = await this.api.ui.createWebView({
        id: 'pandoc.preview',
        title: `Preview: ${this.formatSupport.get(options.format).displayName}`,
        html: this.generatePreviewHTML(result, previewFormat),
        width: '80%',
        height: '80%',
        enableScripts: true
      });

    } catch (error) {
      await this.api.ui.showNotification(
        `Preview failed: ${error.message}`,
        'error'
      );
    }
  }

  async handleExportDocument(options, content) {
    try {
      // 显示进度
      const progressNotification = await this.api.ui.showProgress({
        title: 'Exporting document...',
        message: `Converting to ${this.formatSupport.get(options.format).displayName}`,
        cancellable: true
      });

      const result = await this.pandocService.convert({
        content: content,
        fromFormat: 'markdown',
        toFormat: options.format,
        outputPath: options.outputPath,
        options: this.buildPandocOptions(options),
        onProgress: (progress) => {
          progressNotification.report({
            message: progress.message,
            increment: progress.increment
          });
        }
      });

      progressNotification.complete();

      await this.api.ui.showNotification(
        `Document exported to ${options.outputPath}`,
        'success'
      );

      // 询问是否打开文件
      const openFile = await this.api.ui.showConfirmDialog({
        title: 'Export Complete',
        message: 'Document exported successfully. Would you like to open it?',
        okButton: 'Open',
        cancelButton: 'Close'
      });

      if (openFile) {
        await this.api.system.openExternal(options.outputPath);
      }

    } catch (error) {
      await this.api.ui.showNotification(
        `Export failed: ${error.message}`,
        'error'
      );
    }
  }

  buildPandocOptions(options) {
    const pandocOptions = [];

    // PDF 引擎
    if (options.format === 'pdf' && options.pdfEngine && options.pdfEngine !== 'auto') {
      pandocOptions.push(`--pdf-engine=${options.pdfEngine}`);
    }

    // 数学公式
    if (options.enableMath) {
      pandocOptions.push('--mathjax');
    }

    // 参考文献
    if (options.enableBibliography) {
      pandocOptions.push('--citeproc');
    }

    // 模板
    if (options.template) {
      const templatePath = `${this.pluginPath}/assets/templates/${options.template}.yaml`;
      pandocOptions.push(`--template=${templatePath}`);
    }

    // 额外参数
    if (options.extraArgs && options.extraArgs.length > 0) {
      pandocOptions.push(...options.extraArgs);
    }

    return pandocOptions;
  }

  async importFile(filePath) {
    try {
      const fileExtension = filePath.split('.').pop().toLowerCase();
      const format = this.findFormatByExtension(fileExtension);
      
      if (!format) {
        await this.api.ui.showNotification(
          `Unsupported file format: ${fileExtension}`,
          'error'
        );
        return;
      }

      const progressNotification = await this.api.ui.showProgress({
        title: 'Importing document...',
        message: `Converting from ${format.displayName}`,
        cancellable: false
      });

      const result = await this.pandocService.convert({
        inputPath: filePath,
        fromFormat: format.name,
        toFormat: 'markdown',
        onProgress: (progress) => {
          progressNotification.report({
            message: progress.message,
            increment: progress.increment
          });
        }
      });

      progressNotification.complete();

      // 在新标签页中打开转换后的内容
      await this.api.editor.newDocument(result.content);

      await this.api.ui.showNotification(
        `Document imported from ${filePath}`,
        'success'
      );

    } catch (error) {
      await this.api.ui.showNotification(
        `Import failed: ${error.message}`,
        'error'
      );
    }
  }

  findFormatByExtension(extension) {
    return Array.from(this.formatSupport.values())
      .find(format => format.extension === extension && format.canRead);
  }

  generatePreviewHTML(content, format) {
    if (format === 'html') {
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Preview</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              max-width: 800px;
              margin: 0 auto;
              padding: 20px;
              line-height: 1.6;
            }
            pre {
              background: #f5f5f5;
              padding: 10px;
              border-radius: 4px;
              overflow-x: auto;
            }
            blockquote {
              border-left: 4px solid #ddd;
              margin: 0;
              padding-left: 20px;
              color: #666;
            }
          </style>
        </head>
        <body>
          ${content}
        </body>
        </html>
      `;
    } else {
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Preview</title>
          <style>
            body {
              font-family: monospace;
              padding: 20px;
              white-space: pre-wrap;
            }
          </style>
        </head>
        <body>${content}</body>
        </html>
      `;
    }
  }

  async previewConversion(content, format) {
    try {
      const result = await this.pandocService.convert({
        content: content,
        fromFormat: 'markdown',
        toFormat: format,
        options: []
      });

      const previewWebView = await this.api.ui.createWebView({
        id: 'pandoc.preview',
        title: `Preview: ${this.formatSupport.get(format).displayName}`,
        html: this.generatePreviewHTML(result.content, format),
        width: '80%',
        height: '80%'
      });

    } catch (error) {
      await this.api.ui.showNotification(
        `Preview failed: ${error.message}`,
        'error'
      );
    }
  }

  async handleFileDropped(files) {
    const supportedFiles = files.filter(file => {
      const extension = file.name.split('.').pop().toLowerCase();
      return this.findFormatByExtension(extension);
    });

    if (supportedFiles.length === 0) return;

    if (supportedFiles.length === 1) {
      await this.importFile(supportedFiles[0].path);
    } else {
      // 多个文件，显示批量导入选项
      const choice = await this.api.ui.showQuickPick({
        items: [
          { label: 'Import All', value: 'all', description: 'Import all supported files' },
          { label: 'Select Files', value: 'select', description: 'Choose which files to import' }
        ],
        placeholder: `${supportedFiles.length} supported files found`,
        title: 'Import Multiple Files'
      });

      if (choice?.value === 'all') {
        for (const file of supportedFiles) {
          await this.importFile(file.path);
        }
      } else if (choice?.value === 'select') {
        // 实现文件选择逻辑
        await this.showFileSelectionDialog(supportedFiles);
      }
    }
  }

  async updateConfig(key, value) {
    const configKey = key.replace('pandoc.', '');
    this.config[configKey] = value;
    await this.api.storage.set(key, value);

    // 应用配置更改
    if (configKey === 'executablePath') {
      try {
        await this.initializePandocService();
        await this.detectFormatSupport();
      } catch (error) {
        await this.api.ui.showNotification(
          `Failed to update Pandoc path: ${error.message}`,
          'error'
        );
      }
    }
  }
}

// 插件入口点
function activate(context) {
  const plugin = new PandocPlugin();
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

### 4. Dart 服务层实现

```dart
// main.dart
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class PandocService {
  late String _executablePath;
  late String _pluginPath;
  final Map<String, FormatInfo> _supportedFormats = {};

  Future<void> initialize(Map<String, dynamic> options) async {
    _pluginPath = options['pluginPath'] as String;
    _executablePath = options['executablePath'] as String;
    
    // 验证 Pandoc 可执行文件
    await _validatePandocExecutable();
    
    // 检测支持的格式
    await _detectSupportedFormats();
  }

  Future<void> _validatePandocExecutable() async {
    final file = File(_executablePath);
    if (!await file.exists()) {
      throw Exception('Pandoc executable not found at: $_executablePath');
    }

    // 测试 Pandoc 是否可以运行
    try {
      final result = await Process.run(_executablePath, ['--version']);
      if (result.exitCode != 0) {
        throw Exception('Pandoc executable is not working properly');
      }
      print('Pandoc version: ${result.stdout.toString().split('\n').first}');
    } catch (e) {
      throw Exception('Failed to run Pandoc: $e');
    }
  }

  Future<void> _detectSupportedFormats() async {
    try {
      // 获取输入格式
      final inputResult = await Process.run(_executablePath, ['--list-input-formats']);
      final outputResult = await Process.run(_executablePath, ['--list-output-formats']);

      if (inputResult.exitCode == 0 && outputResult.exitCode == 0) {
        final inputFormats = inputResult.stdout.toString().split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toSet();
        final outputFormats = outputResult.stdout.toString().split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toSet();

        _buildFormatSupport(inputFormats, outputFormats);
      }
    } catch (e) {
      print('Failed to detect formats: $e');
      _loadDefaultFormats();
    }
  }

  void _buildFormatSupport(Set<String> inputFormats, Set<String> outputFormats) {
    final formatDefinitions = {
      'markdown': FormatInfo('markdown', 'Markdown', 'md', 'Markdown format'),
      'html': FormatInfo('html', 'HTML', 'html', 'HTML format'),
      'latex': FormatInfo('latex', 'LaTeX', 'tex', 'LaTeX format'),
      'docx': FormatInfo('docx', 'Word Document', 'docx', 'Microsoft Word format'),
      'odt': FormatInfo('odt', 'OpenDocument Text', 'odt', 'OpenDocument Text format'),
      'rtf': FormatInfo('rtf', 'Rich Text Format', 'rtf', 'Rich Text Format'),
      'epub': FormatInfo('epub', 'EPUB', 'epub', 'EPUB e-book format'),
      'epub3': FormatInfo('epub3', 'EPUB3', 'epub', 'EPUB3 e-book format'),
      'pdf': FormatInfo('pdf', 'PDF', 'pdf', 'Portable Document Format'),
      'rst': FormatInfo('rst', 'reStructuredText', 'rst', 'reStructuredText format'),
      'asciidoc': FormatInfo('asciidoc', 'AsciiDoc', 'adoc', 'AsciiDoc format'),
      'mediawiki': FormatInfo('mediawiki', 'MediaWiki', 'wiki', 'MediaWiki format'),
      'textile': FormatInfo('textile', 'Textile', 'textile', 'Textile format'),
      'org': FormatInfo('org', 'Org Mode', 'org', 'Emacs Org mode'),
      'json': FormatInfo('json', 'JSON', 'json', 'Pandoc JSON format'),
      'man': FormatInfo('man', 'Man Page', '1', 'Manual page format'),
      'texinfo': FormatInfo('texinfo', 'Texinfo', 'texi', 'GNU Texinfo format'),
    };

    for (final entry in formatDefinitions.entries) {
      final formatName = entry.key;
      final formatInfo = entry.value;
      
      formatInfo.canRead = inputFormats.contains(formatName);
      formatInfo.canWrite = outputFormats.contains(formatName);
      
      if (formatInfo.canRead || formatInfo.canWrite) {
        _supportedFormats[formatName] = formatInfo;
      }
    }
  }

  void _loadDefaultFormats() {
    final defaultFormats = [
      FormatInfo('markdown', 'Markdown', 'md', 'Markdown format', canRead: true, canWrite: true),
      FormatInfo('html', 'HTML', 'html', 'HTML format', canRead: true, canWrite: true),
      FormatInfo('latex', 'LaTeX', 'tex', 'LaTeX format', canRead: true, canWrite: true),
      FormatInfo('docx', 'Word Document', 'docx', 'Microsoft Word format', canRead: true, canWrite: true),
      FormatInfo('pdf', 'PDF', 'pdf', 'Portable Document Format', canRead: false, canWrite: true),
    ];

    for (final format in defaultFormats) {
      _supportedFormats[format.name] = format;
    }
  }

  List<Map<String, dynamic>> getSupportedFormats() {
    return _supportedFormats.values.map((format) => format.toMap()).toList();
  }

  Future<ConversionResult> convert(ConversionRequest request) async {
    final args = <String>[];
    
    // 输入格式
    if (request.fromFormat != null) {
      args.addAll(['--from', request.fromFormat!]);
    }
    
    // 输出格式
    if (request.toFormat != null) {
      args.addAll(['--to', request.toFormat!]);
    }
    
    // 输出文件
    if (request.outputPath != null) {
      args.addAll(['--output', request.outputPath!]);
    }
    
    // 添加额外选项
    if (request.options != null) {
      args.addAll(request.options!);
    }
    
    // 输入文件或内容
    if (request.inputPath != null) {
      args.add(request.inputPath!);
    }

    try {
      final process = await Process.start(_executablePath, args);
      
      // 如果有内容输入，写入标准输入
      if (request.content != null) {
        process.stdin.write(request.content!);
        await process.stdin.close();
      }
      
      // 收集输出和错误
      final outputBuffer = StringBuffer();
      final errorBuffer = StringBuffer();
      
      process.stdout.transform(utf8.decoder).listen((data) {
        outputBuffer.write(data);
        request.onProgress?.call(ProgressInfo('Processing...', 50));
      });
      
      process.stderr.transform(utf8.decoder).listen((data) {
        errorBuffer.write(data);
      });
      
      final exitCode = await process.exitCode;
      
      if (exitCode != 0) {
        final errorMessage = errorBuffer.toString();
        throw Exception('Pandoc conversion failed: $errorMessage');
      }
      
      request.onProgress?.call(ProgressInfo('Conversion completed', 100));
      
      return ConversionResult(
        success: true,
        content: request.outputPath == null ? outputBuffer.toString() : null,
        outputPath: request.outputPath,
      );
      
    } catch (e) {
      return ConversionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> cleanup() async {
    // 清理临时文件等
    _supportedFormats.clear();
  }
}

class FormatInfo {
  final String name;
  final String displayName;
  final String extension;
  final String description;
  bool canRead;
  bool canWrite;

  FormatInfo(
    this.name,
    this.displayName,
    this.extension,
    this.description, {
    this.canRead = false,
    this.canWrite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'displayName': displayName,
      'extension': extension,
      'description': description,
      'canRead': canRead,
      'canWrite': canWrite,
    };
  }
}

class ConversionRequest {
  final String? content;
  final String? inputPath;
  final String? outputPath;
  final String? fromFormat;
  final String? toFormat;
  final List<String>? options;
  final Function(ProgressInfo)? onProgress;

  ConversionRequest({
    this.content,
    this.inputPath,
    this.outputPath,
    this.fromFormat,
    this.toFormat,
    this.options,
    this.onProgress,
  });
}

class ConversionResult {
  final bool success;
  final String? content;
  final String? outputPath;
  final String? error;

  ConversionResult({
    required this.success,
    this.content,
    this.outputPath,
    this.error,
  });
}

class ProgressInfo {
  final String message;
  final int increment;

  ProgressInfo(this.message, this.increment);
}

// Dart 插件入口点
class PandocPluginDart extends MarkoraPlugin {
  late PandocService _pandocService;

  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'com.markora.pandoc',
    name: 'Pandoc Universal Converter',
    version: '3.0.0',
    description: 'Universal document converter using Pandoc',
  );

  @override
  Future<void> onLoad(PluginContext context) async {
    super.onLoad(context);
    
    _pandocService = PandocService();
    
    // 注册服务供 JavaScript 端调用
    context.bridge.registerService('PandocService', _pandocService);
  }

  @override
  Future<void> onUnload() async {
    await _pandocService.cleanup();
    super.onUnload();
  }
}
```

### 5. 转换模板

```yaml
# assets/templates/academic-paper.yaml
title: Academic Paper Template
author: Author Name
date: \today
documentclass: article
geometry: margin=1in
fontsize: 12pt
linestretch: 1.5
bibliography: references.bib
csl: ieee.csl
link-citations: true
toc: true
number-sections: true
```

```yaml
# assets/templates/business-report.yaml  
title: Business Report
subtitle: Quarterly Analysis
author: Business Team
date: \today
documentclass: report
geometry: 
  - margin=1in
  - letterpaper
fontsize: 11pt
mainfont: Arial
header-includes:
  - \usepackage{fancyhdr}
  - \pagestyle{fancy}
  - \fancyhead[C]{Business Report}
toc: true
lof: true
lot: true
```

### 6. 国际化文件

```json
// locales/zh.json
{
  "commands": {
    "export": "导出文档",
    "import": "导入文档", 
    "convert": "批量转换",
    "preview": "预览转换"
  },
  "formats": {
    "pdf": "PDF 文档",
    "docx": "Word 文档",
    "html": "HTML 网页",
    "latex": "LaTeX 文档",
    "epub": "电子书",
    "odt": "OpenDocument 文本"
  },
  "messages": {
    "exportSuccess": "文档已导出到 {path}",
    "exportFailed": "导出失败：{error}",
    "importSuccess": "文档已从 {path} 导入",
    "importFailed": "导入失败：{error}",
    "noContent": "没有内容可导出",
    "pandocNotFound": "未找到 Pandoc 可执行文件",
    "unsupportedFormat": "不支持的文件格式：{format}"
  },
  "dialog": {
    "selectFormat": "选择格式",
    "selectOutput": "选择输出文件",
    "exportOptions": "导出选项",
    "advancedOptions": "高级选项",
    "enableMath": "启用数学公式",
    "enableBibliography": "处理参考文献",
    "pdfEngine": "PDF 引擎",
    "template": "模板",
    "additionalArgs": "附加参数"
  }
}
```

## 实施计划

### 第一阶段：基础架构 (1 周)
1. ✅ 设计插件清单和架构
2. ✅ 实现 JavaScript 主逻辑  
3. ✅ 创建 Dart 服务层
4. ✅ 集成 Pandoc 可执行文件

### 第二阶段：核心功能 (1 周)
1. 🔄 实现文档导出功能
2. 🔄 实现文档导入功能
3. 🔄 添加格式检测和支持
4. 🔄 实现转换预览

### 第三阶段：高级功能 (1 周)
1. ⏳ 实现批量转换
2. ⏳ 添加模板系统
3. ⏳ 实现进度追踪
4. ⏳ 添加错误处理

### 第四阶段：优化完善 (3 天)
1. ⏳ 用户界面优化
2. ⏳ 性能优化
3. ⏳ 全面测试
4. ⏳ 文档完善

## 技术亮点

1. **全格式支持**: 支持 20+ 种文档格式互转
2. **智能检测**: 自动检测 Pandoc 能力和格式支持
3. **模板系统**: 预制的专业文档模板
4. **批量处理**: 高效的多文件转换
5. **实时进度**: 详细的转换进度追踪
6. **错误处理**: 完善的错误提示和恢复机制
7. **跨平台**: 支持 Windows、macOS、Linux
8. **配置灵活**: 丰富的转换参数配置

## 用户价值

1. **一站式转换**: 无需切换多个工具
2. **专业品质**: 基于强大的 Pandoc 引擎
3. **简单易用**: 直观的操作界面
4. **格式丰富**: 满足各种文档需求
5. **效率提升**: 批量处理节省时间
6. **质量保证**: 保持文档格式和内容完整性

这个 Pandoc 插件将为 Markora 用户提供专业级的文档转换能力，成为真正的"通用文档转换器"。