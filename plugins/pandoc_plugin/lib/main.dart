import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:process/process.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Plugin interfaces - these should be defined locally for plugin independence
// In a real implementation, these would be provided by the plugin system

/// Plugin metadata
class PluginMetadata {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final String? homepage;
  final String? repository;
  final String license;
  final PluginType type;
  final List<String> tags;
  final String minVersion;
  final String? maxVersion;
  final List<String> dependencies;
  
  const PluginMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    this.homepage,
    this.repository,
    required this.license,
    required this.type,
    required this.tags,
    required this.minVersion,
    this.maxVersion,
    this.dependencies = const [],
  });
}

/// Plugin types
enum PluginType {
  syntax,
  renderer,
  theme,
  export,
  exporter,
  tool,
  integration,
}

/// Plugin action
class PluginAction {
  final String id;
  final String title;
  final String description;
  final String icon;
  
  const PluginAction({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Plugin context
abstract class PluginContext {
  BuildContext get context;
  EditorController get editorController;
  ToolbarRegistry get toolbarRegistry;
}

/// Editor controller
abstract class EditorController {
  String get content;
  String getCurrentContent();
  void setContent(String content);
}

/// Toolbar registry
abstract class ToolbarRegistry {
  void registerAction(PluginAction action, VoidCallback callback);
  void unregisterAction(String actionId);
}

/// Base plugin class
abstract class MarkoraPlugin {
  PluginMetadata get metadata;
  bool get isInitialized;
  
  Future<void> onLoad(PluginContext context);
  Future<void> onUnload();
  Future<void> onActivate();
  Future<void> onDeactivate();
  void onConfigChanged(Map<String, dynamic> config);
  Widget? getConfigWidget();
  Map<String, dynamic> getStatus();
}

/// Pandoc Export Plugin
class PandocPlugin extends MarkoraPlugin {
  late PluginContext _context;
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;
  final PandocAssetManager _assetManager = PandocAssetManager();

  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: 'pandoc_plugin',
    name: 'Pandoc Export Plugin',
    version: '1.0.0',
    description: 'Universal document converter using Pandoc - support export to PDF, HTML, DOCX, ODT and many other formats',
    author: 'Markora Team',
    homepage: 'https://github.com/markora/pandoc-plugin',
    repository: 'https://github.com/markora/pandoc-plugin.git',
    license: 'MIT',
    type: PluginType.export,
    tags: ['export', 'import', 'pandoc', 'converter', 'pdf', 'html', 'docx'],
    minVersion: '1.0.0',
  );

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> onLoad(PluginContext context) async {
    debugPrint('Pandoc Plugin: onLoad called');
    _context = context;
    debugPrint('Pandoc Plugin: Context set, BuildContext type: ${context.context?.runtimeType}');
    
    // Initialize asset manager
    debugPrint('Pandoc Plugin: Initializing asset manager...');
    await _assetManager.initialize();
    debugPrint('Pandoc Plugin: Asset manager initialized');
    
    // Register toolbar actions
    debugPrint('Pandoc Plugin: Registering toolbar actions...');
    _context.toolbarRegistry.registerAction(
      const PluginAction(
        id: 'pandoc_export',
        title: 'Export',
        description: 'Export document using Pandoc',
        icon: 'export',
      ),
      () {
        debugPrint('Pandoc Plugin: Export action callback called');
        _showExportDialog();
      },
    );
    
    _context.toolbarRegistry.registerAction(
      const PluginAction(
        id: 'pandoc_import',
        title: 'Import',
        description: 'Import document using Pandoc',
        icon: 'import',
      ),
      () {
        debugPrint('Pandoc Plugin: Import action callback called');
        _showImportDialog();
      },
    );
    
    _isInitialized = true;
    debugPrint('Pandoc Plugin: onLoad completed successfully');
  }

  @override
  Future<void> onUnload() async {
    // Clean up resources
    _context.toolbarRegistry.unregisterAction('pandoc_export');
    _context.toolbarRegistry.unregisterAction('pandoc_import');
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
    _config = config;
  }

  @override
  Widget? getConfigWidget() {
    return PandocConfigWidget(
      config: _config,
      onConfigChanged: onConfigChanged,
    );
  }

  @override
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'pandocAvailable': _assetManager.isAvailable(),
      'version': _assetManager.version,
    };
  }

  void _showExportDialog() {
    debugPrint('Pandoc Plugin: _showExportDialog called');
    
    // Get current content from context
    final content = _context.editorController.getCurrentContent();
    debugPrint('Pandoc Plugin: Got content with length: ${content.length}');
    
    // Check if context is available
    if (_context.context == null) {
      debugPrint('Pandoc Plugin: No BuildContext available for export dialog');
      return;
    }
    
    debugPrint('Pandoc Plugin: BuildContext is available: ${_context.context.runtimeType}');
    debugPrint('Pandoc Plugin: About to show export dialog');
    
    try {
      // Show the actual Pandoc export dialog
      debugPrint('Pandoc Plugin: Calling showDialog...');
      showDialog(
        context: _context.context!,
        builder: (context) {
          debugPrint('Pandoc Plugin: Dialog builder called');
          return PandocExportDialog(
            markdownContent: content,
            assetManager: _assetManager,
          );
        },
      );
      debugPrint('Pandoc Plugin: showDialog call completed');
    } catch (e) {
      debugPrint('Pandoc Plugin: Error showing export dialog: $e');
      debugPrint('Pandoc Plugin: Error stack trace: ${e.toString()}');
    }
  }

  void _showImportDialog() {
    debugPrint('Pandoc Plugin: _showImportDialog called');
    
    // Check if context is available
    if (_context.context == null) {
      debugPrint('Pandoc Plugin: No BuildContext available for import dialog');
      return;
    }
    
    debugPrint('Pandoc Plugin: Showing import dialog');
    
    try {
      showDialog(
        context: _context.context!,
        builder: (context) => PandocImportDialog(
          assetManager: _assetManager,
          onImportComplete: (content) {
            _context.editorController.setContent(content);
          },
        ),
      );
    } catch (e) {
      debugPrint('Pandoc Plugin: Error showing import dialog: $e');
    }
  }
}

/// Pandoc supported export formats
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

/// Pandoc supported import formats
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

/// Pandoc operation result
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

/// Pandoc Asset Manager
class PandocAssetManager {
  static const String _assetBasePath = 'packages/pandoc_plugin/assets/pandoc';
  static const String _pandocVersion = '3.1.9';
  
  static final PandocAssetManager _instance = PandocAssetManager._internal();
  factory PandocAssetManager() => _instance;
  PandocAssetManager._internal();
  
  String? _pandocPath;
  bool _isInitialized = false;
  
  String? get pandocPath => _pandocPath;
  bool get isInitialized => _isInitialized;
  String get version => _pandocVersion;
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Check if platform is supported
      if (!_isPlatformSupported()) {
        debugPrint('PandocAssetManager: Platform not supported');
        return false;
      }
      
      // Try to extract bundled pandoc
      final extractedPath = await _extractBundledPandoc();
      if (extractedPath != null) {
        _pandocPath = extractedPath;
        _isInitialized = true;
        debugPrint('PandocAssetManager: Using bundled pandoc at $_pandocPath');
        return true;
      }
      
      // Fallback to system pandoc
      final systemPath = await _findSystemPandoc();
      if (systemPath != null) {
        _pandocPath = systemPath;
        _isInitialized = true;
        debugPrint('PandocAssetManager: Using system pandoc at $_pandocPath');
        return true;
      }
      
      debugPrint('PandocAssetManager: No pandoc found');
      return false;
    } catch (e) {
      debugPrint('PandocAssetManager: Initialization failed: $e');
      return false;
    }
  }
  
  bool isAvailable() {
    return _isInitialized && _pandocPath != null;
  }
  
  bool _isPlatformSupported() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  Future<String?> _extractBundledPandoc() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pandocDir = Directory(path.join(appDir.path, 'markora', 'pandoc'));
      
      if (!await pandocDir.exists()) {
        await pandocDir.create(recursive: true);
      }
      
      final platformName = _getPlatformName();
      final executableName = _getExecutableName();
      final targetPath = path.join(pandocDir.path, executableName);
      
      // Check if already extracted
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await _setExecutablePermissions(targetPath);
        return targetPath;
      }
      
      // Extract from assets
      final assetPath = '$_assetBasePath/$platformName/$executableName';
      try {
        final bytes = await rootBundle.load(assetPath);
        await targetFile.writeAsBytes(bytes.buffer.asUint8List());
        await _setExecutablePermissions(targetPath);
        return targetPath;
      } catch (e) {
        debugPrint('PandocAssetManager: Failed to extract asset $assetPath: $e');
        return null;
      }
    } catch (e) {
      debugPrint('PandocAssetManager: Failed to extract bundled pandoc: $e');
      return null;
    }
  }
  
  Future<String?> _findSystemPandoc() async {
    try {
      const processManager = LocalProcessManager();
      final result = await processManager.run(['pandoc', '--version']);
      if (result.exitCode == 0) {
        return 'pandoc';
      }
    } catch (e) {
      debugPrint('PandocAssetManager: System pandoc not found: $e');
    }
    return null;
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
  
  Future<void> _setExecutablePermissions(String filePath) async {
    if (!Platform.isWindows) {
      try {
        const processManager = LocalProcessManager();
        await processManager.run(['chmod', '+x', filePath]);
      } catch (e) {
        debugPrint('PandocAssetManager: Failed to set executable permissions: $e');
      }
    }
  }
}

/// Pandoc Service
class PandocService {
  static const ProcessManager _processManager = LocalProcessManager();
  
  static Future<bool> isPandocInstalled(PandocAssetManager assetManager) async {
    return assetManager.isAvailable();
  }
  
  static bool isPlatformSupported() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  static Future<String?> getPandocVersion(PandocAssetManager assetManager) async {
    final pandocPath = assetManager.pandocPath;
    if (pandocPath == null) return null;
    
    try {
      final result = await _processManager.run([pandocPath, '--version']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'pandoc (\d+\.\d+(?:\.\d+)?)').firstMatch(output);
        return match?.group(1);
      }
    } catch (e) {
      debugPrint('PandocService: Failed to get version: $e');
    }
    return null;
  }
  
  static Future<PandocResult> exportDocument({
    required String markdownContent,
    required PandocExportFormat format,
    required String outputPath,
    required PandocAssetManager assetManager,
    Map<String, String>? customOptions,
  }) async {
    final pandocPath = assetManager.pandocPath;
    if (pandocPath == null) {
      return PandocResult.failure('Pandoc not available');
    }
    
    try {
      // Create temporary input file
      final tempDir = await Directory.systemTemp.createTemp('pandoc_export_');
      final inputFile = File(path.join(tempDir.path, 'input.md'));
      await inputFile.writeAsString(markdownContent);
      
      // Build pandoc command
      final args = [
        pandocPath,
        '-f', 'markdown',
        '-t', format.extension,
        '-o', outputPath,
        inputFile.path,
      ];
      
      // Add custom options
      if (customOptions != null) {
        for (final entry in customOptions.entries) {
          if (entry.value.isNotEmpty) {
            args.addAll(['--${entry.key}', entry.value]);
          } else {
            args.add('--${entry.key}');
          }
        }
      }
      
      // Special handling for PDF
      if (format == PandocExportFormat.pdf) {
        // Add standalone option for PDF
        args.add('--standalone');
        // Don't specify PDF engine - let Pandoc use its default
        // This allows Pandoc to automatically choose the best available engine
        debugPrint('PandocService: Using Pandoc default PDF engine for conversion');
      }
      
      // Execute pandoc
      final result = await _processManager.run(args);
      
      // Clean up
      await tempDir.delete(recursive: true);
      
      if (result.exitCode == 0) {
        return PandocResult.success(result.stdout.toString(), outputPath);
      } else {
        return PandocResult.failure(result.stderr.toString());
      }
    } catch (e) {
      return PandocResult.failure('Export failed: $e');
    }
  }
  
  static Future<PandocResult> importDocument({
    required String inputPath,
    required PandocImportFormat format,
    required PandocAssetManager assetManager,
    Map<String, String>? customOptions,
  }) async {
    final pandocPath = assetManager.pandocPath;
    if (pandocPath == null) {
      return PandocResult.failure('Pandoc not available');
    }
    
    try {
      // Build pandoc command
      final args = [
        pandocPath,
        '-f', format.extension,
        '-t', 'markdown',
        inputPath,
      ];
      
      // Add custom options
      if (customOptions != null) {
        for (final entry in customOptions.entries) {
          if (entry.value.isNotEmpty) {
            args.addAll(['--${entry.key}', entry.value]);
          } else {
            args.add('--${entry.key}');
          }
        }
      }
      
      // Execute pandoc
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
  
  static Future<String?> _detectPdfEngine(PandocAssetManager assetManager) async {
    // Always return null to use Pandoc's default PDF engine
    // This avoids the need to install external PDF engines
    debugPrint('PandocService: Using Pandoc default PDF engine');
    return null;
  }
  
  static String getFileExtension(String format) {
    return format;
  }
}

/// Pandoc Export Dialog
class PandocExportDialog extends StatefulWidget {
  const PandocExportDialog({
    Key? key,
    required this.markdownContent,
    required this.assetManager,
    this.initialFormat = PandocExportFormat.pdf,
  }) : super(key: key);

  final String markdownContent;
  final PandocAssetManager assetManager;
  final PandocExportFormat initialFormat;

  @override
  State<PandocExportDialog> createState() => _PandocExportDialogState();
}

class _PandocExportDialogState extends State<PandocExportDialog> {
  late PandocExportFormat _selectedFormat;
  String? _outputPath;
  bool _isExporting = false;
  bool _pandocAvailable = false;
  String? _pandocVersion;
  Map<String, String> _customOptions = {};

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
    _checkPandocAvailability();
  }

  Future<void> _checkPandocAvailability() async {
    if (!PandocService.isPlatformSupported()) {
      setState(() {
        _pandocAvailable = false;
      });
      return;
    }

    final available = await PandocService.isPandocInstalled(widget.assetManager);
    final version = await PandocService.getPandocVersion(widget.assetManager);

    setState(() {
      _pandocAvailable = available;
      _pandocVersion = version;
    });
  }

  Future<void> _selectOutputPath() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Select output file',
      fileName: 'document.${PandocService.getFileExtension(_selectedFormat.extension)}',
      type: FileType.custom,
      allowedExtensions: [PandocService.getFileExtension(_selectedFormat.extension)],
    );

    if (result != null) {
      setState(() {
        _outputPath = result;
      });
    }
  }

  Future<void> _exportDocument() async {
    if (_outputPath == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final result = await PandocService.exportDocument(
        markdownContent: widget.markdownContent,
        format: _selectedFormat,
        outputPath: _outputPath!,
        assetManager: widget.assetManager,
        customOptions: _customOptions,
      );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export successful: ${result.filePath}'),
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
              _selectedFormat == PandocExportFormat.pdf) {
            // Show simplified dialog for PDF errors
            _showSimplePdfErrorDialog(result.error!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export failed: ${result.error}'),
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
            content: Text('Export failed: $e'),
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

  @override
  Widget build(BuildContext context) {
    if (!PandocService.isPlatformSupported()) {
      return AlertDialog(
        title: const Text('Platform Not Supported'),
        content: const Text('Pandoc export is only available on desktop platforms (Windows, macOS, Linux).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    if (!_pandocAvailable) {
      return AlertDialog(
        title: const Text('Pandoc Not Available'),
        content: const Text('Pandoc is not installed or not available. Please install Pandoc to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Export Document'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pandocVersion != null)
              Text('Pandoc version: $_pandocVersion', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            
            // Format selection
            Text('Export Format:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<PandocExportFormat>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: PandocExportFormat.values.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format.displayName),
                );
              }).toList(),
              onChanged: (format) {
                if (format != null) {
                  setState(() {
                    _selectedFormat = format;
                    _outputPath = null; // Reset output path when format changes
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Output path
            Text('Output File:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Select output file...',
                    ),
                    controller: TextEditingController(text: _outputPath ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectOutputPath,
                  child: const Icon(PhosphorIcons.folder),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _outputPath != null && !_isExporting ? _exportDocument : null,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  void _showSimplePdfErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('PDF Export Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PDF export failed. Pandoc cannot find a suitable PDF engine.'),
            const SizedBox(height: 16),
            const Text('Suggested solutions:'),
            const Text('1. Export as HTML format (recommended)'),
            const Text('2. Manually install LaTeX or wkhtmltopdf'),
            const SizedBox(height: 16),
            const Text('Would you like to export as HTML instead?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Change format to HTML and retry
              setState(() {
                _selectedFormat = PandocExportFormat.html;
              });
              // Auto-retry with HTML format
              _exportDocument();
            },
            child: const Text('Export as HTML'),
          ),
        ],
      ),
    );
  }
}

/// Pandoc Import Dialog
class PandocImportDialog extends StatefulWidget {
  const PandocImportDialog({
    Key? key,
    required this.assetManager,
    this.onImportComplete,
  }) : super(key: key);

  final PandocAssetManager assetManager;
  final Function(String markdownContent)? onImportComplete;

  @override
  State<PandocImportDialog> createState() => _PandocImportDialogState();
}

class _PandocImportDialogState extends State<PandocImportDialog> {
  PandocImportFormat _selectedFormat = PandocImportFormat.docx;
  String? _inputPath;
  bool _isImporting = false;
  bool _pandocAvailable = false;
  String? _pandocVersion;
  Map<String, String> _customOptions = {};

  @override
  void initState() {
    super.initState();
    _checkPandocAvailability();
  }

  Future<void> _checkPandocAvailability() async {
    if (!PandocService.isPlatformSupported()) {
      setState(() {
        _pandocAvailable = false;
      });
      return;
    }

    final available = await PandocService.isPandocInstalled(widget.assetManager);
    final version = await PandocService.getPandocVersion(widget.assetManager);

    setState(() {
      _pandocAvailable = available;
      _pandocVersion = version;
    });
  }

  Future<void> _selectInputFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [PandocService.getFileExtension(_selectedFormat.extension)],
      dialogTitle: 'Select file to import',
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _inputPath = result.files.first.path;
      });
    }
  }

  Future<void> _importDocument() async {
    if (_inputPath == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await PandocService.importDocument(
        inputPath: _inputPath!,
        format: _selectedFormat,
        assetManager: widget.assetManager,
        customOptions: _customOptions,
      );

      if (result.success && result.output != null) {
        widget.onImportComplete?.call(result.output!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Import successful'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
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

  @override
  Widget build(BuildContext context) {
    if (!PandocService.isPlatformSupported()) {
      return AlertDialog(
        title: const Text('Platform Not Supported'),
        content: const Text('Pandoc import is only available on desktop platforms (Windows, macOS, Linux).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    if (!_pandocAvailable) {
      return AlertDialog(
        title: const Text('Pandoc Not Available'),
        content: const Text('Pandoc is not installed or not available. Please install Pandoc to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Import Document'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pandocVersion != null)
              Text('Pandoc version: $_pandocVersion', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            
            // Format selection
            Text('Import Format:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<PandocImportFormat>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: PandocImportFormat.values.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format.displayName),
                );
              }).toList(),
              onChanged: (format) {
                if (format != null) {
                  setState(() {
                    _selectedFormat = format;
                    _inputPath = null; // Reset input path when format changes
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Input file
            Text('Input File:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Select input file...',
                    ),
                    controller: TextEditingController(text: _inputPath ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectInputFile,
                  child: const Icon(PhosphorIcons.folder),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _inputPath != null && !_isImporting ? _importDocument : null,
          child: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }
}

/// Pandoc Configuration Widget
class PandocConfigWidget extends StatefulWidget {
  const PandocConfigWidget({
    Key? key,
    required this.config,
    required this.onConfigChanged,
  }) : super(key: key);

  final Map<String, dynamic> config;
  final Function(Map<String, dynamic>) onConfigChanged;

  @override
  State<PandocConfigWidget> createState() => _PandocConfigWidgetState();
}

class _PandocConfigWidgetState extends State<PandocConfigWidget> {
  late Map<String, dynamic> _config;

  @override
  void initState() {
    super.initState();
    _config = Map<String, dynamic>.from(widget.config);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pandoc Configuration', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        
        // Default export format
        Text('Default Export Format:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _config['defaultExportFormat'] ?? 'pdf',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: PandocExportFormat.values.map((format) {
            return DropdownMenuItem(
              value: format.extension,
              child: Text(format.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _config['defaultExportFormat'] = value;
              });
              widget.onConfigChanged(_config);
            }
          },
        ),
        const SizedBox(height: 16),
        
        // Enable bundled Pandoc
        CheckboxListTile(
          title: const Text('Use Bundled Pandoc'),
          subtitle: const Text('Use the bundled Pandoc instead of system installation'),
          value: _config['enableBundledPandoc'] ?? true,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _config['enableBundledPandoc'] = value;
              });
              widget.onConfigChanged(_config);
            }
          },
        ),
      ],
    );
  }
} 