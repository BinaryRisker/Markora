import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:process/process.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../features/plugins/domain/plugin_interface.dart';
import '../../../types/plugin.dart';
import '../../../features/editor/domain/services/global_editor_manager.dart';


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
    
    await _assetManager.initialize();
    debugPrint('Pandoc Plugin: Asset manager initialized');
    
    // Example of registering a menu item
    // This is a hypothetical example of how it should work.
    // The actual implementation will depend on the MenuRegistry interface.
    // _context.menuRegistry.registerMenuItem('file/export/pandoc', 'Export with Pandoc...', _showExportDialog);
    
    _isInitialized = true;
    debugPrint('Pandoc Plugin: onLoad completed successfully');
  }

  @override
  Future<void> onUnload() async {
    // _context.menuRegistry.unregisterMenuItem('file/export/pandoc');
    _isInitialized = false;
  }

  @override
  Future<void> onActivate() async {}

  @override
  Future<void> onDeactivate() async {}

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
    
    // Get current content from editor controller
    final content = _context.editorController.getCurrentContent();
    
    if (_context.context == null) {
      debugPrint('Pandoc Plugin: No BuildContext available for export dialog');
      return;
    }
    
    showDialog(
      context: _context.context!,
      builder: (context) {
        return PandocExportDialog(
          markdownContent: content,
          assetManager: _assetManager,
        );
      },
    );
  }

  void _showImportDialog() {
    debugPrint('Pandoc Plugin: _showImportDialog called');
    if (_context.context == null) {
      debugPrint('Pandoc Plugin: No BuildContext available for import dialog');
      return;
    }
    showDialog(
      context: _context.context!,
      builder: (context) => PandocImportDialog(assetManager: _assetManager),
    );
  }
}

class PandocConfigWidget extends StatelessWidget {
  final Map<String, dynamic> config;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;
  const PandocConfigWidget({Key? key, required this.config, required this.onConfigChanged}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Text('Pandoc Config options will be here.');
}

class PandocExportDialog extends StatefulWidget {
  final String markdownContent;
  final PandocAssetManager assetManager;
  const PandocExportDialog({Key? key, required this.markdownContent, required this.assetManager}) : super(key: key);

  @override
  _PandocExportDialogState createState() => _PandocExportDialogState();
}

class _PandocExportDialogState extends State<PandocExportDialog> {
  String _selectedFormat = 'pdf';
  // ... other state variables
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export with Pandoc'),
      content: const Text('Export options will be here.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { /* Export logic */ }, child: const Text('Export')),
      ],
    );
  }
}

class PandocImportDialog extends StatefulWidget {
  final PandocAssetManager assetManager;
  const PandocImportDialog({Key? key, required this.assetManager}) : super(key: key);
  @override
  _PandocImportDialogState createState() => _PandocImportDialogState();
}

class _PandocImportDialogState extends State<PandocImportDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import with Pandoc'),
      content: const Text('Import options will be here.'),
       actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { /* Import logic */ }, child: const Text('Import')),
      ],
    );
  }
}

class PandocAssetManager {
  String _pandocPath = '';
  String _pandocVersion = '';

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      _pandocPath = path.join(appSupportDir.path, 'pandoc', _getPandocExecutableName());
      
      File pandocFile = File(_pandocPath);
      if (!await pandocFile.exists()) {
        // In a real scenario, you'd download or bundle it here.
        // For now, we assume it's placed manually or by a script.
        debugPrint('Pandoc not found at $_pandocPath');
        return;
      }

      await _checkVersion();
    } catch (e) {
      debugPrint('Failed to initialize Pandoc asset manager: $e');
    }
  }

  Future<void> _checkVersion() async {
    if (!isAvailable()) return;
    const processManager = LocalProcessManager();
    final result = await processManager.run([_pandocPath, '--version']);
    if (result.exitCode == 0) {
      _pandocVersion = (result.stdout as String).split('\n').first;
      debugPrint('Pandoc version: $_pandocVersion');
    }
  }
  
  String _getPandocExecutableName() {
    if (Platform.isWindows) return 'pandoc.exe';
    return 'pandoc';
  }

  bool isAvailable() => _pandocPath.isNotEmpty && File(_pandocPath).existsSync();
  String get version => _pandocVersion;

  Future<ProcessResult> runPandoc(List<String> args) async {
    if (!isAvailable()) throw Exception('Pandoc is not available');
    const processManager = LocalProcessManager();
    return await processManager.run([_pandocPath, ...args]);
  }
} 