import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../types/plugin.dart';
import 'plugin_interface.dart';

/// 插件加载器
class PluginLoader {
  /// 从文件加载插件元数据
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
  
  /// 加载插件实例
  Future<MarkoraPlugin?> loadPlugin(Plugin plugin) async {
    try {
      if (plugin.installPath == null) {
        throw Exception('插件安装路径为空');
      }
      
      final pluginDir = Directory(plugin.installPath!);
      if (!await pluginDir.exists()) {
        throw Exception('插件目录不存在: ${plugin.installPath}');
      }
      
      // 根据插件类型加载不同的插件实现
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
  
  /// 加载语法扩展插件
  Future<MarkoraPlugin?> _loadSyntaxPlugin(Plugin plugin) async {
    // TODO: 实现语法插件加载逻辑
    // 这里可以加载Dart代码或JavaScript代码
    return SyntaxPluginImpl(plugin.metadata);
  }
  
  /// 加载渲染器插件
  Future<MarkoraPlugin?> _loadRendererPlugin(Plugin plugin) async {
    try {
      // 检查是否是Mermaid插件
      if (plugin.metadata.id == 'mermaid_plugin') {
        // 动态导入Mermaid插件
        final pluginMainFile = File(path.join(plugin.installPath!, 'lib', 'main.dart'));
        if (await pluginMainFile.exists()) {
          // 这里我们直接实例化MermaidPlugin
          // 在实际项目中，可能需要使用dart:mirrors或其他动态加载机制
          return _createMermaidPlugin(plugin.metadata);
        }
      }
      
      // 默认渲染器插件实现
      return RendererPluginImpl(plugin.metadata);
    } catch (e) {
      debugPrint('加载渲染器插件失败: $e');
      return null;
    }
  }
  
  /// 创建Mermaid插件实例
  MarkoraPlugin _createMermaidPlugin(PluginMetadata metadata) {
    // 导入真正的MermaidPlugin
    try {
      // 这里应该动态导入真正的MermaidPlugin
      // 由于Dart的限制，我们先用一个改进的代理实现
      return _ImprovedMermaidPluginProxy(metadata);
    } catch (e) {
      debugPrint('创建MermaidPlugin失败: $e');
      return _MermaidPluginProxy(metadata);
    }
  }
  
  /// 加载主题插件
  Future<MarkoraPlugin?> _loadThemePlugin(Plugin plugin) async {
    // TODO: 实现主题插件加载逻辑
    return ThemePluginImpl(plugin.metadata);
  }
  
  /// 加载导出插件
  Future<MarkoraPlugin?> _loadExporterPlugin(Plugin plugin) async {
    // TODO: 实现导出插件加载逻辑
    return ExporterPluginImpl(plugin.metadata);
  }
  
  /// 加载工具插件
  Future<MarkoraPlugin?> _loadToolPlugin(Plugin plugin) async {
    // TODO: 实现工具插件加载逻辑
    return ToolPluginImpl(plugin.metadata);
  }
  
  /// 加载集成插件
  Future<MarkoraPlugin?> _loadIntegrationPlugin(Plugin plugin) async {
    // TODO: 实现集成插件加载逻辑
    return IntegrationPluginImpl(plugin.metadata);
  }
  
  /// 解析插件类型
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
  
  /// 验证插件
  Future<bool> validatePlugin(Plugin plugin) async {
    try {
      if (plugin.installPath == null) return false;
      
      final pluginDir = Directory(plugin.installPath!);
      if (!await pluginDir.exists()) return false;
      
      // 检查必需文件
      final manifestFile = File(path.join(pluginDir.path, 'plugin.json'));
      if (!await manifestFile.exists()) return false;
      
      // 验证元数据
      final metadata = await loadPluginMetadata(manifestFile);
      if (metadata == null) return false;
      
      // TODO: 添加更多验证逻辑（签名验证、版本兼容性等）
      
      return true;
    } catch (e) {
      debugPrint('验证插件失败: $e');
      return false;
    }
  }
}

/// 基础插件实现
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
    // 默认实现
  }
  
  @override
  Future<void> onDeactivate() async {
    // 默认实现
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    // 默认实现
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

/// 语法插件实现
class SyntaxPluginImpl extends BasePlugin {
  SyntaxPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: 注册语法规则
  }
}

/// 渲染器插件实现
class RendererPluginImpl extends BasePlugin {
  RendererPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: 注册渲染器
  }
}

/// 主题插件实现
class ThemePluginImpl extends BasePlugin {
  ThemePluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: 注册主题
  }
}

/// 导出插件实现
class ExporterPluginImpl extends BasePlugin {
  ExporterPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: 注册导出器
  }
}

/// 工具插件实现
class ToolPluginImpl extends BasePlugin {
  ToolPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: 注册工具
  }
}

/// 集成插件实现
class IntegrationPluginImpl extends BasePlugin {
  IntegrationPluginImpl(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    // TODO: 注册集成功能
  }
}

/// 改进的Mermaid插件代理实现
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
    
    // 注册Mermaid块级语法
    context.syntaxRegistry.registerBlockSyntax(
      'mermaid',
      RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true),
      (content) {
        final syntax = ImprovedMermaidBlockSyntax(_config);
        return syntax.parseBlock(content);
      },
    );
    
    // 注册工具栏按钮
    context.toolbarRegistry.registerAction(
      PluginAction(
        id: 'mermaid',
        title: 'Mermaid图表',
        description: '插入Mermaid图表代码块',
        icon: 'account_tree',
      ),
      () {
        // 插入Mermaid代码块模板
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

/// Mermaid插件代理实现
class _MermaidPluginProxy extends BasePlugin {
  _MermaidPluginProxy(super.metadata);
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    
    // 注册Mermaid块级语法
    context.syntaxRegistry.registerBlockSyntax(
      'mermaid',
      RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true),
      (content) {
        final syntax = MermaidBlockSyntax();
        return syntax.parseBlock(content);
      },
    );
    
    // 注册工具栏按钮
    context.toolbarRegistry.registerAction(
      PluginAction(
        id: 'mermaid',
        title: 'Mermaid图表',
        description: '插入Mermaid图表代码块',
        icon: 'account_tree',
      ),
      () {
        // 插入Mermaid代码块模板
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

/// 改进的Mermaid块级语法实现
class ImprovedMermaidBlockSyntax {
  final Map<String, dynamic> config;
  
  ImprovedMermaidBlockSyntax(this.config);
  
  /// 检查是否匹配Mermaid语法
  bool canParse(String line) {
    return line.trim().startsWith('```mermaid');
  }
  
  /// 解析Mermaid代码块
  Widget parseBlock(String content) {
    // 提取mermaid代码
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

/// Mermaid块级语法实现
class MermaidBlockSyntax {
  /// 检查是否匹配Mermaid语法
  bool canParse(String line) {
    return line.trim().startsWith('```mermaid');
  }
  
  /// 解析Mermaid代码块
  Widget parseBlock(String content) {
    // 提取mermaid代码
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

/// 改进的Mermaid渲染组件
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
        
        // 错误处理
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

/// Mermaid渲染组件
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
    // 这里需要实现WebView来渲染Mermaid
    // 由于WebView的复杂性，这里先用占位符
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

/// Mermaid配置组件
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
          
          // 主题选择
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
          
          // 交互选项
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
          
          // 默认尺寸
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