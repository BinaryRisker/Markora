import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:markora/types/plugin.dart';
import 'package:markora/features/plugins/domain/plugin_interface.dart';

/// Mermaid plugin implementation
class MermaidPlugin extends BasePlugin {
  MermaidPlugin(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;
  
  Map<String, dynamic> _config = {
    'theme': 'default',
    'enableInteraction': true,
    'defaultWidth': 800.0,
    'defaultHeight': 600.0,
  };
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    
    try {
      // Register toolbar button
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'mermaid',
          title: 'Mermaid Chart',
          description: 'Insert Mermaid chart code block',
          icon: 'account_tree',
        ),
        () {
          final template = '''```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Execute]
    B -->|No| D[End]
    C --> D
```''';
          context.editorController.insertText(template);
        },
      );
      
      // Register mermaid syntax
      context.syntaxRegistry.registerBlockSyntax(
        'mermaid',
        RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true),
        (content) {
          final extractedCode = _extractMermaidCode(content);
          return MermaidWidget(code: extractedCode, config: _config);
        },
      );
      
      debugPrint('Mermaid plugin loaded successfully');
    } catch (e) {
      debugPrint('Failed to load Mermaid plugin: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> onUnload() async {
    try {
      // Clean up registrations would be handled by the plugin system
      debugPrint('Mermaid plugin unloaded');
    } catch (e) {
      debugPrint('Error unloading Mermaid plugin: $e');
    }
    
    await super.onUnload();
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    _config = {..._config, ...config};
  }
  
  @override
  Widget? getConfigWidget() {
    return MermaidConfigWidget(config: _config);
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      ...super.getStatus(),
      'config': _config,
    };
  }
  
  /// Extract mermaid code from markdown content
  String _extractMermaidCode(String content) {
    final mermaidRegex = RegExp(r'^```mermaid\s*\n([\s\S]*?)\n```', multiLine: true);
    final match = mermaidRegex.firstMatch(content);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    
    // Fallback: line-by-line extraction
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
    
    return codeLines.join('\n').trim();
  }
}

/// Mermaid rendering widget
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
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    }
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
            background: white;
        }
        .mermaid {
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="mermaid">
\${widget.code}
    </div>
    <script>
        mermaid.initialize({
            startOnLoad: true,
            theme: '$theme',
            securityLevel: 'loose',
            flowchart: {
                useMaxWidth: true,
                htmlLabels: true
            }
        });
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        height: widget.config['defaultHeight']?.toDouble() ?? 400,
        width: widget.config['defaultWidth']?.toDouble() ?? 600,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Mermaid charts are not supported in web mode',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              'Error loading Mermaid chart',
              style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: widget.config['defaultHeight']?.toDouble() ?? 400,
      width: widget.config['defaultWidth']?.toDouble() ?? 600,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}

/// Mermaid configuration widget
class MermaidConfigWidget extends StatefulWidget {
  const MermaidConfigWidget({super.key, required this.config});
  
  final Map<String, dynamic> config;
  
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
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mermaid Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Theme selection
        const Text('Theme:'),
        DropdownButton<String>(
          value: _config['theme'] as String,
          items: const [
            DropdownMenuItem(value: 'default', child: Text('Default')),
            DropdownMenuItem(value: 'dark', child: Text('Dark')),
            DropdownMenuItem(value: 'forest', child: Text('Forest')),
            DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _config['theme'] = value;
              });
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Enable interaction
        CheckboxListTile(
          title: const Text('Enable Interaction'),
          value: _config['enableInteraction'] as bool,
          onChanged: (value) {
            setState(() {
              _config['enableInteraction'] = value ?? true;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Default dimensions
        Text('Default Width: ${(_config['defaultWidth'] as double).toInt()}'),
        Slider(
          value: _config['defaultWidth'] as double,
          min: 400,
          max: 1200,
          divisions: 8,
          onChanged: (value) {
            setState(() {
              _config['defaultWidth'] = value;
            });
          },
        ),
        
        Text('Default Height: ${(_config['defaultHeight'] as double).toInt()}'),
        Slider(
          value: _config['defaultHeight'] as double,
          min: 300,
          max: 800,
          divisions: 10,
          onChanged: (value) {
            setState(() {
              _config['defaultHeight'] = value;
            });
          },
        ),
      ],
    );
  }
}