import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../types/plugin.dart';
import 'plugin_interface.dart';
import 'plugin_implementations.dart';
import 'plugin_context_service.dart';

/// Plugin loader
class PluginLoader {
  /// Load plugin metadata from file
  Future<PluginMetadata?> loadPluginMetadata(File manifestFile) async {
    try {
      final content = await manifestFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      return PluginMetadata(
        id: json['id'] as String,
        name: json['name'] as String,
        version: json['version'] as String,
        description: json['description'] as String,
        author: json['author'] as String,
        type: _parsePluginType(json['type'] as String),
        minVersion: json['minVersion'] as String? ?? '1.0.0',
        maxVersion: json['maxVersion'] as String?,
        homepage: json['homepage'] as String?,
        repository: json['repository'] as String?,
        license: json['license'] as String? ?? 'MIT',
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (e) {
      debugPrint('加载插件元数据失败: $e');
      return null;
    }
  }
  
  /// Load plugin instance
  Future<MarkoraPlugin?> loadPlugin(Plugin plugin) async {
    try {
      if (plugin.installPath == null) {
        throw Exception('插件安装路径为空');
      }
      
      final pluginDir = Directory(plugin.installPath!);
      if (!await pluginDir.exists()) {
        throw Exception('插件目录不存在: ${plugin.installPath}');
      }
      
      // Load different plugin implementations based on plugin type
      switch (plugin.metadata.type) {
        case PluginType.syntax:
          return await _loadSyntaxPlugin(plugin);
        case PluginType.renderer:
          return await _loadRendererPlugin(plugin);
        case PluginType.theme:
          return await _loadThemePlugin(plugin);
        case PluginType.exporter:
          return await _loadExporterPlugin(plugin);
        case PluginType.tool:
          return await _loadToolPlugin(plugin);
        case PluginType.integration:
          return await _loadIntegrationPlugin(plugin);
        default:
          throw Exception('不支持的插件类型: ${plugin.metadata.type}');
      }
    } catch (e) {
      debugPrint('加载插件失败 ${plugin.metadata.id}: $e');
      return null;
    }
  }
  
  /// Load syntax extension plugin
  Future<MarkoraPlugin?> _loadSyntaxPlugin(Plugin plugin) async {
    try {
      // Check if it's a Mermaid plugin
      if (plugin.metadata.id == 'mermaid_plugin') {
        // Use the working MermaidPlugin implementation
        return _createMermaidPlugin(plugin.metadata);
      }
      
      // Default syntax plugin implementation
      return SyntaxPluginImpl(plugin.metadata);
    } catch (e) {
      debugPrint('加载语法插件失败: $e');
      return null;
    }
  }
  
  /// Load renderer plugin
  Future<MarkoraPlugin?> _loadRendererPlugin(Plugin plugin) async {
    try {
      // Check if it's a Mermaid plugin
      if (plugin.metadata.id == 'mermaid_plugin') {
        // Dynamically import Mermaid plugin
        final pluginMainFile = File(path.join(plugin.installPath!, 'lib', 'main.dart'));
        if (await pluginMainFile.exists()) {
          // Here we directly instantiate MermaidPlugin
          // In actual projects, might need to use dart:mirrors or other dynamic loading mechanisms
          return _createMermaidPlugin(plugin.metadata);
        }
      }
      
      // Default renderer plugin implementation
      return RendererPluginImpl(plugin.metadata);
    } catch (e) {
      debugPrint('加载渲染器插件失败: $e');
      return null;
    }
  }
  
  /// Create Mermaid plugin instance
  MarkoraPlugin _createMermaidPlugin(PluginMetadata metadata) {
    // Import the actual MermaidPlugin
    try {
      // Use the improved MermaidPlugin with proper WebView implementation
      return _WorkingMermaidPlugin(metadata);
    } catch (e) {
      debugPrint('创建MermaidPlugin失败: $e');
      return _ImprovedMermaidPluginProxy(metadata);
    }
  }
  
  /// Load theme plugin
  Future<MarkoraPlugin?> _loadThemePlugin(Plugin plugin) async {
    // TODO: Implement theme plugin loading logic
    return ThemePluginImpl(plugin.metadata);
  }
  
  /// Load export plugin
  Future<MarkoraPlugin?> _loadExporterPlugin(Plugin plugin) async {
    // TODO: Implement export plugin loading logic
    return ExporterPluginImpl(plugin.metadata);
  }
  
  /// Load tool plugin
  Future<MarkoraPlugin?> _loadToolPlugin(Plugin plugin) async {
    // TODO: Implement tool plugin loading logic
    return ToolPluginImpl(plugin.metadata);
  }
  
  /// Load integration plugin
  Future<MarkoraPlugin?> _loadIntegrationPlugin(Plugin plugin) async {
    // TODO: Implement integration plugin loading logic
    return IntegrationPluginImpl(plugin.metadata);
  }
  
  /// Parse plugin type
  PluginType _parsePluginType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'syntax':
        return PluginType.syntax;
      case 'renderer':
        return PluginType.renderer;
      case 'theme':
        return PluginType.theme;
      case 'exporter':
        return PluginType.exporter;
      case 'tool':
        return PluginType.tool;
      case 'integration':
        return PluginType.integration;
      default:
        throw Exception('未知的插件类型: $typeString');
    }
  }
  
  /// Validate plugin
  Future<bool> validatePlugin(Plugin plugin) async {
    try {
      if (plugin.installPath == null) return false;
      
      final pluginDir = Directory(plugin.installPath!);
      if (!await pluginDir.exists()) return false;
      
      // Check required files
      final manifestFile = File(path.join(pluginDir.path, 'plugin.json'));
      if (!await manifestFile.exists()) return false;
      
      // Validate metadata
      final metadata = await loadPluginMetadata(manifestFile);
      if (metadata == null) return false;
      
      // TODO: Add more validation logic (signature verification, version compatibility, etc.)
      
      return true;
    } catch (e) {
      debugPrint('验证插件失败: $e');
      return false;
    }
  }
}

/// Base plugin implementation
abstract class BasePlugin implements MarkoraPlugin {
  BasePlugin(this.metadata);
  
  @override
  final PluginMetadata metadata;
  
  @override
  bool isInitialized = false;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    isInitialized = true;
  }
  
  @override
  Future<void> onUnload() async {
    isInitialized = false;
  }
  
  @override
  Future<void> onActivate() async {
    // Default implementation
  }
  
  @override
  Future<void> onDeactivate() async {
    // Default implementation
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    // Default implementation
  }
  
  @override
  Widget? getConfigWidget() {
    return null;
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      'initialized': isInitialized,
      'metadata': {
        'id': metadata.id,
        'name': metadata.name,
        'version': metadata.version,
        'type': metadata.type.name,
      },
    };
  }
}

/// Syntax plugin implementation
class SyntaxPluginImpl extends BasePlugin {
  SyntaxPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: Register syntax rules
  }
}

/// Renderer plugin implementation
class RendererPluginImpl extends BasePlugin {
  RendererPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: Register renderer
  }
}

/// Theme plugin implementation
class ThemePluginImpl extends BasePlugin {
  ThemePluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: Register theme
  }
}

/// Export plugin implementation
class ExporterPluginImpl extends BasePlugin {
  ExporterPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: Register exporter
  }
}

/// Tool plugin implementation
class ToolPluginImpl extends BasePlugin {
  ToolPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: Register tool
  }
}

/// Integration plugin implementation
class IntegrationPluginImpl extends BasePlugin {
  IntegrationPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: Register integration features
  }
}

/// Improved Mermaid plugin proxy implementation
class _ImprovedMermaidPluginProxy extends BasePlugin {
  _ImprovedMermaidPluginProxy(super.metadata);
  
  Map<String, dynamic> _config = {
    'theme': 'default',
    'enableInteraction': true,
    'defaultWidth': 800.0,
    'defaultHeight': 600.0,
  };
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    
    // Register Mermaid block syntax
    context.syntaxRegistry.registerBlockSyntax(
      'mermaid',
      RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true),
      (content) {
        final syntax = ImprovedMermaidBlockSyntax(_config);
        return syntax.parseBlock(content);
      },
    );
    
    // Register toolbar button
    context.toolbarRegistry.registerAction(
      const PluginAction(
        id: 'mermaid',
        title: 'Mermaid图表',
        description: '插入Mermaid图表代码块',
        icon: 'account_tree',
      ),
      () {
        // Insert Mermaid code block template
        final template = '''```mermaid
graph TD
    A[开始] --> B{判断条件}
    B -->|是| C[执行操作]
    B -->|否| D[结束]
    C --> D
```''';
        context.editorController.insertText(template);
      },
    );
    
    debugPrint('改进的Mermaid插件已加载');
  }
  
  @override
  Future<void> onUnload() async {
    await super.onUnload();
    debugPrint('改进的Mermaid插件已卸载');
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    _config = {..._config, ...config};
  }
  
  @override
  Widget? getConfigWidget() {
    return MermaidConfigWidget();
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      ...super.getStatus(),
      'config': _config,
    };
  }
}

/// Mermaid plugin proxy implementation
class _MermaidPluginProxy extends BasePlugin {
  _MermaidPluginProxy(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    
    // Register Mermaid block syntax
    context.syntaxRegistry.registerBlockSyntax(
      'mermaid',
      RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true),
      (content) {
        final syntax = MermaidBlockSyntax();
        return syntax.parseBlock(content);
      },
    );
    
    // Register toolbar button
    context.toolbarRegistry.registerAction(
      const PluginAction(
        id: 'mermaid',
        title: 'Mermaid图表',
        description: '插入Mermaid图表代码块',
        icon: 'account_tree',
      ),
      () {
        // Insert Mermaid code block template
        final template = '''```mermaid
graph TD
    A[开始] --> B{判断条件}
    B -->|是| C[执行操作]
    B -->|否| D[结束]
    C --> D
```''';
        context.editorController.insertText(template);
      },
    );
    
    debugPrint('Mermaid插件已加载');
  }
  
  @override
  Future<void> onUnload() async {
    await super.onUnload();
    debugPrint('Mermaid插件已卸载');
  }
  
  @override
  Widget? getConfigWidget() {
    return MermaidConfigWidget();
  }
}

/// Improved Mermaid block syntax implementation
class ImprovedMermaidBlockSyntax {
  final Map<String, dynamic> config;
  
  ImprovedMermaidBlockSyntax(this.config);
  
  /// Check if matches Mermaid syntax
  bool canParse(String line) {
    return line.trim().startsWith('```mermaid');
  }
  
  /// Parse Mermaid code block
  Widget parseBlock(String content) {
    // Extract mermaid code
    final lines = content.split('\n');
    final codeLines = <String>[];
    bool inMermaidBlock = false;
    
    for (final line in lines) {
      if (line.trim().startsWith('```mermaid')) {
        inMermaidBlock = true;
        continue;
      }
      if (line.trim() == '```' && inMermaidBlock) {
        break;
      }
      if (inMermaidBlock) {
        codeLines.add(line);
      }
    }
    
    final mermaidCode = codeLines.join('\n');
    return ImprovedMermaidWidget(code: mermaidCode, config: config);
  }
}

/// Mermaid block syntax implementation
class MermaidBlockSyntax {
  /// Check if matches Mermaid syntax
  bool canParse(String line) {
    return line.trim().startsWith('```mermaid');
  }
  
  /// Parse Mermaid code block
  Widget parseBlock(String content) {
    // Extract mermaid code
    final lines = content.split('\n');
    final codeLines = <String>[];
    bool inMermaidBlock = false;
    
    for (final line in lines) {
      if (line.trim().startsWith('```mermaid')) {
        inMermaidBlock = true;
        continue;
      }
      if (line.trim() == '```' && inMermaidBlock) {
        break;
      }
      if (inMermaidBlock) {
        codeLines.add(line);
      }
    }
    
    final mermaidCode = codeLines.join('\n');
    return MermaidWidget(code: mermaidCode);
  }
}

/// Improved Mermaid rendering component
class ImprovedMermaidWidget extends StatefulWidget {
  const ImprovedMermaidWidget({
    super.key,
    required this.code,
    required this.config,
  });
  
  final String code;
  final Map<String, dynamic> config;
  
  @override
  State<ImprovedMermaidWidget> createState() => _ImprovedMermaidWidgetState();
}

class _ImprovedMermaidWidgetState extends State<ImprovedMermaidWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_generateHtml());
  }

  String _generateHtml() {
    final theme = widget.config['theme'] ?? 'default';
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mermaid Chart</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: transparent;
        }
        .mermaid {
            text-align: center;
            max-width: 100%;
            overflow: auto;
        }
        .error {
            color: #d32f2f;
            background: #ffebee;
            padding: 16px;
            border-radius: 4px;
            border-left: 4px solid #d32f2f;
        }
    </style>
</head>
<body>
    <div id="mermaid-container">
        <div class="mermaid">
${widget.code}
        </div>
    </div>
    
    <script>
        mermaid.initialize({
            theme: '$theme',
            startOnLoad: true,
            securityLevel: 'loose',
            flowchart: {
                useMaxWidth: true,
                htmlLabels: true
            }
        });
        
        // Error handling
        window.addEventListener('error', function(e) {
            document.getElementById('mermaid-container').innerHTML = 
                '<div class="error">图表渲染失败: ' + e.message + '</div>';
        });
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.red.shade50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Mermaid渲染错误',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: (widget.config['defaultHeight'] ?? 400).toDouble(),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mermaid rendering component
class MermaidWidget extends StatefulWidget {
  const MermaidWidget({
    super.key,
    required this.code,
    this.theme = 'default',
    this.width,
    this.height,
  });
  
  final String code;
  final String theme;
  final double? width;
  final double? height;
  
  @override
  State<MermaidWidget> createState() => _MermaidWidgetState();
}

class _MermaidWidgetState extends State<MermaidWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 400,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildWebView(),
      ),
    );
  }
  
  Widget _buildWebView() {
    // Need to implement WebView to render Mermaid here
    // Due to WebView complexity, use placeholder here first
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Mermaid图表',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '代码长度: ${widget.code.length} 字符',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mermaid configuration component
class MermaidConfigWidget extends StatefulWidget {
  const MermaidConfigWidget({super.key});
  
  @override
  State<MermaidConfigWidget> createState() => _MermaidConfigWidgetState();
}

class _MermaidConfigWidgetState extends State<MermaidConfigWidget> {
  String _selectedTheme = 'default';
  bool _enableInteraction = true;
  double _defaultWidth = 800;
  double _defaultHeight = 600;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mermaid插件配置',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Theme selection
          Text(
            '主题',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedTheme,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'default', child: Text('默认')),
              DropdownMenuItem(value: 'dark', child: Text('深色')),
              DropdownMenuItem(value: 'forest', child: Text('森林')),
              DropdownMenuItem(value: 'neutral', child: Text('中性')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTheme = value ?? 'default';
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Interaction options
          SwitchListTile(
            title: const Text('启用交互'),
            subtitle: const Text('允许用户与图表进行交互'),
            value: _enableInteraction,
            onChanged: (value) {
              setState(() {
                _enableInteraction = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Default dimensions
          Text(
            '默认尺寸',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '宽度',
                    border: OutlineInputBorder(),
                    suffixText: 'px',
                  ),
                  initialValue: _defaultWidth.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _defaultWidth = double.tryParse(value) ?? 800;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '高度',
                    border: OutlineInputBorder(),
                    suffixText: 'px',
                  ),
                  initialValue: _defaultHeight.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _defaultHeight = double.tryParse(value) ?? 600;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Plugin element in markdown content
class PluginElement {
  const PluginElement({
    required this.name,
    required this.startIndex,
    required this.endIndex,
    required this.content,
    required this.widget,
    required this.isBlock,
  });

  /// Plugin rule name
  final String name;
  
  /// Start position in content
  final int startIndex;
  
  /// End position in content
  final int endIndex;
  
  /// Original content
  final String content;
  
  /// Rendered widget
  final Widget widget;
  
  /// Whether this is a block-level plugin
  final bool isBlock;

  @override
  String toString() {
    return 'PluginElement(name: $name, range: $startIndex-$endIndex, isBlock: $isBlock)';
  }
}

/// Working Mermaid plugin with proper WebView implementation
class _WorkingMermaidPlugin extends BasePlugin {
  _WorkingMermaidPlugin(super.metadata);
  
  Map<String, dynamic> _config = {
    'theme': 'default',
    'enableInteraction': true,
    'defaultWidth': 800.0,
    'defaultHeight': 600.0,
  };
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    
    // Register Mermaid block syntax
    context.syntaxRegistry.registerBlockSyntax(
      'mermaid',
      RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true),
      (content) {
        final syntax = WorkingMermaidBlockSyntax(_config);
        return syntax.parseBlock(content);
      },
    );
    
    // Register toolbar button
    context.toolbarRegistry.registerAction(
      const PluginAction(
        id: 'mermaid',
        title: 'Mermaid图表',
        description: '插入Mermaid图表代码块',
        icon: 'account_tree',
      ),
      () {
        // Insert Mermaid code block template
        final template = '''```mermaid
graph TD
    A[开始] --> B{判断条件}
    B -->|是| C[执行操作]
    B -->|否| D[结束]
    C --> D
```''';
        // Get the latest editor controller from the plugin context service
        final contextService = PluginContextService.instance;
        final currentContext = contextService.context;
        debugPrint('Mermaid plugin executing with controller: ${currentContext.editorController.runtimeType}');
        currentContext.editorController.insertText(template);
      },
    );
    
    debugPrint('Working Mermaid插件已加载');
  }
  
  @override
  Future<void> onUnload() async {
    await super.onUnload();
    debugPrint('Working Mermaid插件已卸载');
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    _config = {..._config, ...config};
  }
  
  @override
  Widget? getConfigWidget() {
    return WorkingMermaidConfigWidget();
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      ...super.getStatus(),
      'config': _config,
    };
  }
}

/// Working Mermaid block syntax implementation
class WorkingMermaidBlockSyntax {
  final Map<String, dynamic> config;
  
  WorkingMermaidBlockSyntax(this.config);
  
  /// Parse Mermaid code block
  Widget parseBlock(String content) {
    // Extract mermaid code
    final lines = content.split('\n');
    final codeLines = <String>[];
    bool inMermaidBlock = false;
    
    for (final line in lines) {
      if (line.trim().startsWith('```mermaid')) {
        inMermaidBlock = true;
        continue;
      }
      if (line.trim() == '```' && inMermaidBlock) {
        break;
      }
      if (inMermaidBlock) {
        codeLines.add(line);
      }
    }
    
    final mermaidCode = codeLines.join('\n');
    return WorkingMermaidWidget(code: mermaidCode, config: config);
  }
}

/// Working Mermaid rendering component with WebView
class WorkingMermaidWidget extends StatefulWidget {
  const WorkingMermaidWidget({
    super.key,
    required this.code,
    required this.config,
  });
  
  final String code;
  final Map<String, dynamic> config;
  
  @override
  State<WorkingMermaidWidget> createState() => _WorkingMermaidWidgetState();
}

class _WorkingMermaidWidgetState extends State<WorkingMermaidWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_generateHtml());
  }

  String _generateHtml() {
    final theme = widget.config['theme'] ?? 'default';
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Mermaid Chart</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: transparent;
            overflow: hidden;
        }
        .mermaid {
            text-align: center;
            max-width: 100%;
            overflow: visible;
        }
        .error {
            color: #d32f2f;
            background: #ffebee;
            padding: 16px;
            border-radius: 4px;
            border-left: 4px solid #d32f2f;
        }
        svg {
            max-width: 100%;
            height: auto;
        }
    </style>
</head>
<body>
    <div id="mermaid-container">
        <div class="mermaid">
${widget.code}
        </div>
    </div>
    
    <script>
        mermaid.initialize({
            theme: '$theme',
            startOnLoad: true,
            securityLevel: 'loose',
            flowchart: {
                useMaxWidth: true,
                htmlLabels: true,
                curve: 'basis'
            },
            sequence: {
                useMaxWidth: true,
                wrap: true
            },
            gantt: {
                useMaxWidth: true
            }
        });
        
        // Handle errors
        window.addEventListener('error', function(e) {
            console.error('Mermaid error:', e);
            document.getElementById('mermaid-container').innerHTML = 
                '<div class="error">图表渲染失败: ' + e.message + '</div>';
        });
        
        // Auto-resize
        window.addEventListener('resize', function() {
            mermaid.init(undefined, '.mermaid');
        });
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.red.shade50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Mermaid渲染错误',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: (widget.config['defaultHeight'] ?? 400).toDouble(),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Working Mermaid configuration component
class WorkingMermaidConfigWidget extends StatefulWidget {
  const WorkingMermaidConfigWidget({super.key});
  
  @override
  State<WorkingMermaidConfigWidget> createState() => _WorkingMermaidConfigWidgetState();
}

class _WorkingMermaidConfigWidgetState extends State<WorkingMermaidConfigWidget> {
  String _selectedTheme = 'default';
  bool _enableInteraction = true;
  double _defaultWidth = 800;
  double _defaultHeight = 400;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mermaid插件配置',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Theme selection
          Text(
            '主题',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedTheme,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'default', child: Text('默认')),
              DropdownMenuItem(value: 'dark', child: Text('深色')),
              DropdownMenuItem(value: 'forest', child: Text('森林')),
              DropdownMenuItem(value: 'neutral', child: Text('中性')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTheme = value ?? 'default';
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Height setting
          Text(
            '默认高度',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Slider(
            value: _defaultHeight,
            min: 200,
            max: 800,
            divisions: 12,
            label: '${_defaultHeight.round()}px',
            onChanged: (value) {
              setState(() {
                _defaultHeight = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Interaction toggle
          SwitchListTile(
            title: const Text('启用交互'),
            subtitle: const Text('允许用户与图表交互'),
            value: _enableInteraction,
            onChanged: (value) {
              setState(() {
                _enableInteraction = value;
              });
            },
          ),
        ],
      ),
    );
  }
}