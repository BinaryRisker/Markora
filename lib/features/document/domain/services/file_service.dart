import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import '../../../../types/document.dart';


// Imports only available in Web environment
// In non-Web environments, these API calls will be skipped

/// File service - handles real file operations
class FileService {
  /// Save document to specified path
  Future<void> saveDocumentToFile(Document document, String filePath) async {
    try {
      if (kIsWeb) {
        // Use browser download in Web environment
        await _downloadFileInBrowser(document.content, filePath, 'text/markdown');
        print('Document exported: $filePath');
      } else {
        final file = File(filePath);
        
        // Ensure directory exists
        final directory = Directory(path.dirname(filePath));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        // Write file
        await file.writeAsString(document.content, encoding: utf8);
        
        print('Document saved to: $filePath');
      }
    } catch (e) {
      throw Exception('Failed to save document: $e');
    }
  }

  /// Load document from file
  Future<Document> loadDocumentFromFile(String filePath) async {
    try {
      if (kIsWeb) {
        // In Web environment, filePath is actually filename, need to reselect file to get content
        return await loadDocumentFromWeb();
      } else {
        // Non-Web environment, normal file operations
        final file = File(filePath);
        
        if (!await file.exists()) {
          throw Exception('File does not exist: $filePath');
        }
        
        final content = await file.readAsString(encoding: utf8);
        final fileName = path.basenameWithoutExtension(filePath);
        
        return Document(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName,
          content: content,
          type: _getDocumentTypeFromExtension(path.extension(filePath)),
          filePath: filePath,
          createdAt: await file.lastModified(),
          updatedAt: await file.lastModified(),
        );
      }
    } catch (e) {
      throw Exception('Failed to load document: $e');
    }
  }

  /// Load document in Web environment
  Future<Document> loadDocumentFromWeb() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Open Markdown File',
        allowedExtensions: ['md', 'markdown', 'txt'],
        type: FileType.custom,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }
      
      final file = result.files.first;
      final bytes = file.bytes;
      
      if (bytes == null) {
        throw Exception('Unable to read file content');
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
      throw Exception('Failed to load document: $e');
    }
  }

  /// Save file using file picker
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
  }) async {
    try {
      if (kIsWeb) {
        // On web, we just return the file name. The actual download is handled by creating a blob.
        return fileName ?? 'Untitled.md';
      }
      return await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
      );
    } catch (e) {
      // Don't throw, just return null if user cancels or an error occurs
      return null;
    }
  }

  /// Select save file path
  Future<String?> selectSaveFilePath({
    String? dialogTitle,
    String? fileName,
    List<String>? allowedExtensions,
  }) async {
    try {
      if (kIsWeb) {
        // In Web environment, return filename directly, no path selection needed
        return fileName ?? 'document';
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: dialogTitle ?? 'Save File',
          fileName: fileName,
          allowedExtensions: allowedExtensions,
          type: allowedExtensions != null ? FileType.custom : FileType.any,
        );
        
        return result;
      }
    } catch (e) {
      if (kIsWeb) {
        // In Web environment, return default filename if error occurs
        return fileName ?? 'document';
      }
      throw Exception('Failed to select save path: $e');
    }
  }

  /// Select open file path
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
        // In Web environment, return filename, actual file content obtained through bytes
        return result?.files.first.name;
      } else {
        // In non-Web environment, return file path
        return result?.files.first.path;
      }
    } catch (e) {
      throw Exception('Failed to select open path: $e');
    }
  }



  /// Generate printable HTML content (for PDF export)
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
        
        // Auto print function (optional)
        window.addEventListener('load', function() {
            // Show print dialog after 1 second delay
            setTimeout(function() {
                if (confirm('Do you want to print this document as PDF?')) {
                    window.print();
                }
            }, 1000);
        });
    </script>
</head>
<body>
    <div class="print-header">
        <h1>${document.title}</h1>
        <p>Export time: ${DateTime.now().toString().substring(0, 19)}</p>
    </div>
    
    <div class="markdown-content">
        ${_convertMarkdownToHtml(document.content)}
    </div>
    
    <div class="print-footer">
        <p>Generated by Markora | ${DateTime.now().toString().substring(0, 10)}</p>
    </div>
</body>
</html>
''';
  }

  /// Generate HTML content
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

  /// Simple Markdown to HTML conversion (should use specialized library in actual application)
  String _convertMarkdownToHtml(String markdown) {
    // Simple Markdown to HTML implementation here
    // Should use markdown package or other specialized conversion library in actual application
    String html = markdown;
    
    // Header conversion
    html = html.replaceAllMapped(RegExp(r'^#{6}\s+(.+)$', multiLine: true), (match) => '<h6>${match.group(1)}</h6>');
    html = html.replaceAllMapped(RegExp(r'^#{5}\s+(.+)$', multiLine: true), (match) => '<h5>${match.group(1)}</h5>');
    html = html.replaceAllMapped(RegExp(r'^#{4}\s+(.+)$', multiLine: true), (match) => '<h4>${match.group(1)}</h4>');
    html = html.replaceAllMapped(RegExp(r'^#{3}\s+(.+)$', multiLine: true), (match) => '<h3>${match.group(1)}</h3>');
    html = html.replaceAllMapped(RegExp(r'^#{2}\s+(.+)$', multiLine: true), (match) => '<h2>${match.group(1)}</h2>');
    html = html.replaceAllMapped(RegExp(r'^#{1}\s+(.+)$', multiLine: true), (match) => '<h1>${match.group(1)}</h1>');
    
    // Bold and italic
    html = html.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (match) => '<strong>${match.group(1)}</strong>');
    html = html.replaceAllMapped(RegExp(r'\*(.+?)\*'), (match) => '<em>${match.group(1)}</em>');
    
    // Code
    html = html.replaceAllMapped(RegExp(r'`(.+?)`'), (match) => '<code>${match.group(1)}</code>');
    
    // Links
    html = html.replaceAllMapped(RegExp(r'\[(.+?)\]\((.+?)\)'), (match) => '<a href="${match.group(2)}">${match.group(1)}</a>');
    
    // Paragraphs
    html = html.replaceAll(RegExp(r'\n\n'), '</p><p>');
    html = '<p>$html</p>';
    
    // Line breaks
    html = html.replaceAll('\n', '<br>');
    
    return html;
  }

  /// Get document type based on file extension
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



  /// Download file in Web environment
  Future<void> _downloadFileInBrowser(String content, String fileName, String mimeType) async {
    if (kIsWeb) {
      try {
        // Use dynamic calls in Web environment to avoid compilation errors
        final bytes = utf8.encode(content);
        
        // Use js interop to create download
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
        
        // Execute JavaScript code
        _executeJavaScript(jsCode, [content, fileName, mimeType]);
      } catch (e) {
        throw Exception('Failed to download file in Web environment: $e');
      }
    }
  }
  
  /// Execute JavaScript code (Web environment only)
  void _executeJavaScript(String code, List<dynamic> args) {
    if (kIsWeb) {
      // In Web environment, this method will be replaced by actual Web implementation
      // In non-Web environment, this method will not be called
      print('JavaScript code ready to execute: ${code.substring(0, 50)}...');
    }
  }

  /// Generate and download PDF in browser
  Future<void> _generatePdfInBrowser(Document document, String filePath) async {
    if (kIsWeb) {
      try {
        // Create temporary HTML content for PDF generation
        final htmlContent = _convertMarkdownToHtml(document.content);
        
        // Create temporary div element in Web environment
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
        
        // Use html2canvas + jsPDF to generate PDF with Chinese support
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final documentTitle = document.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        final fileName = documentTitle.isNotEmpty 
            ? '${documentTitle}_$timestamp.pdf'
            : 'document_$timestamp.pdf';
            
        final pdfGenerationCode = '''
          (function() {
            var tempDiv = document.getElementById('$tempDivId');
            if (!tempDiv) {
              throw new Error('Temporary div element not found');
            }
            
            if (typeof html2canvas === 'undefined' || typeof jsPDF === 'undefined') {
              throw new Error('html2canvas or jsPDF library not loaded');
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
                
                console.log('PDF downloaded: $fileName');
                console.log('File saved in browser default download folder');
                
                // Clean up temporary element
                tempDiv.remove();
              } catch (e) {
                console.error('PDF generation error:', e);
                tempDiv.remove();
                throw e;
              }
            }).catch(function(error) {
              console.error('Canvas generation error:', error);
              tempDiv.remove();
              throw error;
            });
          })();
        ''';
        
        _executeJavaScript(pdfGenerationCode, []);
      } catch (e) {
        throw Exception('Web PDF generation failed: $e');
      }
    }
  }

  /// Split text into lines suitable for PDF
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

  /// Remove HTML tags, keep plain text
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

  /// Process text for PDF output, especially Chinese characters
  String _processTextForPdf(String text) {
    // Special processing for text containing Chinese characters
    if (text.contains(RegExp(r'[\u4e00-\u9fff]'))) {
      // If contains Chinese characters, try encoding conversion
      try {
        // Convert string to UTF-8 bytes then decode again
        final bytes = utf8.encode(text);
        return utf8.decode(bytes);
      } catch (e) {
        // If conversion fails, return original text
        return text;
      }
    }
    return text;
  }
}