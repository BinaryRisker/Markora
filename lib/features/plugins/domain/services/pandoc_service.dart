import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:process/process.dart';
import 'package:path/path.dart' as path;

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
  
  /// 检查pandoc是否已安装
  static Future<bool> isPandocInstalled() async {
    try {
      // 跨平台检查pandoc是否可用
      final result = await _processManager.run([
        'pandoc',
        '--version'
      ]);
      
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Pandoc availability check failed: $e');
      return false;
    }
  }
  
  /// 检查平台是否支持pandoc
  static bool isPlatformSupported() {
    // 只在桌面端支持pandoc
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// 获取pandoc版本信息
  static Future<String?> getPandocVersion() async {
    try {
      final result = await _processManager.run([
        'pandoc',
        '--version'
      ]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // 提取版本号 (通常在第一行)
        final lines = output.split('\n');
        if (lines.isNotEmpty) {
          return lines.first.trim();
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
      
      // 构建pandoc命令
      final args = [
        'pandoc',
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
          args.add('--${entry.key}');
          if (entry.value.isNotEmpty) {
            args.add(entry.value);
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
      // 构建pandoc命令
      final args = [
        'pandoc',
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
  
  /// 获取默认的导出选项
  static Map<String, String> getDefaultExportOptions(PandocExportFormat format) {
    switch (format) {
      case PandocExportFormat.pdf:
        return {
          'pdf-engine': 'xelatex',
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