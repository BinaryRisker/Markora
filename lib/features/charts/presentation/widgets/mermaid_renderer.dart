import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

import '../../../../types/charts.dart';

/// Mermaid图表渲染器
class MermaidRenderer extends StatefulWidget {
  const MermaidRenderer({
    super.key,
    required this.chart,
    this.renderOptions,
    this.onError,
  });

  /// Mermaid图表
  final MermaidChart chart;
  
  /// 渲染选项
  final MermaidRenderOptions? renderOptions;
  
  /// 错误回调
  final ValueChanged<String>? onError;

  @override
  State<MermaidRenderer> createState() => _MermaidRendererState();
}

class _MermaidRendererState extends State<MermaidRenderer> {
  late WebViewController _controller;
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
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _renderMermaidChart();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = error.description;
              _isLoading = false;
            });
            widget.onError?.call(error.description);
          },
        ),
      );
      
    _loadHtmlContent();
  }

  void _loadHtmlContent() {
    final htmlContent = _generateHtml();
    _controller.loadHtmlString(htmlContent);
  }

  String _generateHtml() {
    final backgroundColor = widget.renderOptions?.backgroundColor ?? '#ffffff';
    final theme = widget.renderOptions?.theme ?? 'default';
    
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
            padding: 16px;
            background-color: $backgroundColor;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            overflow: auto;
        }
        
        .mermaid-container {
            width: 100%;
            height: auto;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 200px;
        }
        
        .mermaid {
            max-width: 100%;
            height: auto;
        }
        
        .error {
            color: #d32f2f;
            background-color: #ffebee;
            border: 1px solid #ffcdd2;
            border-radius: 4px;
            padding: 16px;
            font-family: monospace;
            white-space: pre-wrap;
        }
        
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 200px;
            color: #666;
        }
    </style>
</head>
<body>
    <div id="loading" class="loading">正在加载图表...</div>
    <div id="error" class="error" style="display: none;"></div>
    <div id="mermaid-container" class="mermaid-container">
        <div class="mermaid" id="mermaid-chart"></div>
    </div>

    <script>
        // 配置Mermaid
        mermaid.initialize({
            startOnLoad: false,
            theme: '$theme',
            securityLevel: 'loose',
            fontFamily: '"Helvetica Neue", Arial, sans-serif',
            fontSize: 14,
            flowchart: {
                useMaxWidth: true,
                htmlLabels: true,
                curve: 'linear'
            },
            sequence: {
                useMaxWidth: true,
                showSequenceNumbers: true
            },
            gantt: {
                useMaxWidth: true,
                fontSize: 12
            }
        });

        // 渲染图表的函数
        function renderChart(chartCode) {
            const loadingEl = document.getElementById('loading');
            const errorEl = document.getElementById('error');
            const chartEl = document.getElementById('mermaid-chart');
            
            // 隐藏加载和错误信息
            loadingEl.style.display = 'none';
            errorEl.style.display = 'none';
            
            try {
                // 清空之前的内容
                chartEl.innerHTML = '';
                
                // 渲染Mermaid图表
                mermaid.render('mermaid-svg', chartCode).then((result) => {
                    chartEl.innerHTML = result.svg;
                    
                    // 通知Flutter渲染完成
                    window.postMessage({
                        type: 'mermaid-rendered',
                        success: true
                    }, '*');
                }).catch((error) => {
                    console.error('Mermaid render error:', error);
                    showError('图表渲染失败: ' + error.message);
                    
                    // 通知Flutter渲染失败
                    window.postMessage({
                        type: 'mermaid-rendered',
                        success: false,
                        error: error.message
                    }, '*');
                });
            } catch (error) {
                console.error('Mermaid error:', error);
                showError('图表解析失败: ' + error.message);
                
                // 通知Flutter渲染失败
                window.postMessage({
                    type: 'mermaid-rendered',
                    success: false,
                    error: error.message
                }, '*');
            }
        }
        
        function showError(message) {
            const loadingEl = document.getElementById('loading');
            const errorEl = document.getElementById('error');
            
            loadingEl.style.display = 'none';
            errorEl.style.display = 'block';
            errorEl.textContent = message;
        }
        
        // 页面加载完成后的回调
        window.onload = function() {
            // 通知Flutter页面已准备就绪
            window.postMessage({
                type: 'mermaid-ready'
            }, '*');
        };
    </script>
</body>
</html>
    ''';
  }

  void _renderMermaidChart() async {
    if (_error != null) return;
    
    try {
      // 转义图表代码中的特殊字符
      final escapedCode = widget.chart.content
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '');
      
      // 调用JavaScript函数渲染图表
      await _controller.runJavaScript('renderChart("$escapedCode");');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      widget.onError?.call(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    return Stack(
      children: [
        // WebView
        WebViewWidget(controller: _controller),
        
        // 加载指示器
        if (_isLoading)
          Container(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在渲染图表...'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '图表渲染失败',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '未知错误',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _loadHtmlContent();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 简化的Mermaid图表渲染组件（用于小尺寸预览）
class SimpleMermaidRenderer extends StatelessWidget {
  const SimpleMermaidRenderer({
    super.key,
    required this.code,
    this.width,
    this.height,
    this.theme = 'default',
  });

  /// Mermaid代码
  final String code;
  
  /// 宽度
  final double? width;
  
  /// 高度
  final double? height;
  
  /// 主题
  final String theme;

  @override
  Widget build(BuildContext context) {
    final chart = MermaidChart(
      type: MermaidChartType.flowchart,
      content: code,
      rawContent: '```mermaid\n$code\n```',
      startIndex: 0,
      endIndex: code.length,
    );

    return SizedBox(
      width: width,
      height: height ?? 200,
      child: MermaidRenderer(
        chart: chart,
        renderOptions: MermaidRenderOptions(
          width: width,
          height: height,
          theme: theme,
        ),
      ),
    );
  }
} 