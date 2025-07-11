import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:markora/features/plugins/domain/plugin_interface.dart';
import 'package:markora/types/plugin.dart';

/// Mermaid chart plugin
class MermaidPlugin extends MarkoraPlugin {
  late PluginContext _context;
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;

  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'mermaid_plugin',
    name: 'Mermaid Chart Plugin',
    version: '1.0.0',
    description: 'Support rendering Mermaid charts in Markdown, including flowcharts, sequence diagrams, Gantt charts and other chart types',
    author: 'Markora Team',
    homepage: 'https://github.com/markora/mermaid-plugin',
    repository: 'https://github.com/markora/mermaid-plugin.git',
    license: 'MIT',
    type: PluginType.syntax,
    tags: ['chart', 'mermaid', 'visualization', 'flowchart'],
    minVersion: '1.0.0',
  );

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> onLoad(PluginContext context) async {
    _context = context;
    
    // Register mermaid block syntax
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
    // Operations when plugin is activated
  }

  @override
  Future<void> onDeactivate() async {
    // Operations when plugin is deactivated
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

/// Mermaid chart rendering component
class MermaidWidget extends StatefulWidget {
  const MermaidWidget({
    super.key,
    required this.code,
    required this.config,
  });

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
                  'Mermaid Chart Rendering Failed',
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

/// Mermaid plugin configuration component
class MermaidConfigWidget extends StatefulWidget {
  const MermaidConfigWidget({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

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
            'Mermaid Plugin Configuration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // Theme selection
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _config['theme'] ?? 'default',
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select theme',
            ),
            items: const [
              DropdownMenuItem(value: 'default', child: Text('Default')),
              DropdownMenuItem(value: 'dark', child: Text('Dark')),
              DropdownMenuItem(value: 'forest', child: Text('Forest')),
              DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
            ],
            onChanged: (value) => _updateConfig('theme', value),
          ),
          const SizedBox(height: 16),
          
          // Enable interaction
          SwitchListTile(
            title: const Text('Enable Interaction'),
            subtitle: const Text('Allow users to interact with charts'),
            value: _config['enableInteraction'] ?? true,
            onChanged: (value) => _updateConfig('enableInteraction', value),
          ),
          const SizedBox(height: 16),
          
          // Default width
          Text(
            'Default Width',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: (_config['defaultWidth'] ?? 800).toString(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter default width (pixels)',
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
          
          // Default height
          Text(
            'Default Height',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: (_config['defaultHeight'] ?? 600).toString(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter default height (pixels)',
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