import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:process/process.dart';
import 'package:path_provider/path_provider.dart';
import '../../../types/plugin.dart';
import 'plugin_interface.dart';

/// External Pandoc Plugin Proxy
/// This class serves as a proxy to load and manage external Pandoc plugins
class ExternalPandocPluginProxy extends MarkoraPlugin {
  ExternalPandocPluginProxy(this._metadata, this._pluginPath);
  
  final PluginMetadata _metadata;
  final String _pluginPath;
  bool _isInitialized = false;
  PluginContext? _context;
  dynamic _actualPlugin;
  
  @override
  PluginMetadata get metadata => _metadata;
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    _context = context;
    
    try {
      // Try to load the actual plugin implementation
      await _loadActualPlugin();
      
      // Register export toolbar action with different icon
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'pandoc_export',
          title: 'Export',
          description: 'Export document using Pandoc',
          icon: 'export',
        ),
        () => _handleExportAction(context),
      );
      
      // Register import toolbar action with different icon
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'pandoc_import',
          title: 'Import',
          description: 'Import document using Pandoc',
          icon: 'import',
        ),
        () => _handleImportAction(context),
      );
      
      _isInitialized = true;
      debugPrint('External Pandoc plugin proxy loaded successfully from: $_pluginPath');
    } catch (e) {
      debugPrint('Failed to load external Pandoc plugin: $e');
      rethrow;
    }
  }
  
  /// Load the actual plugin implementation
  Future<void> _loadActualPlugin() async {
    try {
      // For now, we'll create a mock implementation
      // In a real implementation, this would load the plugin from the file system
      debugPrint('Loading actual Pandoc plugin from: $_pluginPath');
      
      // Create a mock plugin instance
      _actualPlugin = _MockPandocPlugin();
      
      debugPrint('Actual Pandoc plugin loaded successfully');
    } catch (e) {
      debugPrint('Failed to load actual plugin: $e');
      // Continue with proxy implementation
    }
  }
  
  @override
  Future<void> onUnload() async {
    if (_context != null) {
      _context!.toolbarRegistry.unregisterAction('pandoc_export');
      _context!.toolbarRegistry.unregisterAction('pandoc_import');
    }
    _isInitialized = false;
  }
  
  @override
  Future<void> onActivate() async {
    // Plugin activated
  }
  
  @override
  Future<void> onDeactivate() async {
    // Plugin deactivated
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    // Configuration changed
  }
  
  @override
  Widget? getConfigWidget() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pandoc Plugin Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Plugin Path: $_pluginPath',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This is an external Pandoc plugin loaded from the plugins directory.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _checkPandocStatus(context),
              child: const Text('Check Pandoc Status'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'pluginPath': _pluginPath,
      'type': 'external',
      'pandocExecutableExists': _checkPandocExecutableExists(),
    };
  }
  
  void _handleExportAction(PluginContext pluginContext) {
    final context = pluginContext.context;
    if (context == null) {
      debugPrint('No UI context available for export dialog');
      return;
    }
    
    // Check if Pandoc executable exists
    if (!_checkPandocExecutableExists()) {
      _showPandocNotFoundDialog(context);
      return;
    }
    
    // Show export dialog
    _showExportDialog(context, pluginContext);
  }

  void _handleImportAction(PluginContext pluginContext) {
    final context = pluginContext.context;
    if (context == null) {
      debugPrint('No UI context available for import dialog');
      return;
    }
    
    // Check if Pandoc executable exists
    if (!_checkPandocExecutableExists()) {
      _showPandocNotFoundDialog(context);
      return;
    }
    
    // Show import dialog
    _showImportDialog(context, pluginContext);
  }
  
  bool _checkPandocExecutableExists() {
    final platformName = _getPlatformName();
    final executableName = _getExecutableName();
    final executablePath = path.join(_pluginPath, 'assets', 'pandoc', platformName, executableName);
    return File(executablePath).existsSync();
  }
  
  String _getPlatformName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    throw UnsupportedError('Unsupported platform');
  }
  
  String _getExecutableName() {
    return Platform.isWindows ? 'pandoc.exe' : 'pandoc';
  }
  
  void _showPandocNotFoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pandoc Not Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pandoc executable is not found in the plugin directory.'),
            const SizedBox(height: 16),
            Text('Expected location: ${path.join(_pluginPath, 'assets', 'pandoc', _getPlatformName(), _getExecutableName())}'),
            const SizedBox(height: 16),
            const Text('Please download Pandoc executable and place it in the correct directory.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showExportDialog(BuildContext context, PluginContext pluginContext) {
    showDialog(
      context: context,
      builder: (context) => _PandocExportDialog(
        pluginContext: pluginContext,
        pluginPath: _pluginPath,
      ),
    );
  }
  
  void _showImportDialog(BuildContext context, PluginContext pluginContext) {
    showDialog(
      context: context,
      builder: (context) => _PandocImportDialog(
        pluginContext: pluginContext,
        pluginPath: _pluginPath,
      ),
    );
  }
  
  void _checkPandocStatus(BuildContext context) {
    final exists = _checkPandocExecutableExists();
    final platformName = _getPlatformName();
    final executableName = _getExecutableName();
    final executablePath = path.join(_pluginPath, 'assets', 'pandoc', platformName, executableName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pandoc Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform: $platformName'),
            Text('Executable: $executableName'),
            Text('Path: $executablePath'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  exists ? Icons.check_circle : Icons.error,
                  color: exists ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(exists ? 'Pandoc executable found' : 'Pandoc executable not found'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Mock Pandoc Plugin for testing
class _MockPandocPlugin {
  // Mock implementation for testing
}

/// Pandoc conversion result
class _PandocResult {
  final bool success;
  final String? output;
  final String? error;

  const _PandocResult({
    required this.success,
    this.output,
    this.error,
  });

  factory _PandocResult.success(String output) {
    return _PandocResult(
      success: true,
      output: output,
    );
  }

  factory _PandocResult.failure(String error) {
    return _PandocResult(
      success: false,
      error: error,
    );
  }
}

/// Pandoc Export Formats
enum _PandocExportFormat {
  pdf('pdf', 'PDF Document'),
  html('html', 'HTML Document'),
  docx('docx', 'Microsoft Word Document'),
  odt('odt', 'OpenDocument Text'),
  latex('latex', 'LaTeX Document'),
  rtf('rtf', 'Rich Text Format'),
  epub('epub', 'EPUB eBook'),
  txt('txt', 'Plain Text');
  
  const _PandocExportFormat(this.extension, this.displayName);
  final String extension;
  final String displayName;
}

/// Pandoc Import Formats
enum _PandocImportFormat {
  html('html', 'HTML Document'),
  docx('docx', 'Microsoft Word Document'),
  odt('odt', 'OpenDocument Text'),
  latex('latex', 'LaTeX Document'),
  rtf('rtf', 'Rich Text Format'),
  epub('epub', 'EPUB eBook'),
  txt('txt', 'Plain Text');
  
  const _PandocImportFormat(this.extension, this.displayName);
  final String extension;
  final String displayName;
}

/// Pandoc Export Dialog
class _PandocExportDialog extends StatefulWidget {
  const _PandocExportDialog({
    required this.pluginContext,
    required this.pluginPath,
  });

  final PluginContext pluginContext;
  final String pluginPath;

  @override
  State<_PandocExportDialog> createState() => _PandocExportDialogState();
}

class _PandocExportDialogState extends State<_PandocExportDialog> {
  _PandocExportFormat _selectedFormat = _PandocExportFormat.pdf;
  String? _outputPath;
  bool _isExporting = false;
  bool _pandocAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkPandocAvailability();
  }

  Future<void> _checkPandocAvailability() async {
    // Check if Pandoc executable exists
    final platformName = _getPlatformName();
    final executableName = _getExecutableName();
    final executablePath = path.join(widget.pluginPath, 'assets', 'pandoc', platformName, executableName);
    final exists = File(executablePath).existsSync();
    
    setState(() {
      _pandocAvailable = exists;
    });
  }

  String _getPlatformName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    throw UnsupportedError('Unsupported platform');
  }
  
  String _getExecutableName() {
    return Platform.isWindows ? 'pandoc.exe' : 'pandoc';
  }

  String _getCurrentDocumentTitle() {
    try {
      // Try to get the current document title from the context
      final content = widget.pluginContext.editorController.content;
      
      // Extract title from first heading if available
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.startsWith('# ')) {
          final title = line.substring(2).trim();
          if (title.isNotEmpty) {
            // Clean up title for filename
            return title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          }
        }
      }
      
      // Default title if no heading found
      return 'document';
    } catch (e) {
      return 'document';
    }
  }

  Future<void> _selectOutputPath() async {
    try {
      // Get current document title for default filename
      final currentTitle = _getCurrentDocumentTitle();
      final defaultFileName = '$currentTitle.${_selectedFormat.extension}';
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择输出文件',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: [_selectedFormat.extension],
      );

      if (result != null) {
        setState(() {
          _outputPath = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportDocument() async {
    if (_outputPath == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // Get current content
      final content = widget.pluginContext.editorController.content;
      
      // Call Pandoc to convert the content
      final result = await _convertWithPandoc(content, _selectedFormat, _outputPath!);
      
      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导出成功: $_outputPath'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          // Check if it's a PDF engine error
          if (result.error != null && 
              (result.error!.contains('pdflatex') || result.error!.contains('pdf-engine') || result.error!.contains('not found')) &&
              _selectedFormat == _PandocExportFormat.pdf) {
            // Show simplified dialog for PDF errors
            _showSimplePdfErrorDialog(result.error!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('导出失败: ${result.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<_PandocResult> _convertWithPandoc(String content, _PandocExportFormat format, String outputPath) async {
    try {
      // Find Pandoc executable
      final pandocPath = await _findPandocExecutable();
      if (pandocPath == null) {
        return _PandocResult.failure('Pandoc executable not found');
      }

      // Create temporary input file
      final tempDir = await getTemporaryDirectory();
      final inputFile = File(path.join(tempDir.path, 'input.md'));
      await inputFile.writeAsString(content);

      // Build Pandoc command
      final args = [
        pandocPath,
        '-f', 'markdown',
        '-t', format.extension,
        '-o', outputPath,
        inputFile.path,
      ];

      // Add format-specific options
      if (format == _PandocExportFormat.pdf) {
        // For PDF, use basic options and let Pandoc choose the best available engine
        args.addAll([
          '--standalone',
        ]);
        
        // Don't specify PDF engine - let Pandoc use its default
        // This allows Pandoc to automatically choose the best available engine
        debugPrint('Using Pandoc default PDF engine for conversion');
      } else if (format == _PandocExportFormat.html) {
        // Add standalone HTML document
        args.addAll([
          '--standalone',
          '--self-contained',
        ]);
      } else if (format == _PandocExportFormat.docx) {
        // Add reference document if available
        args.add('--standalone');
      }

      // Execute Pandoc
      const processManager = LocalProcessManager();
      final result = await processManager.run(args);

      // Clean up temporary file
      await inputFile.delete();

      if (result.exitCode == 0) {
        return _PandocResult.success(outputPath);
      } else {
        final error = result.stderr.toString();
        final stdout = result.stdout.toString();
        debugPrint('Pandoc command: ${args.join(' ')}');
        debugPrint('Pandoc stderr: $error');
        debugPrint('Pandoc stdout: $stdout');
        
        // Provide more user-friendly error messages
        String userError = error;
        if (error.contains('pdflatex') || error.contains('pdf-engine') || error.contains('not found')) {
          userError = 'PDF 导出失败：Pandoc 无法找到合适的 PDF 引擎。\n\n建议解决方案：\n1. 尝试导出为 HTML 格式\n2. 如需 PDF，请安装 LaTeX 或 wkhtmltopdf';
        } else if (error.contains('pandoc: command not found')) {
          userError = 'Pandoc 未找到，请确保 Pandoc 已正确安装。';
        } else if (error.trim().isEmpty && stdout.trim().isEmpty) {
          userError = 'Pandoc 转换失败：未知错误。';
        }
        
        return _PandocResult.failure(userError);
      }
    } catch (e) {
      return _PandocResult.failure('Conversion error: $e');
    }
  }

  Future<String?> _findPandocExecutable() async {
    // First try to find bundled Pandoc
    final platformName = _getPlatformName();
    final executableName = _getExecutableName();
    final bundledPath = path.join(widget.pluginPath, 'assets', 'pandoc', platformName, executableName);
    
    if (File(bundledPath).existsSync()) {
      return bundledPath;
    }

    // Try system Pandoc
    try {
      const processManager = LocalProcessManager();
      final result = await processManager.run(['pandoc', '--version']);
      if (result.exitCode == 0) {
        return 'pandoc';
      }
    } catch (e) {
      // System Pandoc not found
    }

    return null;
  }

  Future<String?> _detectPdfEngine() async {
    // Always return null to use Pandoc's default PDF engine
    // This avoids the need to install external PDF engines
    debugPrint('Using Pandoc default PDF engine');
    return null;
  }

  void _showSimplePdfErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('PDF 导出失败'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PDF 导出失败，Pandoc 无法找到合适的 PDF 引擎。'),
            const SizedBox(height: 16),
            const Text('建议解决方案：'),
            const Text('1. 导出为 HTML 格式（推荐）'),
            const Text('2. 手动安装 LaTeX 或 wkhtmltopdf'),
            const SizedBox(height: 16),
            const Text('是否要改为导出 HTML 格式？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Change format to HTML and retry
              setState(() {
                _selectedFormat = _PandocExportFormat.html;
              });
              // Auto-retry with HTML format
              _exportDocument();
            },
            child: const Text('导出为 HTML'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    if (!_pandocAvailable) {
      return AlertDialog(
        title: const Text('Pandoc 不可用'),
        content: const Text('Pandoc 可执行文件未找到。请按照说明下载并放置 Pandoc 可执行文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_upload_outlined),
          SizedBox(width: 8),
          Text('导出文档'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            const Text('导出格式:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<_PandocExportFormat>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _PandocExportFormat.values.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format.displayName),
                );
              }).toList(),
              onChanged: (format) {
                if (format != null) {
                  setState(() {
                    _selectedFormat = format;
                    _outputPath = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Output path
            const Text('输出文件:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: '选择输出文件...',
                    ),
                    controller: TextEditingController(text: _outputPath ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectOutputPath,
                  child: const Icon(Icons.folder_open),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _outputPath != null && !_isExporting ? _exportDocument : null,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('导出'),
        ),
      ],
    );
  }
}

/// Pandoc Import Dialog
class _PandocImportDialog extends StatefulWidget {
  const _PandocImportDialog({
    required this.pluginContext,
    required this.pluginPath,
  });

  final PluginContext pluginContext;
  final String pluginPath;

  @override
  State<_PandocImportDialog> createState() => _PandocImportDialogState();
}

class _PandocImportDialogState extends State<_PandocImportDialog> {
  _PandocImportFormat _selectedFormat = _PandocImportFormat.docx;
  String? _inputPath;
  bool _isImporting = false;
  bool _pandocAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkPandocAvailability();
  }

  Future<void> _checkPandocAvailability() async {
    // Check if Pandoc executable exists
    final platformName = _getPlatformName();
    final executableName = _getExecutableName();
    final executablePath = path.join(widget.pluginPath, 'assets', 'pandoc', platformName, executableName);
    final exists = File(executablePath).existsSync();
    
    setState(() {
      _pandocAvailable = exists;
    });
  }

  String _getPlatformName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    throw UnsupportedError('Unsupported platform');
  }
  
  String _getExecutableName() {
    return Platform.isWindows ? 'pandoc.exe' : 'pandoc';
  }

  Future<void> _selectInputFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [_selectedFormat.extension],
        dialogTitle: '选择要导入的文件',
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _inputPath = result.files.first.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importDocument() async {
    if (_inputPath == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // Check if input file exists
      final inputFile = File(_inputPath!);
      if (!await inputFile.exists()) {
        throw Exception('文件不存在');
      }
      
      // Convert with Pandoc
      final result = await _convertFromPandoc(_inputPath!, _selectedFormat);
      
      if (result.success && result.output != null) {
        // Set content to editor
        widget.pluginContext.editorController.setContent(result.output!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('导入成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导入失败: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<_PandocResult> _convertFromPandoc(String inputPath, _PandocImportFormat format) async {
    try {
      // Find Pandoc executable
      final pandocPath = await _findPandocExecutableForImport();
      if (pandocPath == null) {
        return _PandocResult.failure('Pandoc executable not found');
      }

      // Build Pandoc command
      final args = [
        pandocPath,
        '-f', format.extension,
        '-t', 'markdown',
        inputPath,
      ];

      // Execute Pandoc
      const processManager = LocalProcessManager();
      final result = await processManager.run(args);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        return _PandocResult.success(output);
      } else {
        final error = result.stderr.toString();
        return _PandocResult.failure('Pandoc conversion failed: $error');
      }
    } catch (e) {
      return _PandocResult.failure('Conversion error: $e');
    }
  }

  Future<String?> _findPandocExecutableForImport() async {
    // First try to find bundled Pandoc
    final platformName = _getPlatformName();
    final executableName = _getExecutableName();
    final bundledPath = path.join(widget.pluginPath, 'assets', 'pandoc', platformName, executableName);
    
    if (File(bundledPath).existsSync()) {
      return bundledPath;
    }

    // Try system Pandoc
    try {
      const processManager = LocalProcessManager();
      final result = await processManager.run(['pandoc', '--version']);
      if (result.exitCode == 0) {
        return 'pandoc';
      }
    } catch (e) {
      // System Pandoc not found
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_pandocAvailable) {
      return AlertDialog(
        title: const Text('Pandoc 不可用'),
        content: const Text('Pandoc 可执行文件未找到。请按照说明下载并放置 Pandoc 可执行文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download_outlined),
          SizedBox(width: 8),
          Text('导入文档'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            const Text('导入格式:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<_PandocImportFormat>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _PandocImportFormat.values.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format.displayName),
                );
              }).toList(),
              onChanged: (format) {
                if (format != null) {
                  setState(() {
                    _selectedFormat = format;
                    _inputPath = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Input file
            const Text('输入文件:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: '选择输入文件...',
                    ),
                    controller: TextEditingController(text: _inputPath ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectInputFile,
                  child: const Icon(Icons.folder_open),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _inputPath != null && !_isImporting ? _importDocument : null,
          child: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('导入'),
        ),
      ],
    );
  }
} 