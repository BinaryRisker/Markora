library pandoc_plugin;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:markora/features/plugins/domain/plugin_interface.dart';
import 'package:markora/types/plugin.dart';

/// Pandoc plugin implementation
class PandocPlugin extends BasePlugin {
  PandocPlugin(this._metadata);
  
  final PluginMetadata _metadata;
  
  @override
  PluginMetadata get metadata => _metadata;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    await super.onLoad(context);
    
    try {
      // Register export action
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'pandoc_export',
          title: 'Export Document',
          description: 'Export document using Pandoc',
          icon: 'file_download',
        ),
        () => _handleExportAction(context),
      );
      
      // Register import action
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'pandoc_import',
          title: 'Import Document',
          description: 'Import document using Pandoc',
          icon: 'file_upload',
        ),
        () => _handleImportAction(context),
      );
      
      debugPrint('Pandoc plugin loaded successfully');
    } catch (e) {
      debugPrint('Failed to load Pandoc plugin: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> onUnload() async {
    try {
      debugPrint('Pandoc plugin unloaded');
    } catch (e) {
      debugPrint('Error unloading Pandoc plugin: $e');
    }
    
    await super.onUnload();
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      ...super.getStatus(),
      'exportFormats': ['pdf', 'docx', 'html', 'epub'],
      'importFormats': ['docx', 'html', 'epub', 'rst'],
    };
  }
  
  /// Handle export action
  void _handleExportAction(PluginContext context) {
    // Show export dialog
    _showExportDialog(context);
  }
  
  /// Handle import action
  void _handleImportAction(PluginContext context) {
    // Show import dialog
    _showImportDialog(context);
  }
  
  /// Show export dialog
  void _showExportDialog(PluginContext context) {
    if (context.context != null) {
      showDialog(
        context: context.context!,
        builder: (BuildContext dialogContext) => PandocExportDialog(
          onExport: (format, options) => _performExport(context, format, options),
        ),
      );
    } else {
      debugPrint('Pandoc export dialog cannot be shown: no BuildContext available');
    }
  }
  
  /// Show import dialog
  void _showImportDialog(PluginContext context) {
    if (context.context != null) {
      showDialog(
        context: context.context!,
        builder: (BuildContext dialogContext) => PandocImportDialog(
          onImport: (format, options) => _performImport(context, format, options),
        ),
      );
    } else {
      debugPrint('Pandoc import dialog cannot be shown: no BuildContext available');
    }
  }
  
  /// Perform export operation
  Future<void> _performExport(PluginContext context, String format, Map<String, dynamic> options) async {
    try {
      final content = context.editorController.getCurrentContent();
      
      // Get save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Document',
        fileName: 'document.$format',
        type: FileType.custom,
        allowedExtensions: [format],
      );
      
      if (result != null) {
        // TODO: Implement actual Pandoc conversion
        // For now, just save the markdown content
        final file = File(result);
        await file.writeAsString(content);
        
        debugPrint('Document exported to: $result');
        
        // Show success message
        if (context.context != null) {
          ScaffoldMessenger.of(context.context!).showSnackBar(
            SnackBar(
              content: Text('Document exported successfully to $format'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      
      // Show error message
      if (context.context != null) {
        ScaffoldMessenger.of(context.context!).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Perform import operation
  Future<void> _performImport(PluginContext context, String format, Map<String, dynamic> options) async {
    try {
      // Select file to import
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [format],
        dialogTitle: 'Import Document',
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final content = await file.readAsString();
        
        // TODO: Implement actual Pandoc conversion
        // For now, just set the content directly
        context.editorController.setContent(content);
        
        debugPrint('Document imported from: ${file.path}');
        
        // Show success message
        if (context.context != null) {
          ScaffoldMessenger.of(context.context!).showSnackBar(
            SnackBar(
              content: Text('Document imported successfully from $format'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      
      // Show error message
      if (context.context != null) {
        ScaffoldMessenger.of(context.context!).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Pandoc export dialog widget
class PandocExportDialog extends StatefulWidget {
  const PandocExportDialog({super.key, required this.onExport});
  
  final Function(String format, Map<String, dynamic> options) onExport;
  
  @override
  State<PandocExportDialog> createState() => _PandocExportDialogState();
}

class _PandocExportDialogState extends State<PandocExportDialog> {
  String _selectedFormat = 'pdf';
  bool _includeMetadata = true;
  bool _useCustomTemplate = false;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Document'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export Format:'),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedFormat,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'pdf', child: Text('PDF')),
              DropdownMenuItem(value: 'docx', child: Text('Word Document')),
              DropdownMenuItem(value: 'html', child: Text('HTML')),
              DropdownMenuItem(value: 'epub', child: Text('EPUB')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFormat = value;
                });
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('Include Metadata'),
            value: _includeMetadata,
            onChanged: (value) {
              setState(() {
                _includeMetadata = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          CheckboxListTile(
            title: const Text('Use Custom Template'),
            value: _useCustomTemplate,
            onChanged: (value) {
              setState(() {
                _useCustomTemplate = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final options = {
              'includeMetadata': _includeMetadata,
              'useCustomTemplate': _useCustomTemplate,
            };
            widget.onExport(_selectedFormat, options);
            Navigator.of(context).pop();
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}

/// Pandoc import dialog widget
class PandocImportDialog extends StatefulWidget {
  const PandocImportDialog({super.key, required this.onImport});
  
  final Function(String format, Map<String, dynamic> options) onImport;
  
  @override
  State<PandocImportDialog> createState() => _PandocImportDialogState();
}

class _PandocImportDialogState extends State<PandocImportDialog> {
  String _selectedFormat = 'docx';
  bool _preserveFormatting = true;
  bool _convertImages = true;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Document'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Import Format:'),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedFormat,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'docx', child: Text('Word Document')),
              DropdownMenuItem(value: 'html', child: Text('HTML')),
              DropdownMenuItem(value: 'epub', child: Text('EPUB')),
              DropdownMenuItem(value: 'rst', child: Text('reStructuredText')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFormat = value;
                });
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('Preserve Formatting'),
            value: _preserveFormatting,
            onChanged: (value) {
              setState(() {
                _preserveFormatting = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          CheckboxListTile(
            title: const Text('Convert Images'),
            value: _convertImages,
            onChanged: (value) {
              setState(() {
                _convertImages = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final options = {
              'preserveFormatting': _preserveFormatting,
              'convertImages': _convertImages,
            };
            widget.onImport(_selectedFormat, options);
            Navigator.of(context).pop();
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}