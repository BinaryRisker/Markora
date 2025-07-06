import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

import '../../../../types/charts.dart';

/// Mermaid渲染器 - 使用WebView渲染真正的Mermaid图表
class MermaidRenderer extends StatefulWidget {
  const MermaidRenderer({
    super.key,
    required this.chart,
    this.height = 400,
    this.theme = 'default',
    this.onError,
  });

  final MermaidChart chart;
  final double height;
  final String theme;
  final ValueChanged<String>? onError;

  @override
  State<MermaidRenderer> createState() => _MermaidRendererState();
}

class _MermaidRendererState extends State<MermaidRenderer> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // 更新加载进度
            },
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
              _renderMermaid();
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
              widget.onError?.call(error.description);
            },
          ),
        )
        ..loadHtmlString(_generateHtmlContent());
    } catch (e) {
      // WebView初始化失败，通知父组件
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'WebView初始化失败: $e';
          });
        }
      });
      widget.onError?.call('WebView不可用，将使用备用渲染器');
    }
  }

  /// 生成包含Mermaid的HTML内容
  String _generateHtmlContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? '#1e1e1e' : '#ffffff';
    final textColor = isDark ? '#ffffff' : '#000000';
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mermaid Chart</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
    <style>
        body {
            margin: 0;
            padding: 16px;
            background-color: $backgroundColor;
            color: $textColor;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            overflow: hidden;
        }
        
        .mermaid-container {
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            width: 100%;
        }
        
        .mermaid {
            max-width: 100%;
            height: auto;
        }
        
        .error-container {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 200px;
            padding: 20px;
            background-color: #fee;
            border: 2px dashed #f88;
            border-radius: 8px;
            color: #c33;
        }
        
        .loading-container {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 200px;
            color: #666;
        }
        
        .spinner {
            width: 40px;
            height: 40px;
            border: 4px solid #f3f3f3;
            border-top: 4px solid #3498db;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-bottom: 16px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div id="loading" class="loading-container">
        <div class="spinner"></div>
        <div>正在渲染图表...</div>
    </div>
    
    <div id="error" class="error-container" style="display: none;">
        <div style="font-size: 18px; margin-bottom: 8px;">⚠️ 渲染错误</div>
        <div id="error-message"></div>
    </div>
    
    <div id="mermaid-container" class="mermaid-container" style="display: none;">
        <div class="mermaid" id="mermaid-chart"></div>
    </div>

    <script>
        // 配置Mermaid
        mermaid.initialize({
            startOnLoad: false,
            theme: '${isDark ? 'dark' : widget.theme}',
            securityLevel: 'loose',
            fontFamily: 'monospace',
            flowchart: {
                useMaxWidth: true,
                htmlLabels: true,
                curve: 'basis'
            },
            sequence: {
                diagramMarginX: 50,
                diagramMarginY: 10,
                actorMargin: 50,
                width: 150,
                height: 65,
                boxMargin: 10,
                boxTextMargin: 5,
                noteMargin: 10,
                messageMargin: 35,
                messageAlign: 'center',
                mirrorActors: true,
                bottomMarginAdj: 1,
                useMaxWidth: true,
                rightAngles: false,
                showSequenceNumbers: false
            },
            gantt: {
                titleTopMargin: 25,
                barHeight: 20,
                fontSizeName: 12,
                fontSizeTitle: 16,
                fontSizeSection: 12,
                bottomPadding: 4,
                leftPadding: 75,
                gridLineStartPadding: 35,
                fontSize: 11,
                fontFamily: '"Open Sans", sans-serif',
                numberSectionStyles: 4,
                axisFormat: '%Y-%m-%d',
                topAxis: false
            }
        });

        // 渲染Mermaid图表的函数
        function renderMermaid() {
            const chartContent = `${widget.chart.content}`;
            const container = document.getElementById('mermaid-container');
            const chart = document.getElementById('mermaid-chart');
            const loading = document.getElementById('loading');
            const error = document.getElementById('error');
            
            try {
                // 验证Mermaid语法
                mermaid.parse(chartContent);
                
                // 渲染图表
                chart.textContent = chartContent;
                
                mermaid.run({
                    nodes: [chart]
                }).then(() => {
                    loading.style.display = 'none';
                    error.style.display = 'none';
                    container.style.display = 'flex';
                    
                    // 通知Flutter渲染完成
                    if (window.flutter_inappwebview) {
                        window.flutter_inappwebview.callHandler('onRenderComplete');
                    }
                }).catch((err) => {
                    showError('渲染失败: ' + err.message);
                });
                
            } catch (err) {
                showError('语法错误: ' + err.message);
            }
        }
        
        function showError(message) {
            const loading = document.getElementById('loading');
            const error = document.getElementById('error');
            const errorMessage = document.getElementById('error-message');
            
            loading.style.display = 'none';
            errorMessage.textContent = message;
            error.style.display = 'flex';
            
            // 通知Flutter渲染错误
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('onRenderError', message);
            }
        }
        
        // 页面加载完成后渲染图表
        document.addEventListener('DOMContentLoaded', function() {
            setTimeout(renderMermaid, 100);
        });
    </script>
</body>
</html>
''';
  }

  /// 渲染Mermaid图表
  void _renderMermaid() {
    _controller.runJavaScript('renderMermaid()');
  }

  @override
  void didUpdateWidget(MermaidRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chart.content != widget.chart.content ||
        oldWidget.theme != widget.theme) {
      _controller.loadHtmlString(_generateHtmlContent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            
            // 加载指示器
            if (_isLoading)
              Container(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在渲染图表...'),
                    ],
                  ),
                ),
              ),
            
            // 错误提示
            if (_hasError)
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '图表渲染失败',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isLoading = true;
                          });
                          _controller.loadHtmlString(_generateHtmlContent());
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
        height: height ?? 400,
        theme: theme,
      ),
    );
  }
} 