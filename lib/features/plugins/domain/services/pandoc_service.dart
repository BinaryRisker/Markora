import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:process/process.dart';
import 'package:path/path.dart' as path;
import 'pandoc_asset_manager.dart';

/// Pandoc支持的导出格式
enum PandocExportFormat {
  pdf('pdf', 'PDF Document'),
  html('html', 'HTML Document'),
  docx('docx', 'Microsoft Word Document'),
  odt('odt', 'OpenDocument Text'),
  latex('latex', 'LaTeX Document'),
  rtf('rtf', 'Rich Text Format'),
  epub('epub', 'EPUB eBook'),
  mobi('mobi', 'Kindle eBook'),
  txt('txt', 'Plain Text'),
  json('json', 'JSON'),
  xml('xml', 'XML'),
  opml('opml', 'OPML'),
  rst('rst', 'reStructuredText'),
  mediawiki('mediawiki', 'MediaWiki'),
  textile('textile', 'Textile'),
  asciidoc('asciidoc', 'AsciiDoc');
  
  const PandocExportFormat(this.extension, this.displayName);
  final String extension;
  final String displayName;
}

/// Pandoc支持的导入格式
enum PandocImportFormat {
  html('html', 'HTML Document'),
  docx('docx', 'Microsoft Word Document'),
  odt('odt', 'OpenDocument Text'),
  latex('latex', 'LaTeX Document'),
  rtf('rtf', 'Rich Text Format'),
  epub('epub', 'EPUB eBook'),
  txt('txt', 'Plain Text'),
  json('json', 'JSON'),
  xml('xml', 'XML'),
  opml('opml', 'OPML'),
  rst('rst', 'reStructuredText'),
  mediawiki('mediawiki', 'MediaWiki'),
  textile('textile', 'Textile'),
  asciidoc('asciidoc', 'AsciiDoc');
  
  const PandocImportFormat(this.extension, this.displayName);
  final String extension;
  final String displayName;
}

/// Pandoc操作结果
class PandocResult {
  final bool success;
  final String? output;
  final String? error;
  final String? filePath;
  
  const PandocResult({
    required this.success,
    this.output,
    this.error,
    this.filePath,
  });
  
  factory PandocResult.success([String? output, String? filePath]) {
    return PandocResult(
      success: true,
      output: output,
      filePath: filePath,
    );
  }
  
  factory PandocResult.failure(String error) {
    return PandocResult(
      success: false,
      error: error,
    );
  }
}

/// Pandoc服务
class PandocService {
  static const ProcessManager _processManager = LocalProcessManager();
  static final PandocAssetManager _assetManager = PandocAssetManager();
  
  /// 获取可用的Pandoc路径（优先使用内置版本）
  static Future<String?> _getPandocPath() async {
    // 首先尝试内置版本
    if (await _assetManager.isAvailable()) {
      return _assetManager.pandocPath;
    }
    
    // 如果内置版本不可用，尝试系统安装的版本
    try {
      final result = await _processManager.run(['pandoc', '--version']);
      if (result.exitCode == 0) {
        return 'pandoc'; // 使用系统PATH中的pandoc
      }
    } catch (e) {
      debugPrint('System pandoc not available: $e');
    }
    
    return null;
  }
  
  /// 检查pandoc是否已安装（包括内置版本）
  static Future<bool> isPandocInstalled() async {
    final pandocPath = await _getPandocPath();
    return pandocPath != null;
  }
  
  /// 检查平台是否支持pandoc
  static bool isPlatformSupported() {
    // 只在桌面端支持pandoc
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// 获取pandoc版本信息
  static Future<String?> getPandocVersion() async {
    // 首先尝试内置版本
    if (await _assetManager.isAvailable()) {
      final version = await _assetManager.getPandocVersion();
      if (version != null) {
        return 'pandoc $version (built-in)';
      }
    }
    
    // 尝试系统版本
    try {
      final result = await _processManager.run(['pandoc', '--version']);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // 提取版本号 (通常在第一行)
        final lines = output.split('\n');
        if (lines.isNotEmpty) {
          return '${lines.first.trim()} (system)';
        }
      }
    } catch (e) {
      debugPrint('Failed to get pandoc version: $e');
    }
    return null;
  }
  
  /// 导出Markdown到指定格式
  static Future<PandocResult> exportFromMarkdown({
    required String markdownContent,
    required PandocExportFormat format,
    required String outputPath,
    Map<String, String>? options,
  }) async {
    if (!isPlatformSupported()) {
      return PandocResult.failure('Platform not supported');
    }
    
    if (!await isPandocInstalled()) {
      return PandocResult.failure('Pandoc not installed');
    }
    
    try {
      // 创建临时markdown文件
      final tempDir = Directory.systemTemp.createTempSync('markora_export_');
      final tempMdFile = File(path.join(tempDir.path, 'temp.md'));
      await tempMdFile.writeAsString(markdownContent);
      
      // 获取pandoc路径
      final pandocPath = await _getPandocPath();
      if (pandocPath == null) {
        return PandocResult.failure('Pandoc not available');
      }
      
      // 构建pandoc命令
      final args = [
        pandocPath,
        tempMdFile.path,
        '-o',
        outputPath,
        '--from',
        'markdown',
        '--to',
        format.extension,
      ];
      
      // 添加额外选项
      if (options != null) {
        for (final entry in options.entries) {
          if (entry.key == 'pdf-engine' && entry.value == 'auto') {
            // 动态检测PDF引擎
            final engine = await _detectPdfEngine();
            if (engine != 'html') {
              args.add('--pdf-engine');
              args.add(engine);
            } else {
              // 如果没有PDF引擎，先导出为HTML再转换
              debugPrint('PandocService: No PDF engine available, using HTML fallback');
              return await _exportPdfViaHtml(markdownContent, outputPath);
            }
          } else {
            args.add('--${entry.key}');
            if (entry.value.isNotEmpty) {
              args.add(entry.value);
            }
          }
        }
      }
      
      // 执行pandoc命令
      final result = await _processManager.run(args);
      
      // 清理临时文件
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        debugPrint('Failed to clean temp directory: $e');
      }
      
      if (result.exitCode == 0) {
        return PandocResult.success(result.stdout.toString(), outputPath);
      } else {
        return PandocResult.failure(result.stderr.toString());
      }
    } catch (e) {
      return PandocResult.failure('Export failed: $e');
    }
  }
  
  /// 从指定格式导入为Markdown
  static Future<PandocResult> importToMarkdown({
    required String inputPath,
    required PandocImportFormat format,
    Map<String, String>? options,
  }) async {
    if (!isPlatformSupported()) {
      return PandocResult.failure('Platform not supported');
    }
    
    if (!await isPandocInstalled()) {
      return PandocResult.failure('Pandoc not installed');
    }
    
    try {
      // 获取pandoc路径
      final pandocPath = await _getPandocPath();
      if (pandocPath == null) {
        return PandocResult.failure('Pandoc not available');
      }
      
      // 构建pandoc命令
      final args = [
        pandocPath,
        inputPath,
        '--from',
        format.extension,
        '--to',
        'markdown',
      ];
      
      // 添加额外选项
      if (options != null) {
        for (final entry in options.entries) {
          args.add('--${entry.key}');
          if (entry.value.isNotEmpty) {
            args.add(entry.value);
          }
        }
      }
      
      // 执行pandoc命令
      final result = await _processManager.run(args);
      
      if (result.exitCode == 0) {
        return PandocResult.success(result.stdout.toString());
      } else {
        return PandocResult.failure(result.stderr.toString());
      }
    } catch (e) {
      return PandocResult.failure('Import failed: $e');
    }
  }
  
  /// 获取支持的导出格式
  static List<PandocExportFormat> getSupportedExportFormats() {
    return PandocExportFormat.values;
  }
  
  /// 获取支持的导入格式
  static List<PandocImportFormat> getSupportedImportFormats() {
    return PandocImportFormat.values;
  }
  
  /// 获取格式的文件扩展名
  static String getFileExtension(String format) {
    // 处理特殊情况
    switch (format.toLowerCase()) {
      case 'latex':
        return 'tex';
      case 'mediawiki':
        return 'wiki';
      default:
        return format.toLowerCase();
    }
  }
  
  /// 检测可用的PDF引擎
  static Future<String> _detectPdfEngine() async {
    // PDF引擎优先级列表（从最简单到最复杂）
    final engines = ['wkhtmltopdf', 'weasyprint', 'prince', 'pdflatex', 'xelatex', 'lualatex'];
    
    for (final engine in engines) {
      try {
        final result = await _processManager.run([engine, '--version']);
        if (result.exitCode == 0) {
          debugPrint('PandocService: Found PDF engine: $engine');
          return engine;
        }
      } catch (e) {
        // 引擎不可用，继续尝试下一个
      }
    }
    
    // 如果没有找到任何PDF引擎，使用HTML作为中间格式
    debugPrint('PandocService: No PDF engine found, will use HTML conversion');
    return 'html';
  }
  
  /// 通过HTML中间格式导出PDF（当没有PDF引擎时）
  static Future<PandocResult> _exportPdfViaHtml(String markdownContent, String outputPath) async {
    try {
      // 创建临时HTML文件
      final tempDir = Directory.systemTemp.createTempSync('markora_pdf_export_');
      final tempHtmlFile = File(path.join(tempDir.path, 'temp.html'));
      
      // 获取pandoc路径
      final pandocPath = await _getPandocPath();
      if (pandocPath == null) {
        return PandocResult.failure('Pandoc not available');
      }
      
      // 先转换为HTML
      final htmlResult = await exportFromMarkdown(
        markdownContent: markdownContent,
        format: PandocExportFormat.html,
        outputPath: tempHtmlFile.path,
        options: {
          'standalone': '',
          'mathjax': '',
          'css': '', // 可以添加CSS样式
        },
      );
      
      if (!htmlResult.success) {
        return PandocResult.failure('HTML conversion failed: ${htmlResult.error}');
      }
      
      // 清理临时文件
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        debugPrint('Failed to clean temp directory: $e');
      }
      
      // 返回HTML文件路径，并提示用户手动转换
      return PandocResult.failure(
        'PDF export requires a PDF engine (like wkhtmltopdf, xelatex, etc.). '
        'Please install a PDF engine or export as HTML instead. '
        'Available engines: wkhtmltopdf, weasyprint, pdflatex, xelatex, lualatex'
      );
      
    } catch (e) {
      return PandocResult.failure('PDF export via HTML failed: $e');
    }
  }

  /// 获取默认的导出选项
  static Map<String, String> getDefaultExportOptions(PandocExportFormat format) {
    switch (format) {
      case PandocExportFormat.pdf:
        return {
          // 动态检测PDF引擎
          'pdf-engine': 'auto', // 特殊标记，表示需要动态检测
          'variable': 'geometry:margin=1in',
        };
      case PandocExportFormat.html:
        return {
          'standalone': '',
          'mathjax': '',
          'highlight-style': 'github',
        };
      case PandocExportFormat.docx:
        return {
          'reference-doc': '', // 可以设置参考文档
        };
      case PandocExportFormat.epub:
        return {
          'epub-cover-image': '', // 可以设置封面图片
        };
      default:
        return {};
    }
  }
} 