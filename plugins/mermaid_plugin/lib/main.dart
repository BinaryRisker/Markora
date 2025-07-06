import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../lib/features/plugins/domain/plugin_interface.dart';
import '../../../lib/types/plugin.dart';

/// Mermaid图表插件
class MermaidPlugin extends MarkoraPlugin {
  late PluginContext _context;
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;

  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'mermaid_plugin',
    name: 'Mermaid 图表插件',
    version: '1.0.0',
    description: '支持在Markdown中渲染Mermaid图表，包括流程图、序列图、甘特图等多种图表类型',
    author: 'Markora Team',
    homepage: 'https://github.com/markora/mermaid-plugin',
    repository: 'https://github.com/markora/mermaid-plugin.git',
    license: 'MIT',
    type: PluginType.syntax,
    tags: ['图表', 'mermaid', '可视化', '流程图'],
    minAppVersion: '1.0.0',
  );

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> onLoad(PluginContext context) async {
    _context = context;
    
    // 注册mermaid块级语法
    _context.syntaxRegistry.registerBlockSyntax(
      'mermaid',
      RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true),
      (content) => MermaidWidget(
        code: content,
        config: _config,
      ),
    );
    
    _isInitialized = true;
  }

  @override
  Future<void> onUnload() async {
    _isInitialized = false;
  }

  @override
  Future<void> onActivate() async {
    // 插件激活时的操作
  }

  @override
  Future<void> onDeactivate() async {
    // 插件停用时的操作
  }

  @override
  void onConfigChanged(Map<String, dynamic> config) {
    _config = config;
  }

  @override
  Widget? getConfigWidget() {
    return MermaidConfigWidget(
      config: _config,
      onConfigChanged: onConfigChanged,
    );
  }

  @override
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'theme': _config['theme'] ?? 'default',
      'interactionEnabled': _config['enableInteraction'] ?? true,
    };
  }
}

/// Mermaid图表渲染组件
class MermaidWidget extends StatefulWidget {
  const MermaidWidget({
    Key? key,
    required this.code,
    required this.config,
  }) : super(key: key);

  final String code;
  final Map<String, dynamic> config;

  @override
  State<MermaidWidget> createState() => _MermaidWidgetState();
}

class _MermaidWidgetState extends State<MermaidWidget> {
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
    final width = widget.config['defaultWidth'] ?? 800;
    final height = widget.config['defaultHeight'] ?? 600;
    
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
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Mermaid图表渲染失败',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      height: (widget.config['defaultHeight'] ?? 600).toDouble(),
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
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mermaid插件配置组件
class MermaidConfigWidget extends StatefulWidget {
  const MermaidConfigWidget({
    Key? key,
    required this.config,
    required this.onConfigChanged,
  }) : super(key: key);

  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onConfigChanged;

  @override
  State<MermaidConfigWidget> createState() => _MermaidConfigWidgetState();
}

class _MermaidConfigWidgetState extends State<MermaidConfigWidget> {
  late Map<String, dynamic> _config;

  @override
  void initState() {
    super.initState();
    _config = Map.from(widget.config);
  }

  void _updateConfig(String key, dynamic value) {
    setState(() {
      _config[key] = value;
    });
    widget.onConfigChanged(_config);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mermaid插件配置',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // 主题选择
          Text(
            '主题',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _config['theme'] ?? 'default',
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '选择主题',
            ),
            items: const [
              DropdownMenuItem(value: 'default', child: Text('默认')),
              DropdownMenuItem(value: 'dark', child: Text('深色')),
              DropdownMenuItem(value: 'forest', child: Text('森林')),
              DropdownMenuItem(value: 'neutral', child: Text('中性')),
            ],
            onChanged: (value) => _updateConfig('theme', value),
          ),
          const SizedBox(height: 16),
          
          // 启用交互
          SwitchListTile(
            title: const Text('启用交互'),
            subtitle: const Text('允许用户与图表进行交互'),
            value: _config['enableInteraction'] ?? true,
            onChanged: (value) => _updateConfig('enableInteraction', value),
          ),
          const SizedBox(height: 16),
          
          // 默认宽度
          Text(
            '默认宽度',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: (_config['defaultWidth'] ?? 800).toString(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入默认宽度（像素）',
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final width = int.tryParse(value);
              if (width != null) {
                _updateConfig('defaultWidth', width);
              }
            },
          ),
          const SizedBox(height: 16),
          
          // 默认高度
          Text(
            '默认高度',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: (_config['defaultHeight'] ?? 600).toString(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入默认高度（像素）',
              suffixText: 'px',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final height = int.tryParse(value);
              if (height != null) {
                _updateConfig('defaultHeight', height);
              }
            },
          ),
        ],
      ),
    );
  }
}