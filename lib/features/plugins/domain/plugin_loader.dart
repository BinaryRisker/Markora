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
import 'entities/pandoc_plugin.dart';

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
      debugPrint('Failed to load plugin metadata: $e');
      return null;
    }
  }
  
  /// Load plugin instance
  Future<MarkoraPlugin?> loadPlugin(Plugin plugin) async {
    try {
      debugPrint('Loading plugin: ${plugin.metadata.id} with installPath: ${plugin.installPath}');
      
      // Skip directory checks for built-in plugins in web environment
      if (plugin.installPath == null) {
        throw Exception('Plugin install path is empty');
      }
      
      // Check if it's a built-in plugin (virtual path)
      final isBuiltInPlugin = plugin.installPath!.startsWith('builtin://');
      
      if (!isBuiltInPlugin) {
        final pluginDir = Directory(plugin.installPath!);
        if (!await pluginDir.exists()) {
          throw Exception('Plugin directory does not exist: ${plugin.installPath}');
        }
      } else {
        debugPrint('Built-in plugin detected, skipping directory checks');
      }
      
      // Load different plugin implementations based on plugin type
      switch (plugin.metadata.type) {
        case PluginType.syntax:
          return await _loadSyntaxPlugin(plugin);
        case PluginType.renderer:
          return await _loadRendererPlugin(plugin);
        case PluginType.theme:
          return await _loadThemePlugin(plugin);
        case PluginType.export:
        case PluginType.exporter:
          return await _loadExporterPlugin(plugin);
        case PluginType.tool:
          return await _loadToolPlugin(plugin);
        case PluginType.integration:
          return await _loadIntegrationPlugin(plugin);
        default:
          throw Exception('Unsupported plugin type: ${plugin.metadata.type}');
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load plugin ${plugin.metadata.id}: $e');
      debugPrint('Stack trace: $stackTrace');
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
      debugPrint('Failed to load syntax plugin: $e');
      return null;
    }
  }
  
  /// Load renderer plugin
  Future<MarkoraPlugin?> _loadRendererPlugin(Plugin plugin) async {
    try {
      // Check if it's a Mermaid plugin
      if (plugin.metadata.id == 'mermaid_plugin') {
        // For built-in plugins, skip file system checks
        final isBuiltInPlugin = plugin.installPath!.startsWith('builtin://');
        
        if (isBuiltInPlugin) {
          debugPrint('Built-in mermaid plugin detected');
          return _createMermaidPlugin(plugin.metadata);
        } else {
          // Dynamically import Mermaid plugin
          final pluginMainFile = File(path.join(plugin.installPath!, 'lib', 'main.dart'));
          if (await pluginMainFile.exists()) {
            // Here we directly instantiate MermaidPlugin
            // In actual projects, might need to use dart:mirrors or other dynamic loading mechanisms
            return _createMermaidPlugin(plugin.metadata);
          }
        }
      }
      
      // Default renderer plugin implementation
      return RendererPluginImpl(plugin.metadata);
    } catch (e, stackTrace) {
      debugPrint('Failed to load renderer plugin: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Create Mermaid plugin instance
  MarkoraPlugin _createMermaidPlugin(PluginMetadata metadata) {
    // Import the actual MermaidPlugin
    try {
      debugPrint('_createMermaidPlugin called with metadata: ${metadata.id}');
      debugPrint('kIsWeb: $kIsWeb');
      
      // For web environment, use the most simplified version
      if (kIsWeb) {
        debugPrint('Web environment: Creating minimal mermaid plugin');
        final plugin = _MinimalWebMermaidPlugin(metadata);
        debugPrint('Minimal mermaid plugin created successfully: ${plugin.runtimeType}');
        return plugin;
      }
      
      // Use the improved MermaidPlugin with proper WebView implementation
      debugPrint('Desktop environment: Creating working mermaid plugin');
      final plugin = _WorkingMermaidPlugin(metadata);
      debugPrint('Working mermaid plugin created successfully: ${plugin.runtimeType}');
      return plugin;
    } catch (e, stackTrace) {
      debugPrint('Failed to create MermaidPlugin: $e');
      debugPrint('Stack trace: $stackTrace');
      return _ImprovedMermaidPluginProxy(metadata);
    }
  }
  
  /// Create Pandoc export plugin instance
  MarkoraPlugin _createPandocExportPlugin(PluginMetadata metadata) {
    try {
      debugPrint('_createPandocExportPlugin called with metadata: ${metadata.id}');
      
      // Create PandocExportPlugin instance
      final plugin = PandocExportPlugin();
      debugPrint('Pandoc export plugin created successfully: ${plugin.runtimeType}');
      return plugin;
    } catch (e, stackTrace) {
      debugPrint('Failed to create PandocExportPlugin: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Fallback to default implementation
      return ExporterPluginImpl(metadata);
    }
  }
  
  /// Load theme plugin
  Future<MarkoraPlugin?> _loadThemePlugin(Plugin plugin) async {
    // TODO: Implement theme plugin loading logic
    return ThemePluginImpl(plugin.metadata);
  }
  
  /// Load export plugin
  Future<MarkoraPlugin?> _loadExporterPlugin(Plugin plugin) async {
    try {
      // Check if it's a Pandoc export plugin
      if (plugin.metadata.id == 'pandoc_export_plugin') {
        // Import the actual PandocExportPlugin
        return _createPandocExportPlugin(plugin.metadata);
      }
      
      // Default export plugin implementation
      return ExporterPluginImpl(plugin.metadata);
    } catch (e) {
      debugPrint('Failed to load export plugin: $e');
      return ExporterPluginImpl(plugin.metadata);
    }
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
      case 'export':
        return PluginType.export;
      case 'exporter':
        return PluginType.exporter;
      case 'tool':
        return PluginType.tool;
      case 'integration':
        return PluginType.integration;
      default:
        throw Exception('Unknown plugin type: $typeString');
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
      debugPrint('Failed to validate plugin: $e');
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
        title: 'Mermaid Chart',
        description: 'Insert Mermaid chart code block',
        icon: 'account_tree',
      ),
      () {
        // Insert Mermaid code block template
        final template = '''```mermaid
graph TD
    A[Start] --> B{Condition}
    B -->|Yes| C[Execute]
    B -->|No| D[End]
    C --> D
```''';
        context.editorController.insertText(template);
      },
    );
    
    debugPrint('Improved Mermaid plugin loaded');
  }
  
  @override
  Future<void> onUnload() async {
    await super.onUnload();
    debugPrint('Improved Mermaid plugin unloaded');
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
        title: 'Mermaid Chart',
        description: 'Insert Mermaid chart code block',
        icon: 'account_tree',
      ),
      () {
        // Insert Mermaid code block template
        final template = '''```mermaid
graph TD
    A[Start] --> B{Condition}
    B -->|Yes| C[Execute]
    B -->|No| D[End]
    C --> D
```''';
        context.editorController.insertText(template);
      },
    );
    
    debugPrint('Mermaid plugin loaded');
  }
  
  @override
  Future<void> onUnload() async {
    await super.onUnload();
    debugPrint('Mermaid plugin unloaded');
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
                '<div class="error">Chart rendering failed: ' + e.message + '</div>';
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
              'Mermaid rendering error',
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
              'Mermaid Chart',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Code length: ${widget.code.length} characters',
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
            'Mermaid Plugin Configuration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Theme selection
          Text(
            'Theme',
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
              DropdownMenuItem(value: 'default', child: Text('Default')),
              DropdownMenuItem(value: 'dark', child: Text('Dark')),
              DropdownMenuItem(value: 'forest', child: Text('Forest')),
              DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
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
            title: const Text('Enable Interaction'),
            subtitle: const Text('Allow users to interact with charts'),
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
            'Default Size',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Width',
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
                    labelText: 'Height',
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

/// Minimal web Mermaid plugin (testing only)
class _MinimalWebMermaidPlugin extends BasePlugin {
  _MinimalWebMermaidPlugin(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    try {
      debugPrint('Minimal Web Mermaid plugin: Starting onLoad');
      
      // Test basic access to context properties without using them
      debugPrint('Context editor controller type: ${context.editorController.runtimeType}');
      debugPrint('Context syntax registry type: ${context.syntaxRegistry.runtimeType}');
      debugPrint('Context toolbar registry type: ${context.toolbarRegistry.runtimeType}');
      debugPrint('Context menu registry type: ${context.menuRegistry.runtimeType}');
      
      // Register toolbar button to test
      debugPrint('Registering toolbar action...');
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'mermaid',
          title: 'Mermaid Chart',
          description: 'Insert Mermaid chart code block',
          icon: 'account_tree',
        ),
        () {
          try {
            debugPrint('Minimal Mermaid button clicked');
            // Insert Mermaid code block template
            final template = '''```mermaid
graph TD
    A[Start] --> B{Condition}
    B -->|Yes| C[Execute]
    B -->|No| D[End]
    C --> D
```''';
            debugPrint('Inserting mermaid template...');
            
            // Get the latest editor controller from the plugin context service
            final contextService = PluginContextService.instance;
            final currentContext = contextService.context;
            debugPrint('Using editor controller: ${currentContext.editorController.runtimeType}');
            currentContext.editorController.insertText(template);
            debugPrint('Template inserted successfully');
          } catch (e) {
            debugPrint('Mermaid button execution error: $e');
          }
        },
      );
      debugPrint('Toolbar action registered successfully');
      
      // Register mermaid syntax for web (simplified approach)
      debugPrint('Registering mermaid block syntax...');
      try {
        // Use a more flexible pattern that matches various mermaid block formats
        final mermaidPattern = RegExp(r'```mermaid\s*\n([\s\S]*?)\n```');
        context.syntaxRegistry.registerBlockSyntax(
          'mermaid',
          mermaidPattern,
          (content) {
            debugPrint('Mermaid block syntax triggered for content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
            final extractedCode = _extractMermaidCode(content);
            debugPrint('Extracted mermaid code: $extractedCode');
            return WebMermaidDisplayWidget(code: extractedCode);
          },
        );
        debugPrint('Mermaid block syntax registered successfully');
      } catch (e) {
        debugPrint('Failed to register mermaid syntax: $e');
      }
      
      await super.onLoad(context);
      debugPrint('Minimal Web Mermaid plugin loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('Minimal Web Mermaid plugin onLoad error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  @override
  Future<void> onUnload() async {
    await super.onUnload();
    debugPrint('Minimal Web Mermaid plugin unloaded');
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      ...super.getStatus(),
      'webOptimized': true,
      'minimal': true,
    };
  }
  
  /// Extract mermaid code from markdown content
  String _extractMermaidCode(String content) {
    debugPrint('Extracting mermaid code from: $content');
    
    // Try regex first for more reliable extraction
    final mermaidRegex = RegExp(r'```mermaid\s*\n([\s\S]*?)\n```');
    final match = mermaidRegex.firstMatch(content);
    if (match != null) {
      var extractedCode = match.group(1)?.trim() ?? '';
      debugPrint('Regex extraction result: $extractedCode');
      
      // Clean up potential encoding issues
      extractedCode = extractedCode
          .replaceAll(RegExp(r'[^\x20-\x7E\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      return extractedCode;
    }
    
    // Fallback: Simple line-by-line extraction
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
    
    final result = codeLines.join('\n').trim();
    debugPrint('Line-by-line extraction result: $result');
    
    // Clean up potential encoding issues
    final cleanedResult = result
        .replaceAll(RegExp(r'[^\x20-\x7E\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]'), '') // Keep only ASCII and CJK characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
    
    if (cleanedResult != result) {
      debugPrint('Cleaned mermaid code: $cleanedResult');
    }
    
    return cleanedResult;
  }
}

/// Web-optimized Mermaid plugin (without WebView)
class _WebMermaidPlugin extends BasePlugin {
  _WebMermaidPlugin(super.metadata);
  
  Map<String, dynamic> _config = {
    'theme': 'default',
    'enableInteraction': true,
    'defaultWidth': 800.0,
    'defaultHeight': 400.0,
  };
  
  @override
  Future<void> onLoad(PluginContext context) async {
    try {
      await super.onLoad(context);
      
      // Only register toolbar action for web - skip syntax registration to avoid namespace issues
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'mermaid',
          title: 'Mermaid Chart',
          description: 'Insert Mermaid chart code block',
          icon: 'account_tree',
        ),
        () {
          try {
            // Insert Mermaid code block template
            final template = '''```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Execute]
    B -->|No| D[End]
    C --> D
```''';
            // Get the latest editor controller from the plugin context service
            final contextService = PluginContextService.instance;
            final currentContext = contextService.context;
            debugPrint('Web Mermaid plugin executing with controller: ${currentContext.editorController.runtimeType}');
            currentContext.editorController.insertText(template);
          } catch (e) {
            debugPrint('Web Mermaid plugin execution error: $e');
          }
        },
      );
      
      debugPrint('Web Mermaid plugin loaded (no WebView, toolbar only)');
    } catch (e) {
      debugPrint('Web Mermaid plugin onLoad error: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> onUnload() async {
    await super.onUnload();
    debugPrint('Web Mermaid plugin unloaded');
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    _config = {..._config, ...config};
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      ...super.getStatus(),
      'config': _config,
      'webOptimized': true,
    };
  }
}

/// Web Mermaid block syntax implementation (no WebView)
class WebMermaidBlockSyntax {
  final Map<String, dynamic> config;
  
  WebMermaidBlockSyntax(this.config);
  
  /// Parse Mermaid code block for web
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
    return WebMermaidWidget(code: mermaidCode, config: config);
  }
}

/// Web-optimized Mermaid widget (fallback only)
class WebMermaidWidget extends StatelessWidget {
  const WebMermaidWidget({
    super.key,
    required this.code,
    required this.config,
  });
  
  final String code;
  final Map<String, dynamic> config;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: (config['defaultHeight'] ?? 400).toDouble(),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Mermaid Chart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chart functionality is limited in web environment, please use desktop version for full experience',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    try {
      await super.onLoad(context);
      
      // Only register syntax and toolbar for non-web platforms
      if (!kIsWeb) {
        // Register Mermaid block syntax
        context.syntaxRegistry.registerBlockSyntax(
          'mermaid',
          RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true),
          (content) {
            final syntax = WorkingMermaidBlockSyntax(_config);
            return syntax.parseBlock(content);
          },
        );
      }
      
      // Register toolbar button (works for both web and desktop)
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'mermaid',
          title: 'Mermaid Chart',
          description: 'Insert Mermaid chart code block',
          icon: 'account_tree',
        ),
        () {
          try {
            // Insert Mermaid code block template
            final template = '''```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Execute]
    B -->|No| D[End]
    C --> D
```''';
            // Get the latest editor controller from the plugin context service
            final contextService = PluginContextService.instance;
            final currentContext = contextService.context;
            debugPrint('Mermaid plugin executing with controller: ${currentContext.editorController.runtimeType}');
            currentContext.editorController.insertText(template);
          } catch (e) {
            debugPrint('Mermaid plugin execution error: $e');
          }
        },
      );
      
      debugPrint('Working Mermaid plugin loaded (kIsWeb: $kIsWeb)');
    } catch (e) {
      debugPrint('Working Mermaid plugin onLoad error: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> onUnload() async {
    await super.onUnload();
    debugPrint('Working Mermaid plugin unloaded');
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
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Only initialize WebView for non-web platforms
    if (!kIsWeb) {
      _initializeWebView();
    } else {
      // For web platforms, skip WebView initialization
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    if (kIsWeb) return; // Safety check
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _error = error.description;
                _isLoading = false;
              });
            }
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
                '<div class="error">Chart rendering failed: ' + e.message + '</div>';
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
              'Mermaid Rendering Error',
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

    // For web environment, provide a fallback rendering
    if (kIsWeb) {
      return _buildWebFallback();
    }

    // For non-web platforms, use WebView
    if (_controller != null) {
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
              WebViewWidget(controller: _controller!),
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

    // Fallback if controller is null
    return _buildWebFallback();
  }

  /// Build web fallback for mermaid rendering
  Widget _buildWebFallback() {
    return Container(
      height: (widget.config['defaultHeight'] ?? 400).toDouble(),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Mermaid Chart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  widget.code,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chart functionality is limited in web environment, please use desktop version for full experience',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            'Mermaid Plugin Configuration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Theme selection
          Text(
            'Theme',
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
              DropdownMenuItem(value: 'default', child: Text('Default')),
              DropdownMenuItem(value: 'dark', child: Text('Dark')),
              DropdownMenuItem(value: 'forest', child: Text('Forest')),
              DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
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
            'Default Height',
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
            title: const Text('Enable Interaction'),
            subtitle: const Text('Allow users to interact with charts'),
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

/// Web Mermaid display widget for syntax rendering
class WebMermaidDisplayWidget extends StatelessWidget {
  const WebMermaidDisplayWidget({
    super.key,
    required this.code,
  });
  
  final String code;
  
  @override
  Widget build(BuildContext context) {
    if (code.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: const Text(
          'Empty Mermaid diagram',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.account_tree,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mermaid Diagram',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Code display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 14,
                color: Colors.black87,
                fontFamilyFallback: [
                  'Monaco', 
                  'Menlo',
                  'Ubuntu Mono',
                  'Courier New', 
                  'Microsoft YaHei',
                  'SimSun',
                  'Arial',
                  'sans-serif'
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Info message
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Web environment shows code preview, desktop version can render full charts',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}