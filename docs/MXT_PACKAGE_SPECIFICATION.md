# MXT 插件包规范 V3.0

## 概述

MXT (Markora eXTension) 是 Markora 编辑器的官方插件包格式，基于 ZIP 压缩格式，支持跨平台分发和动态加载。

## 包格式规范

### 1. 文件结构

```
plugin_name_v1.0.0.mxt
├── manifest.json          # 插件清单文件 (必需)
├── main.dart              # Dart 入口点 (可选)
├── main.js                # JavaScript 入口点 (可选)
├── package.json           # NPM 风格依赖声明 (可选)
├── pubspec.yaml           # Dart 依赖声明 (可选)
├── assets/                # 静态资源目录 (可选)
│   ├── icons/            # 图标文件
│   │   ├── icon-16.png
│   │   ├── icon-32.png
│   │   └── icon-48.png
│   ├── themes/           # 主题文件
│   ├── templates/        # 模板文件
│   └── media/           # 媒体文件
├── locales/              # 国际化文件 (可选)
│   ├── en.json
│   ├── zh.json
│   └── ja.json
├── platforms/            # 平台特定代码 (可选)
│   ├── windows/
│   │   ├── native.dll
│   │   └── setup.ps1
│   ├── macos/
│   │   ├── native.dylib
│   │   └── setup.sh
│   ├── linux/
│   │   ├── native.so
│   │   └── setup.sh
│   ├── android/
│   │   └── plugin.aar
│   └── ios/
│       └── plugin.framework/
├── webview/              # WebView 资源 (可选)
│   ├── index.html
│   ├── styles.css
│   ├── scripts.js
│   └── worker.js
├── schemas/              # 配置架构 (可选)
│   └── config.schema.json
├── docs/                 # 文档 (可选)
│   ├── README.md
│   ├── CHANGELOG.md
│   └── api.md
└── tests/                # 测试文件 (可选)
    ├── unit/
    └── integration/
```

### 2. 清单文件 (manifest.json)

#### 2.1 基本结构

```json
{
  "apiVersion": "3.0.0",
  "kind": "Plugin",
  "metadata": {
    "id": "com.markora.plugin.example",
    "name": "Example Plugin",
    "displayName": "示例插件",
    "version": "1.0.0",
    "description": "An example plugin for Markora",
    "shortDescription": "Example plugin",
    "author": "Markora Team",
    "email": "plugins@markora.dev",
    "license": "MIT",
    "homepage": "https://markora.dev/plugins/example",
    "repository": "https://github.com/markora/example-plugin",
    "bugs": "https://github.com/markora/example-plugin/issues",
    "keywords": ["example", "demo", "tutorial"],
    "categories": ["editor", "utility"],
    "icon": "assets/icons/icon-48.png",
    "preview": "assets/screenshots/preview.png",
    "gallery": [
      "assets/screenshots/screenshot1.png",
      "assets/screenshots/screenshot2.png"
    ]
  },
  "spec": {
    // 插件规格说明
  }
}
```

#### 2.2 插件规格 (spec)

```json
{
  "spec": {
    "type": "hybrid",
    "category": "editor",
    "entryPoints": {
      "dart": "main.dart",
      "javascript": "main.js"
    },
    "platforms": {
      "windows": {
        "supported": true,
        "minVersion": "10",
        "maxVersion": "11",
        "architectures": ["x64", "arm64"],
        "native": "platforms/windows/native.dll"
      },
      "macos": {
        "supported": true,
        "minVersion": "10.15",
        "architectures": ["x64", "arm64"],
        "native": "platforms/macos/native.dylib"
      },
      "linux": {
        "supported": true,
        "distributions": ["ubuntu", "fedora", "debian"],
        "architectures": ["x64", "arm64"],
        "native": "platforms/linux/native.so"
      },
      "android": {
        "supported": false,
        "reason": "WebView API limitations",
        "minSdk": 21,
        "targetSdk": 34
      },
      "ios": {
        "supported": false,
        "reason": "Filesystem access restrictions",
        "minVersion": "12.0"
      },
      "web": {
        "supported": true,
        "browsers": ["chrome", "firefox", "safari", "edge"],
        "features": ["webgl", "webassembly"]
      }
    },
    "capabilities": {
      "required": [
        "editor.read",
        "editor.write",
        "ui.toolbar",
        "storage.local"
      ],
      "optional": [
        "filesystem.read",
        "filesystem.write",
        "network.http",
        "clipboard.read",
        "clipboard.write"
      ]
    },
    "permissions": [
      {
        "name": "filesystem",
        "scope": "user-documents",
        "description": "Access user documents for import/export"
      },
      {
        "name": "network",
        "scope": "https://api.example.com",
        "description": "Access external API for data synchronization"
      }
    ],
    "dependencies": {
      "core": ">=2.0.0 <3.0.0",
      "plugins": {
        "markdown-renderer": ">=1.0.0",
        "theme-manager": "^2.1.0"
      },
      "runtime": {
        "dart": ">=3.0.0",
        "javascript": "ES2020"
      }
    },
    "activationEvents": [
      "onStartup",
      "onLanguage:markdown",
      "onCommand:example.activate",
      "onFileType:.md",
      "onSettingChanged:example.enabled"
    ],
    "contributes": {
      "commands": [
        {
          "id": "example.hello",
          "title": "Hello World",
          "category": "Example",
          "description": "Shows a hello world message",
          "icon": "$(heart)",
          "enablement": "editorHasSelection"
        }
      ],
      "toolbar": [
        {
          "id": "example.toolbar",
          "group": "editor",
          "priority": 100,
          "items": [
            {
              "command": "example.hello",
              "icon": "assets/icons/hello.svg",
              "tooltip": "Say Hello",
              "when": "editorFocused"
            }
          ]
        }
      ],
      "menus": {
        "editor/context": [
          {
            "command": "example.hello",
            "when": "editorHasSelection",
            "group": "example@1"
          }
        ],
        "explorer/context": [
          {
            "command": "example.processFile",
            "when": "resourceExtname == '.md'",
            "group": "example@1"
          }
        ]
      },
      "keybindings": [
        {
          "command": "example.hello",
          "key": "ctrl+shift+h",
          "mac": "cmd+shift+h",
          "when": "editorTextFocus"
        }
      ],
      "languages": [
        {
          "id": "example-lang",
          "aliases": ["Example", "example"],
          "extensions": [".ex", ".example"],
          "mimetypes": ["text/x-example"],
          "configuration": "language-configuration.json"
        }
      ],
      "themes": [
        {
          "id": "example-dark",
          "label": "Example Dark",
          "path": "assets/themes/dark.json",
          "uiTheme": "vs-dark"
        }
      ],
      "snippets": [
        {
          "language": "markdown",
          "path": "assets/snippets/markdown.json"
        }
      ],
      "renderers": [
        {
          "id": "example-renderer",
          "displayName": "Example Renderer",
          "languages": ["example"],
          "entrypoint": "webview/renderer.html"
        }
      ],
      "webviews": [
        {
          "id": "example-webview",
          "title": "Example Panel",
          "entrypoint": "webview/panel.html",
          "enableScripts": true,
          "retainContextWhenHidden": true
        }
      ]
    },
    "configuration": {
      "title": "Example Plugin Settings",
      "properties": {
        "example.enabled": {
          "type": "boolean",
          "default": true,
          "description": "Enable the example plugin",
          "scope": "application"
        },
        "example.apiKey": {
          "type": "string",
          "default": "",
          "description": "API key for external service",
          "scope": "machine",
          "secret": true
        },
        "example.theme": {
          "type": "string",
          "default": "default",
          "enum": ["default", "dark", "light"],
          "enumDescriptions": [
            "Use default theme",
            "Use dark theme",
            "Use light theme"
          ],
          "description": "Plugin theme preference"
        },
        "example.advanced": {
          "type": "object",
          "default": {},
          "properties": {
            "timeout": {
              "type": "number",
              "default": 5000,
              "minimum": 1000,
              "maximum": 30000
            },
            "retries": {
              "type": "integer",
              "default": 3,
              "minimum": 0,
              "maximum": 10
            }
          }
        }
      }
    },
    "scripts": {
      "preinstall": "scripts/preinstall.sh",
      "postinstall": "scripts/postinstall.sh",
      "preuninstall": "scripts/preuninstall.sh",
      "postupdate": "scripts/postupdate.sh"
    },
    "resources": {
      "cpu": "low",
      "memory": "medium",
      "storage": "10MB",
      "network": "optional"
    },
    "security": {
      "contentSecurityPolicy": "default-src 'self'; script-src 'self' 'unsafe-inline'",
      "sandbox": ["allow-scripts", "allow-same-origin"],
      "trustedDomains": ["api.example.com"]
    }
  }
}
```

### 3. 插件类型定义

#### 3.1 插件类型 (type)

- **`dart`**: 纯 Dart 插件
- **`javascript`**: 纯 JavaScript 插件  
- **`hybrid`**: Dart + JavaScript 混合插件
- **`webview`**: 基于 WebView 的插件
- **`native`**: 包含原生代码的插件

#### 3.2 插件分类 (category)

- **`editor`**: 编辑器功能增强
- **`renderer`**: 内容渲染器
- **`theme`**: 主题和外观
- **`language`**: 语言支持
- **`tool`**: 开发工具
- **`converter`**: 格式转换器
- **`utility`**: 实用工具
- **`integration`**: 第三方集成

### 4. 配置架构

#### 4.1 语言配置 (language-configuration.json)

```json
{
  "comments": {
    "lineComment": "//",
    "blockComment": ["/*", "*/"]
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
    ["\"", "\""],
    ["'", "'"]
  ],
  "folding": {
    "markers": {
      "start": "^\\s*//\\s*#region\\b",
      "end": "^\\s*//\\s*#endregion\\b"
    }
  },
  "wordPattern": "(-?\\d*\\.\\d\\w*)|([^\\`\\~\\!\\@\\#\\%\\^\\&\\*\\(\\)\\-\\=\\+\\[\\{\\]\\}\\\\\\|\\;\\:\\'\\\"\\,\\.\\<\\>\\/\\?\\s]+)",
  "indentationRules": {
    "increaseIndentPattern": "^((?!\\/\\/).)*(\\{[^}\"'`]*|\\([^)\"'`]*|\\[[^\\]\"'`]*)$",
    "decreaseIndentPattern": "^((?!.*?\\/\\*).*\\*/)?\\s*[\\}\\]].*$"
  }
}
```

#### 4.2 代码片段 (snippets.json)

```json
{
  "Insert Code Block": {
    "prefix": ["code", "```"],
    "body": [
      "```${1:language}",
      "${2:code}",
      "```"
    ],
    "description": "Insert code block"
  },
  "Insert Table": {
    "prefix": "table",
    "body": [
      "| ${1:Header 1} | ${2:Header 2} |",
      "|---------------|---------------|",
      "| ${3:Cell 1}   | ${4:Cell 2}   |"
    ],
    "description": "Insert table"
  }
}
```

### 5. 国际化支持

#### 5.1 语言文件格式

```json
{
  "displayName": "示例插件",
  "description": "这是一个示例插件",
  "commands": {
    "example.hello": {
      "title": "问好",
      "description": "显示问好消息"
    }
  },
  "configuration": {
    "example.enabled": {
      "description": "启用示例插件"
    },
    "example.theme": {
      "description": "插件主题偏好",
      "enumDescriptions": [
        "使用默认主题",
        "使用深色主题", 
        "使用浅色主题"
      ]
    }
  },
  "messages": {
    "hello": "你好，世界！",
    "error.networkTimeout": "网络超时，请检查网络连接"
  }
}
```

### 6. 版本控制

#### 6.1 语义化版本

插件版本遵循 [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR**: 不兼容的 API 变更
- **MINOR**: 向后兼容的功能新增
- **PATCH**: 向后兼容的问题修正

#### 6.2 兼容性矩阵

```json
{
  "compatibility": {
    "core": {
      "1.0.0": ">=1.0.0 <2.0.0",
      "2.0.0": ">=2.0.0 <3.0.0"
    },
    "api": {
      "breaking_changes": [
        {
          "version": "2.0.0",
          "description": "Editor API signature changes",
          "migration": "docs/migration-v2.md"
        }
      ]
    }
  }
}
```

### 7. 安全规范

#### 7.1 代码签名

```json
{
  "signature": {
    "algorithm": "SHA256withRSA",
    "certificate": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----",
    "signature": "base64-encoded-signature",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

#### 7.2 权限声明

```json
{
  "permissions": [
    {
      "name": "filesystem",
      "scope": "user-documents",
      "description": "访问用户文档进行导入导出",
      "required": true,
      "dangerous": false
    },
    {
      "name": "network",
      "scope": "https://api.example.com/*",
      "description": "访问外部 API 进行数据同步",
      "required": false,
      "dangerous": true
    }
  ]
}
```

### 8. 性能要求

#### 8.1 资源限制

- **包大小**: 建议 < 50MB，最大 100MB
- **内存使用**: 建议 < 100MB，最大 500MB
- **启动时间**: < 3 秒
- **响应时间**: 用户操作响应 < 200ms

#### 8.2 性能指标

```json
{
  "performance": {
    "startup": {
      "target": "< 1s",
      "maximum": "< 3s"
    },
    "memory": {
      "idle": "< 50MB",
      "peak": "< 200MB"
    },
    "cpu": {
      "idle": "< 5%",
      "peak": "< 50%"
    }
  }
}
```

### 9. 测试规范

#### 9.1 测试文件结构

```
tests/
├── unit/                 # 单元测试
│   ├── commands.test.dart
│   └── utils.test.js
├── integration/          # 集成测试
│   ├── workflow.test.dart
│   └── ui.test.js
├── fixtures/            # 测试数据
│   ├── sample.md
│   └── config.json
└── mocks/              # 模拟对象
    └── api.mock.js
```

#### 9.2 测试配置

```json
{
  "testing": {
    "frameworks": ["dart_test", "jest"],
    "coverage": {
      "threshold": 80,
      "exclude": ["**/generated/**", "**/test/**"]
    },
    "ci": {
      "platforms": ["windows", "macos", "linux"],
      "flutter_versions": ["3.19.0", "3.24.0"]
    }
  }
}
```

### 10. 发布规范

#### 10.1 发布清单

```json
{
  "release": {
    "version": "1.0.0",
    "changelog": "CHANGELOG.md",
    "assets": [
      {
        "name": "example_plugin_v1.0.0.mxt",
        "size": 1024000,
        "checksum": "sha256:abc123...",
        "platforms": ["all"]
      }
    ],
    "metadata": {
      "build_date": "2024-01-01T00:00:00Z",
      "build_environment": "CI/CD Pipeline",
      "flutter_version": "3.24.0",
      "dart_version": "3.4.0"
    }
  }
}
```

## 工具支持

### 1. 验证工具

```bash
# 验证插件包格式
markora plugin validate example_plugin_v1.0.0.mxt

# 检查兼容性
markora plugin check-compatibility example_plugin_v1.0.0.mxt

# 测试插件
markora plugin test example_plugin_v1.0.0.mxt
```

### 2. 开发工具

```bash
# 创建插件项目
markora plugin create --template=basic my-plugin

# 构建插件
markora plugin build

# 打包插件
markora plugin package

# 发布插件
markora plugin publish --registry=official
```

这个规范确保了 MXT 插件包的标准化、安全性和可维护性，为 Markora 插件生态系统提供了坚实的基础。