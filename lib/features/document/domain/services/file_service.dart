import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import '../../../../types/document.dart';
import '../../../export/domain/entities/export_settings.dart';

/// 文件服务 - 处理真实的文件操作
class FileService {
  /// 保存文档到指定路径
  Future<void> saveDocumentToFile(Document document, String filePath) async {
    try {
      final file = File(filePath);
      
      // 确保目录存在
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 写入文件
      await file.writeAsString(document.content, encoding: utf8);
      
      print('文档已保存到: $filePath');
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
        dialogTitle: '打开Markdown文件',
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
      final file = File(filePath);
      
      // 确保目录存在
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      await file.writeAsString(htmlContent, encoding: utf8);
      print('HTML已导出到: $filePath');
    } catch (e) {
      throw Exception('导出HTML失败: $e');
    }
  }

  /// 导出文档为PDF（简化版本，实际应用中需要更复杂的PDF生成）
  Future<void> exportToPdf(Document document, String filePath) async {
    try {
      // 这里暂时导出为HTML，实际应用中需要使用PDF生成库
      final htmlContent = _generateHtmlContent(document);
      final pdfFile = File(filePath);
      
      // 确保目录存在
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 暂时保存为HTML格式（实际应用中应该转换为PDF）
      await pdfFile.writeAsString(htmlContent, encoding: utf8);
      print('PDF已导出到: $filePath (当前为HTML格式)');
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
      final result = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? '保存文件',
        fileName: fileName,
        allowedExtensions: allowedExtensions,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
      );
      
      return result;
    } catch (e) {
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
        dialogTitle: dialogTitle ?? '打开文件',
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
      throw Exception('选择打开路径失败: $e');
    }
  }

  /// 导出文档（根据设置）
  Future<void> exportDocument(Document document, ExportSettings settings, {String? targetPath}) async {
    try {
      String? filePath = targetPath;
      
      if (filePath == null) {
        // 根据格式选择文件扩展名
        final extension = _getExtensionForFormat(settings.format);
        final defaultFileName = '${document.title}$extension';
        
        // 选择保存路径
        filePath = await selectSaveFilePath(
          dialogTitle: '导出${_getFormatDisplayName(settings.format)}',
          fileName: defaultFileName,
          allowedExtensions: [extension.substring(1)], // 移除点号
        );
        
        if (filePath == null) return; // 用户取消了选择
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
                inlineMath: [['\\\$', '\\\$'], ['\\\\(', '\\\\)']],
                displayMath: [['\\\$\\\$', '\\\$\\\$'], ['\\\\[', '\\\\]']]
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
}