import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../types/document.dart';
import '../entities/export_settings.dart';

/// Export service interface
abstract class ExportService {
  /// Export document
  Future<ExportResult> exportDocument(
    Document document,
    ExportSettings settings, {
    Function(ExportProgress)? onProgress,
  });

  /// Check if format is supported
  bool isFormatSupported(ExportFormat format);

  /// Get suggested filename
  String getSuggestedFileName(Document document, ExportFormat format);
}

/// Export service implementation
class ExportServiceImpl implements ExportService {
  @override
  Future<ExportResult> exportDocument(
    Document document,
    ExportSettings settings, {
    Function(ExportProgress)? onProgress,
  }) async {
    try {
      // Initialize progress
      onProgress?.call(const ExportProgress(
        progress: 0.0,
        status: 'Starting export...',
      ));

      switch (settings.format) {
        case ExportFormat.html:
          return await _exportToHtml(document, settings, onProgress);
        case ExportFormat.pdf:
          return await _exportToPdf(document, settings, onProgress);
        case ExportFormat.png:
        case ExportFormat.jpeg:
          return await _exportToImage(document, settings, onProgress);
        case ExportFormat.docx:
          return await _exportToDocx(document, settings, onProgress);
      }
    } catch (e) {
      return ExportResult.failure('Export failed: $e');
    }
  }

  @override
  bool isFormatSupported(ExportFormat format) {
    switch (format) {
      case ExportFormat.html:
        return true;
      case ExportFormat.pdf:
        return true; // PDF export implemented
      case ExportFormat.png:
      case ExportFormat.jpeg:
        return false; // Need to add image export support
      case ExportFormat.docx:
        return false; // Need to add docx package support
    }
  }

  @override
  String getSuggestedFileName(Document document, ExportFormat format) {
    final baseName = document.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$baseName.${format.extension}';
  }

  /// Export as HTML
  Future<ExportResult> _exportToHtml(
    Document document,
    ExportSettings settings,
    Function(ExportProgress)? onProgress,
  ) async {
    try {
      onProgress?.call(const ExportProgress(
        progress: 0.2,
        status: 'Generating HTML...',
        currentStep: 'Parsing Markdown content',
      ));

      // Generate HTML content
      final htmlContent = _generateHtmlContent(document, settings.htmlSettings);

      onProgress?.call(const ExportProgress(
        progress: 0.8,
        status: 'Saving file...',
        currentStep: 'Writing HTML file',
      ));

      // Simulate file saving (actual implementation will differ in web environment)
      await _saveHtmlFile(htmlContent, settings.fullPath);

      onProgress?.call(const ExportProgress(
        progress: 1.0,
        status: 'Export completed',
        isCompleted: true,
      ));

      return ExportResult.success(
        settings.fullPath,
        fileSizeBytes: htmlContent.codeUnits.length,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      return ExportResult.failure('HTML export failed: $e');
    }
  }

  /// Export as PDF
  Future<ExportResult> _exportToPdf(
    Document document,
    ExportSettings settings,
    Function(ExportProgress)? onProgress,
  ) async {
    try {
      onProgress?.call(const ExportProgress(
        progress: 0.2,
        status: 'Generating PDF...',
        currentStep: 'Parsing document structure',
      ));

      // First generate HTML, then convert to PDF
      final htmlContent = _generateHtmlContent(document, settings.htmlSettings);

      onProgress?.call(const ExportProgress(
        progress: 0.5,
        status: 'Rendering pages...',
        currentStep: 'Applying PDF styles',
      ));

      // Generate PDF
      final pdfBytes = await _generatePdfFromHtml(
        document, 
        htmlContent, 
        settings.pdfSettings,
        settings.htmlSettings,
      );

      onProgress?.call(const ExportProgress(
        progress: 0.9,
        status: 'Saving PDF...',
        currentStep: 'Writing PDF file',
      ));

      await _savePdfFile(pdfBytes, settings.fullPath);

      onProgress?.call(const ExportProgress(
        progress: 1.0,
        status: 'Export completed',
        isCompleted: true,
      ));

      return ExportResult.success(
        settings.fullPath,
        fileSizeBytes: pdfBytes.length,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      return ExportResult.failure('PDF export failed: $e');
    }
  }

  /// Export as image
  Future<ExportResult> _exportToImage(
    Document document,
    ExportSettings settings,
    Function(ExportProgress)? onProgress,
  ) async {
    // Image export requires WebView or other rendering technology
    return ExportResult.failure('Image export feature not yet implemented');
  }

  /// Export as DOCX
  Future<ExportResult> _exportToDocx(
    Document document,
    ExportSettings settings,
    Function(ExportProgress)? onProgress,
  ) async {
    // DOCX export requires docx package
    return ExportResult.failure('DOCX export feature not yet implemented');
  }

  /// Generate HTML content
  String _generateHtmlContent(Document document, HtmlExportSettings settings) {
    final title = settings.title.isNotEmpty ? settings.title : document.title;
    final author = settings.author;
    final description = settings.description;

    // Basic HTML template
    final html = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    ${author.isNotEmpty ? '<meta name="author" content="$author">' : ''}
    ${description.isNotEmpty ? '<meta name="description" content="$description">' : ''}
    
    ${_generateHtmlStyles(settings)}
    ${settings.enableMathJax ? _getMathJaxScript() : ''}
    ${settings.enableMermaid ? _getMermaidScript() : ''}
</head>
<body>
    <div class="container">
        ${settings.includeTableOfContents ? _generateTableOfContents(document.content) : ''}
        <div class="content">
            ${_convertMarkdownToHtml(document.content, settings)}
        </div>
    </div>
    
    ${settings.enableMermaid ? '<script>mermaid.initialize({startOnLoad:true});</script>' : ''}
</body>
</html>
''';

    return html;
  }

  /// Generate HTML styles
  String _generateHtmlStyles(HtmlExportSettings settings) {
    final responsiveStyles = settings.responsiveDesign ? '''
@media (max-width: 768px) {
    body {
        padding: 1rem;
        font-size: 14px;
    }
    
    h1 { font-size: 2em; }
    h2 { font-size: 1.5em; }
    h3 { font-size: 1.25em; }
}
''' : '';

    final styles = '''
<style>
/* Basic styles */
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 900px;
    margin: 0 auto;
    padding: 2rem;
    ${settings.responsiveDesign ? '' : 'min-width: 900px;'}
}

.container {
    background: #fff;
}

/* Heading styles */
h1, h2, h3, h4, h5, h6 {
    margin-top: 2rem;
    margin-bottom: 1rem;
    font-weight: 600;
    line-height: 1.25;
}

h1 { font-size: 2.5em; border-bottom: 2px solid #eee; padding-bottom: 0.5rem; }
h2 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3rem; }
h3 { font-size: 1.5em; }
h4 { font-size: 1.25em; }
h5 { font-size: 1.1em; }
h6 { font-size: 1em; color: #666; }

/* Paragraph and list styles */
p { margin-bottom: 1rem; }
ul, ol { margin-bottom: 1rem; padding-left: 2rem; }
li { margin-bottom: 0.25rem; }

/* Code styles */
code {
    background: #f6f8fa;
    border-radius: 3px;
    padding: 0.2em 0.4em;
    font-family: 'SF Mono', Consolas, 'Liberation Mono', Menlo, monospace;
    font-size: 0.9em;
}

pre {
    background: #f6f8fa;
    border-radius: 6px;
    padding: 1rem;
    overflow-x: auto;
    margin-bottom: 1rem;
}

pre code {
    background: none;
    padding: 0;
}

/* Quote styles */
blockquote {
    border-left: 4px solid #dfe2e5;
    padding-left: 1rem;
    margin-left: 0;
    margin-bottom: 1rem;
    color: #666;
}

/* Table styles */
table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 1rem;
}

th, td {
    border: 1px solid #dfe2e5;
    padding: 0.5rem 1rem;
    text-align: left;
}

th {
    background: #f6f8fa;
    font-weight: 600;
}

/* Link styles */
a {
    color: #0366d6;
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

/* Image styles */
img {
    max-width: 100%;
    height: auto;
    border-radius: 6px;
    margin: 1rem 0;
}

/* Table of contents styles */
.toc {
    background: #f6f8fa;
    border-radius: 6px;
    padding: 1rem;
    margin-bottom: 2rem;
}

.toc h2 {
    margin-top: 0;
    margin-bottom: 1rem;
    border-bottom: none;
    font-size: 1.25em;
}

.toc ul {
    margin-bottom: 0;
}

/* Responsive design */
${responsiveStyles}

/* Custom CSS */
${settings.customCss}
</style>
''';

    return styles;
  }

  /// Get MathJax script
  String _getMathJaxScript() {
    return '''
<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
<script>
MathJax = {
  tex: {
    inlineMath: [['\$', '\$']],
    displayMath: [['\$\$', '\$\$']]
  }
};
</script>
''';
  }

  /// Get Mermaid script
  String _getMermaidScript() {
    return '<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>';
  }

  /// Generate table of contents
  String _generateTableOfContents(String content) {
    final lines = content.split('\n');
    final tocItems = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#')) {
        final level = trimmed.indexOf(' ');
        if (level > 0) {
          final title = trimmed.substring(level + 1);
          final anchor = title.toLowerCase()
              .replaceAll(RegExp(r'[^\w\s-]'), '')
              .replaceAll(' ', '-');
          final indent = '  ' * (level - 1);
          tocItems.add('$indent<li><a href="#$anchor">$title</a></li>');
        }
      }
    }

    if (tocItems.isEmpty) return '';

    return '''
<div class="toc">
    <h2>Table of Contents</h2>
    <ul>
        ${tocItems.join('\n        ')}
    </ul>
</div>
''';
  }

  /// Convert Markdown to HTML (simplified version)
  String _convertMarkdownToHtml(String content, HtmlExportSettings settings) {
    var html = content;

    // Headings
    html = html.replaceAllMapped(RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true), (match) {
      final level = match.group(1)!.length;
      final title = match.group(2)!;
      final anchor = title.toLowerCase()
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '-');
      return '<h$level id="$anchor">$title</h$level>';
    });

    // Bold
    html = html.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) {
      return '<strong>${match.group(1)}</strong>';
    });

    // Italic
    html = html.replaceAllMapped(RegExp(r'\*(.*?)\*'), (match) {
      return '<em>${match.group(1)}</em>';
    });

    // Inline code
    html = html.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) {
      return '<code>${match.group(1)}</code>';
    });

    // Code blocks
    html = html.replaceAllMapped(RegExp(r'```(\w+)?\n([\s\S]*?)\n```'), (match) {
      final language = match.group(1) ?? '';
      final code = match.group(2)!;
      return '<pre><code class="language-$language">$code</code></pre>';
    });

    // Links
    html = html.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (match) {
      final text = match.group(1)!;
      final url = match.group(2)!;
      return '<a href="$url">$text</a>';
    });

    // Paragraphs
    final paragraphs = html.split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .map((p) {
          if (p.trim().startsWith('<')) return p; // Already HTML
          return '<p>${p.trim()}</p>';
        }).join('\n\n');

    return paragraphs;
  }

  /// Generate PDF from HTML
  Future<Uint8List> _generatePdfFromHtml(
    Document document,
    String htmlContent, 
    PdfExportSettings pdfSettings,
    HtmlExportSettings htmlSettings,
  ) async {
    final pdf = pw.Document();
    
    // Get document title
    final title = htmlSettings.title.isNotEmpty 
        ? htmlSettings.title 
        : document.title.isNotEmpty 
            ? document.title 
            : 'Document';
    
    // Create PDF page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: _getPdfPageFormat(pdfSettings.pageSize),
        margin: pw.EdgeInsets.all(_convertToPoints(pdfSettings.marginTop)),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text: _stripHtmlTags(htmlContent),
              style: pw.TextStyle(
                fontSize: pdfSettings.fontSize,
                lineSpacing: pdfSettings.lineHeight,
              ),
            ),
            if (pdfSettings.includePageNumbers)
              pw.Footer(
                trailing: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
          ];
        },
      ),
    );
    
    return pdf.save();
  }

  /// Save HTML file
  Future<void> _saveHtmlFile(String content, String path) async {
    try {
      final file = File(path);
      
      // Ensure directory exists
      final directory = Directory(path.substring(0, path.lastIndexOf(Platform.pathSeparator)));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      await file.writeAsString(content, encoding: utf8);
      debugPrint('HTML file saved to: $path');
    } catch (e) {
      throw Exception('Failed to save HTML file: $e');
    }
  }

  /// Save PDF file
  Future<void> _savePdfFile(Uint8List bytes, String path) async {
    try {
      final file = File(path);
      
      // Ensure directory exists
      final directory = Directory(path.substring(0, path.lastIndexOf(Platform.pathSeparator)));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      await file.writeAsBytes(bytes);
      debugPrint('PDF file saved to: $path');
    } catch (e) {
      throw Exception('Failed to save PDF file: $e');
    }
  }
  
  /// Get PDF page format
  PdfPageFormat _getPdfPageFormat(String pageSize) {
    switch (pageSize.toLowerCase()) {
      case 'a3':
        return PdfPageFormat.a3;
      case 'a4':
        return PdfPageFormat.a4;
      case 'a5':
        return PdfPageFormat.a5;
      case 'letter':
        return PdfPageFormat.letter;
      case 'legal':
        return PdfPageFormat.legal;
      default:
        return PdfPageFormat.a4;
    }
  }
  
  /// Convert margin to points
  double _convertToPoints(double margin) {
    // Assume input margin unit is centimeters, convert to points (1cm = 28.35 points)
    return margin * 28.35;
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
}