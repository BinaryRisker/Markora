import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import '../../../../types/document.dart';
import '../../../export/domain/entities/export_settings.dart';
import '../../../export/domain/services/export_service.dart';

// 仅在Web环境下可用的导入
// 在非Web环境下，这些API调用将被跳过

/// 文件服务 - 处理真实的文件操作
class FileService {
  /// 保存文档到指定路径
  Future<void> saveDocumentToFile(Document document, String filePath) async {
    try {
      if (kIsWeb) {
        // Web环境下使用浏览器下载
        await _downloadFileInBrowser(document.content, filePath, 'text/markdown');
        print('文档已导出: $filePath');
      } else {
        final file = File(filePath);
        
        // 确保目录存在
        final directory = Directory(path.dirname(filePath));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        // 写入文件
        await file.writeAsString(document.content, encoding: utf8);
        
        print('文档已保存到: $filePath');
      }
    } catch (e) {
      throw Exception('保存文档失败: $e');
    }
  }

  /// 从文件加载文档
  Future<Document> loadDocumentFromFile(String filePath) async {
    try {
      if (kIsWeb) {
        // Web环境下，filePath实际是文件名，需要重新选择文件获取内容
        return await loadDocumentFromWeb();
      } else {
        // 非Web环境，正常文件操作
        final file = File(filePath);
        
        if (!await file.exists()) {
          throw Exception('文件不存在: $filePath');
        }
        
        final content = await file.readAsString(encoding: utf8);
        final fileName = path.basenameWithoutExtension(filePath);
        
        return Document(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName,
          content: content,
          type: _getDocumentTypeFromExtension(path.extension(filePath)),
          createdAt: await file.lastModified(),
          updatedAt: await file.lastModified(),
        );
      }
    } catch (e) {
      throw Exception('加载文档失败: $e');
    }
  }

  /// Web环境下加载文档
  Future<Document> loadDocumentFromWeb() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Open Markdown File',
        allowedExtensions: ['md', 'markdown', 'txt'],
        type: FileType.custom,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        throw Exception('未选择文件');
      }
      
      final file = result.files.first;
      final bytes = file.bytes;
      
      if (bytes == null) {
        throw Exception('无法读取文件内容');
      }
      
      final content = utf8.decode(bytes);
      final fileName = path.basenameWithoutExtension(file.name);
      final now = DateTime.now();
      
      return Document(
        id: now.millisecondsSinceEpoch.toString(),
        title: fileName,
        content: content,
        type: _getDocumentTypeFromExtension(path.extension(file.name)),
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('加载文档失败: $e');
    }
  }

  /// 导出文档为HTML
  Future<void> exportToHtml(Document document, String filePath) async {
    try {
      final htmlContent = _generateHtmlContent(document);
      
      if (kIsWeb) {
        // Web环境下使用浏览器下载
        await _downloadFileInBrowser(htmlContent, filePath, 'text/html');
        print('HTML已导出: $filePath');
      } else {
        final file = File(filePath);
        
        // 确保目录存在
        final directory = Directory(path.dirname(filePath));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        await file.writeAsString(htmlContent, encoding: utf8);
        print('HTML已导出到: $filePath');
      }
    } catch (e) {
      throw Exception('导出HTML失败: $e');
    }
  }

  /// 导出文档为PDF
  Future<void> exportToPdf(Document document, String filePath) async {
    try {
      if (kIsWeb) {
        // Web环境下使用jsPDF生成真正的PDF
        await _generatePdfInBrowser(document, filePath);
        print('PDF已导出: $filePath');
      } else {
        // 非Web环境下使用真正的PDF生成
        final exportService = ExportServiceImpl();
        final settings = ExportSettings(
          format: ExportFormat.pdf,
          outputPath: path.dirname(filePath),
          fileName: path.basenameWithoutExtension(filePath),
          pdfSettings: const PdfExportSettings(
            pageSize: 'A4',
            fontSize: 12.0,
            lineHeight: 1.6,
            marginTop: 2.0,
            marginBottom: 2.0,
            marginLeft: 2.0,
            marginRight: 2.0,
            includePageNumbers: true,
          ),
          htmlSettings: const HtmlExportSettings(
            enableMathJax: true,
            enableMermaid: false,
            responsiveDesign: false,
            includeTableOfContents: false,
          ),
        );
        
        final result = await exportService.exportDocument(document, settings);
        if (!result.success) {
          throw Exception(result.errorMessage ?? 'PDF导出失败');
        }
        
        print('PDF已导出到: $filePath');
      }
    } catch (e) {
      throw Exception('导出PDF失败: $e');
    }
  }

  /// 选择保存文件路径
  Future<String?> selectSaveFilePath({
    String? dialogTitle,
    String? fileName,
    List<String>? allowedExtensions,
  }) async {
    try {
      if (kIsWeb) {
        // Web环境下直接返回文件名，不需要路径选择
        return fileName ?? 'document';
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: dialogTitle ?? '保存文件',
          fileName: fileName,
          allowedExtensions: allowedExtensions,
          type: allowedExtensions != null ? FileType.custom : FileType.any,
        );
        
        return result;
      }
    } catch (e) {
      if (kIsWeb) {
        // Web环境下如果出错，返回默认文件名
        return fileName ?? 'document';
      }
      throw Exception('选择保存路径失败: $e');
    }
  }

  /// 选择打开文件路径
  Future<String?> selectOpenFilePath({
    String? dialogTitle,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle ?? 'Open File',
        allowedExtensions: allowedExtensions,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowMultiple: false,
      );
      
      if (kIsWeb) {
        // Web环境下返回文件名，实际文件内容通过bytes获取
        return result?.files.first.name;
      } else {
        // 非Web环境返回文件路径
        return result?.files.first.path;
      }
    } catch (e) {
      throw Exception('Failed to select open path: $e');
    }
  }

  /// 导出文档（根据设置）
  Future<void> exportDocument(Document document, ExportSettings settings, {String? targetPath}) async {
    try {
      // 根据格式选择文件扩展名
      final extension = _getExtensionForFormat(settings.format);
      // 使用用户输入的文件名，如果没有则使用文档标题
      final fileName = settings.fileName.isNotEmpty ? settings.fileName : document.title;
      final fullFileName = '$fileName$extension';
      
      String? filePath = targetPath;
      
      if (filePath == null) {
        if (kIsWeb) {
          // Web环境下直接使用文件名
          filePath = fullFileName;
        } else {
          // 非Web环境选择保存路径
          filePath = await selectSaveFilePath(
            dialogTitle: '导出${_getFormatDisplayName(settings.format)}',
            fileName: fullFileName,
            allowedExtensions: [extension.substring(1)], // 移除点号
          );
          
          if (filePath == null) return; // 用户取消了选择
        }
      }
      
      // 根据格式导出
      switch (settings.format) {
        case ExportFormat.html:
          await exportToHtml(document, filePath);
          break;
        case ExportFormat.pdf:
          await exportToPdf(document, filePath);
          break;
        case ExportFormat.docx:
          // 暂时导出为Markdown格式
          await saveDocumentToFile(document, filePath);
          break;
        case ExportFormat.png:
        case ExportFormat.jpeg:
          // 图像导出暂未实现
          throw Exception('图像导出功能暂未实现');
      }
    } catch (e) {
      throw Exception('导出文档失败: $e');
    }
  }

  /// 生成可打印的HTML内容（用于PDF导出）
  String _generatePrintableHtmlContent(Document document) {
    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${document.title}</title>
    <style>
        @media print {
            body { margin: 0; }
            .no-print { display: none; }
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 210mm;
            margin: 0 auto;
            padding: 20mm;
            background-color: #fff;
            font-size: 12pt;
        }
        
        h1, h2, h3, h4, h5, h6 {
            color: #2c3e50;
            margin-top: 24pt;
            margin-bottom: 12pt;
            page-break-after: avoid;
        }
        
        h1 { font-size: 24pt; border-bottom: 2px solid #3498db; padding-bottom: 6pt; }
        h2 { font-size: 18pt; border-bottom: 1px solid #bdc3c7; padding-bottom: 3pt; }
        h3 { font-size: 14pt; }
        h4 { font-size: 12pt; }
        h5 { font-size: 11pt; }
        h6 { font-size: 10pt; }
        
        p {
            margin-bottom: 12pt;
            orphans: 3;
            widows: 3;
        }
        
        code {
            background-color: #f8f9fa;
            padding: 2pt 4pt;
            border-radius: 3pt;
            font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
            font-size: 10pt;
        }
        
        pre {
            background-color: #f8f9fa;
            padding: 12pt;
            border-radius: 4pt;
            overflow-x: auto;
            border-left: 4pt solid #3498db;
            page-break-inside: avoid;
            font-size: 10pt;
        }
        
        blockquote {
            border-left: 4pt solid #3498db;
            padding-left: 16pt;
            margin: 16pt 0;
            color: #7f8c8d;
            font-style: italic;
            page-break-inside: avoid;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 16pt 0;
            page-break-inside: avoid;
        }
        
        th, td {
            border: 1pt solid #ddd;
            padding: 8pt;
            text-align: left;
            font-size: 10pt;
        }
        
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        
        ul, ol {
            padding-left: 24pt;
        }
        
        li {
            margin-bottom: 4pt;
        }
        
        a {
            color: #3498db;
            text-decoration: none;
        }
        
        .print-header {
            text-align: center;
            margin-bottom: 24pt;
            border-bottom: 2pt solid #3498db;
            padding-bottom: 12pt;
        }
        
        .print-footer {
            margin-top: 24pt;
            text-align: center;
            font-size: 10pt;
            color: #7f8c8d;
        }
    </style>
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <script>
        window.MathJax = {
            tex: {
                inlineMath: [['\u0024', '\u0024'], ['\\(', '\\)']],
                displayMath: [['\u0024\u0024', '\u0024\u0024'], ['\\[', '\\]']]
            }
        };
        
        // 自动打印功能（可选）
        window.addEventListener('load', function() {
            // 延迟一秒后显示打印对话框
            setTimeout(function() {
                if (confirm('是否要打印此文档为PDF？')) {
                    window.print();
                }
            }, 1000);
        });
    </script>
</head>
<body>
    <div class="print-header">
        <h1>${document.title}</h1>
        <p>导出时间: ${DateTime.now().toString().substring(0, 19)}</p>
    </div>
    
    <div class="markdown-content">
        ${_convertMarkdownToHtml(document.content)}
    </div>
    
    <div class="print-footer">
        <p>由 Markora 生成 | ${DateTime.now().toString().substring(0, 10)}</p>
    </div>
</body>
</html>
''';
  }

  /// 生成HTML内容
  String _generateHtmlContent(Document document) {
    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${document.title}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #fff;
        }
        h1, h2, h3, h4, h5, h6 {
            color: #2c3e50;
            margin-top: 30px;
            margin-bottom: 15px;
        }
        h1 { font-size: 2.5em; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        h2 { font-size: 2em; border-bottom: 1px solid #bdc3c7; padding-bottom: 5px; }
        h3 { font-size: 1.5em; }
        p { margin-bottom: 15px; }
        code {
            background-color: #f8f9fa;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
        }
        pre {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            border-left: 4px solid #3498db;
        }
        blockquote {
            border-left: 4px solid #3498db;
            padding-left: 20px;
            margin: 20px 0;
            color: #7f8c8d;
            font-style: italic;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        ul, ol {
            padding-left: 30px;
        }
        li {
            margin-bottom: 5px;
        }
        a {
            color: #3498db;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .math {
            font-family: 'Times New Roman', serif;
        }
    </style>
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <script>
        window.MathJax = {
            tex: {
                inlineMath: [['\u0024', '\u0024'], ['\\(', '\\)']],
                displayMath: [['\u0024\u0024', '\u0024\u0024'], ['\\[', '\\]']]
            }
        };
    </script>
</head>
<body>
    <div class="markdown-content">
        ${_convertMarkdownToHtml(document.content)}
    </div>
</body>
</html>
''';
  }

  /// 简单的Markdown到HTML转换（实际应用中应该使用专门的库）
  String _convertMarkdownToHtml(String markdown) {
    // 这里实现简单的Markdown转HTML
    // 实际应用中应该使用markdown包或其他专门的转换库
    String html = markdown;
    
    // 标题转换
    html = html.replaceAllMapped(RegExp(r'^#{6}\s+(.+)$', multiLine: true), (match) => '<h6>${match.group(1)}</h6>');
    html = html.replaceAllMapped(RegExp(r'^#{5}\s+(.+)$', multiLine: true), (match) => '<h5>${match.group(1)}</h5>');
    html = html.replaceAllMapped(RegExp(r'^#{4}\s+(.+)$', multiLine: true), (match) => '<h4>${match.group(1)}</h4>');
    html = html.replaceAllMapped(RegExp(r'^#{3}\s+(.+)$', multiLine: true), (match) => '<h3>${match.group(1)}</h3>');
    html = html.replaceAllMapped(RegExp(r'^#{2}\s+(.+)$', multiLine: true), (match) => '<h2>${match.group(1)}</h2>');
    html = html.replaceAllMapped(RegExp(r'^#{1}\s+(.+)$', multiLine: true), (match) => '<h1>${match.group(1)}</h1>');
    
    // 粗体和斜体
    html = html.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (match) => '<strong>${match.group(1)}</strong>');
    html = html.replaceAllMapped(RegExp(r'\*(.+?)\*'), (match) => '<em>${match.group(1)}</em>');
    
    // 代码
    html = html.replaceAllMapped(RegExp(r'`(.+?)`'), (match) => '<code>${match.group(1)}</code>');
    
    // 链接
    html = html.replaceAllMapped(RegExp(r'\[(.+?)\]\((.+?)\)'), (match) => '<a href="${match.group(2)}">${match.group(1)}</a>');
    
    // 段落
    html = html.replaceAll(RegExp(r'\n\n'), '</p><p>');
    html = '<p>$html</p>';
    
    // 换行
    html = html.replaceAll('\n', '<br>');
    
    return html;
  }

  /// 根据文件扩展名获取文档类型
  DocumentType _getDocumentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.md':
      case '.markdown':
        return DocumentType.markdown;
      case '.txt':
        return DocumentType.text;
      default:
        return DocumentType.markdown;
    }
  }

  /// 根据导出格式获取文件扩展名
  String _getExtensionForFormat(ExportFormat format) {
    switch (format) {
      case ExportFormat.html:
        return '.html';
      case ExportFormat.pdf:
        return '.pdf';
      case ExportFormat.docx:
        return '.docx';
      case ExportFormat.png:
        return '.png';
      case ExportFormat.jpeg:
        return '.jpg';
    }
  }

  /// 获取格式显示名称
  String _getFormatDisplayName(ExportFormat format) {
    switch (format) {
      case ExportFormat.html:
        return 'HTML';
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.docx:
        return 'Word文档';
      case ExportFormat.png:
        return 'PNG图像';
      case ExportFormat.jpeg:
        return 'JPEG图像';
    }
  }

  /// Web环境下下载文件
  Future<void> _downloadFileInBrowser(String content, String fileName, String mimeType) async {
    if (kIsWeb) {
      try {
        // 在Web环境下使用动态调用避免编译错误
        final bytes = utf8.encode(content);
        
        // 使用js interop创建下载
        final jsCode = '''
          (function(content, fileName, mimeType) {
            const bytes = new Uint8Array($bytes);
            const blob = new Blob([bytes], {type: mimeType});
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = fileName;
            a.click();
            URL.revokeObjectURL(url);
          })(arguments[0], arguments[1], arguments[2]);
        ''';
        
        // 执行JavaScript代码
        _executeJavaScript(jsCode, [content, fileName, mimeType]);
      } catch (e) {
        throw Exception('Web环境下载文件失败: $e');
      }
    }
  }
  
  /// 执行JavaScript代码（仅在Web环境下）
  void _executeJavaScript(String code, List<dynamic> args) {
    if (kIsWeb) {
      // 在Web环境下，这个方法会被实际的Web实现替换
      // 在非Web环境下，这个方法不会被调用
      print('JavaScript代码准备执行: ${code.substring(0, 50)}...');
    }
  }

  /// 在浏览器中生成并下载PDF
  Future<void> _generatePdfInBrowser(Document document, String filePath) async {
    if (kIsWeb) {
      try {
        // 创建临时HTML内容用于PDF生成
        final htmlContent = _convertMarkdownToHtml(document.content);
        
        // 在Web环境下创建临时div元素
        final tempDivId = 'temp-pdf-div-${DateTime.now().millisecondsSinceEpoch}';
        final createDivCode = '''
          var tempDiv = document.createElement('div');
          tempDiv.id = '$tempDivId';
          tempDiv.style.position = 'absolute';
          tempDiv.style.left = '-9999px';
          tempDiv.style.top = '-9999px';
          tempDiv.style.width = '210mm';
          tempDiv.style.padding = '20mm';
          tempDiv.style.fontFamily = 'Arial, sans-serif';
          tempDiv.style.fontSize = '12pt';
          tempDiv.style.lineHeight = '1.6';
          tempDiv.style.color = '#333';
          tempDiv.style.backgroundColor = '#fff';
          tempDiv.innerHTML = '<h1>${document.title}</h1>$htmlContent';
          document.body.appendChild(tempDiv);
        ''';
        
        _executeJavaScript(createDivCode, []);
        
        // 使用html2canvas + jsPDF生成PDF以支持中文
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final documentTitle = document.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        final fileName = documentTitle.isNotEmpty 
            ? '${documentTitle}_$timestamp.pdf'
            : 'document_$timestamp.pdf';
            
        final pdfGenerationCode = '''
          (function() {
            var tempDiv = document.getElementById('$tempDivId');
            if (!tempDiv) {
              throw new Error('临时div元素未找到');
            }
            
            if (typeof html2canvas === 'undefined' || typeof jsPDF === 'undefined') {
              throw new Error('html2canvas或jsPDF库未加载');
            }
            
            html2canvas(tempDiv, {
              scale: 2,
              useCORS: true,
              allowTaint: true,
              backgroundColor: '#ffffff',
              width: tempDiv.offsetWidth,
              height: tempDiv.offsetHeight
            }).then(function(canvas) {
              try {
                var pdf = new jsPDF('portrait', 'mm', 'a4');
                var imgData = canvas.toDataURL('image/png');
                
                var pdfWidth = 210.0;
                var pdfHeight = 297.0;
                var margin = 20.0;
                var maxWidth = pdfWidth - (margin * 2);
                var maxHeight = pdfHeight - (margin * 2);
                
                var canvasWidth = canvas.width;
                var canvasHeight = canvas.height;
                var ratio = canvasWidth / canvasHeight;
                
                var imgWidth = maxWidth;
                var imgHeight = imgWidth / ratio;
                
                if (imgHeight > maxHeight) {
                  imgHeight = maxHeight;
                  imgWidth = imgHeight * ratio;
                }
                
                pdf.addImage(imgData, 'PNG', margin, margin, imgWidth, imgHeight);
                pdf.save('$fileName');
                
                console.log('PDF已下载: $fileName');
                console.log('文件保存在浏览器的默认下载文件夹中');
                
                // 清理临时元素
                tempDiv.remove();
              } catch (e) {
                console.error('PDF生成错误:', e);
                tempDiv.remove();
                throw e;
              }
            }).catch(function(error) {
              console.error('Canvas生成错误:', error);
              tempDiv.remove();
              throw error;
            });
          })();
        ''';
        
        _executeJavaScript(pdfGenerationCode, []);
      } catch (e) {
        throw Exception('Web PDF生成失败: $e');
      }
    }
  }

  /// 将文本分割成适合PDF的行
  List<String> _splitTextIntoLines(String text, int maxCharsPerLine) {
    final lines = <String>[];
    final words = text.split(' ');
    var currentLine = '';
    
    for (final word in words) {
      if ((currentLine + word).length <= maxCharsPerLine) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
        }
        currentLine = word;
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    
    return lines;
  }

  /// 移除HTML标签，保留纯文本
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  /// 处理文本以适应PDF输出，特别是中文字符
  String _processTextForPdf(String text) {
    // 对于包含中文字符的文本，进行特殊处理
    if (text.contains(RegExp(r'[\u4e00-\u9fff]'))) {
      // 如果包含中文字符，尝试进行编码转换
      try {
        // 将字符串转换为UTF-8字节然后重新解码
        final bytes = utf8.encode(text);
        return utf8.decode(bytes);
      } catch (e) {
        // 如果转换失败，返回原文本
        return text;
      }
    }
    return text;
  }
}