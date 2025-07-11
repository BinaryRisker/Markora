import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:path/path.dart' as path;

import '../../../../types/document.dart';
import '../providers/document_providers.dart';
import '../../../export/domain/entities/export_settings.dart';

/// File save format
enum SaveFormat {
  markdown('Markdown', '.md', 'Markdown File'),
  html('HTML', '.html', 'HTML File'),
  pdf('PDF', '.pdf', 'PDF File'),
  docx('Word', '.docx', 'Word Document'),
  txt('Plain Text', '.txt', 'Plain Text File');

  const SaveFormat(this.displayName, this.extension, this.description);
  
  final String displayName;
  final String extension;
  final String description;
  
  /// Convert to ExportFormat (if applicable)
  ExportFormat? toExportFormat() {
    switch (this) {
      case SaveFormat.html:
        return ExportFormat.html;
      case SaveFormat.pdf:
        return ExportFormat.pdf;
      case SaveFormat.docx:
        return ExportFormat.docx;
      case SaveFormat.markdown:
      case SaveFormat.txt:
        return null; // These formats are saved directly, no export needed
    }
  }
}

/// File save result
class SaveResult {
  const SaveResult({
    required this.filePath,
    required this.format,
    required this.fileName,
  });

  final String filePath;
  final SaveFormat format;
  final String fileName;
}

/// File save as dialog
class SaveAsDialog extends ConsumerStatefulWidget {
  const SaveAsDialog({
    super.key,
    required this.document,
    this.initialPath,
    this.initialFormat = SaveFormat.markdown,
  });

  final Document document;
  final String? initialPath;
  final SaveFormat initialFormat;

  @override
  ConsumerState<SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends ConsumerState<SaveAsDialog> {
  late TextEditingController _fileNameController;
  late TextEditingController _pathController;
  late SaveFormat _selectedFormat;
  
  String? _selectedDirectory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
    
    // Initialize filename (remove extension)
    final baseName = path.basenameWithoutExtension(widget.document.title);
    _fileNameController = TextEditingController(text: baseName);
    
    // Initialize path
    _selectedDirectory = widget.initialPath ?? _getDefaultSaveDirectory();
    _pathController = TextEditingController(text: _selectedDirectory);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  /// Get default save directory
  String _getDefaultSaveDirectory() {
    try {
      // Try to get user documents directory
      final homeDir = Platform.environment['USERPROFILE'] ?? 
                     Platform.environment['HOME'] ?? 
                     Directory.current.path;
      
      final documentsDir = path.join(homeDir, 'Documents');
      if (Directory(documentsDir).existsSync()) {
        return documentsDir;
      }
      
      return homeDir;
    } catch (e) {
      return Directory.current.path;
    }
  }

  /// Select save directory
  Future<void> _selectDirectory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Should use file picker here, temporarily use simple directory input
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _DirectoryPickerDialog(
          initialPath: _selectedDirectory ?? '',
        ),
      );

      if (result != null) {
        setState(() {
          _selectedDirectory = result;
          _pathController.text = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select directory: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Validate input
  String? _validateInput() {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      return 'Please enter filename';
    }

    final directory = _selectedDirectory;
    if (directory == null || directory.isEmpty) {
      return 'Please select save directory';
    }

    if (!Directory(directory).existsSync()) {
      return 'Selected directory does not exist';
    }

    // Check if filename contains illegal characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) {
      return 'Filename contains illegal characters';
    }

    return null;
  }

  /// Save file
  void _saveFile() async {
    final error = _validateInput();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fileName = _fileNameController.text.trim();
      final fullFileName = '$fileName${_selectedFormat.extension}';
      final filePath = path.join(_selectedDirectory!, fullFileName);

      // Choose save method based on format
      final fileService = ref.read(fileServiceProvider);
      final exportFormat = _selectedFormat.toExportFormat();
      
      if (exportFormat != null) {
        // Formats that need export (HTML, PDF, DOCX)
        final settings = ExportSettings(
          format: exportFormat,
          outputPath: '',
          fileName: fileName,
        );
        await fileService.exportDocument(widget.document, settings, targetPath: filePath);
      } else {
        // Formats that save directly (Markdown, plain text)
        await fileService.saveDocumentToFile(widget.document, filePath);
      }

      final result = SaveResult(
        filePath: filePath,
        format: _selectedFormat,
        fileName: fullFileName,
      );

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.floppyDisk,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Save As'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filename input
            Text(
              'Filename',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                hintText: 'Enter filename',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Save format selection
            Text(
              'Save Format',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SaveFormat>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: SaveFormat.values.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Row(
                    children: [
                      Text(format.displayName),
                      const SizedBox(width: 8),
                      Text(
                        format.extension,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (format) {
                if (format != null) {
                  setState(() {
                    _selectedFormat = format;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Save path selection
            Text(
              'Save Location',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      hintText: 'Select save location',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _selectDirectory,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : PhosphorIcon(
                          PhosphorIconsRegular.folder,
                          size: 16,
                        ),
                  label: const Text('Browse'),
                ),
              ],
            ),
            
            // Preview full path
            if (_selectedDirectory != null && _fileNameController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Path:',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      path.join(_selectedDirectory!, 
                                '${_fileNameController.text}${_selectedFormat.extension}'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveFile,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

/// Simple directory selection dialog
class _DirectoryPickerDialog extends StatefulWidget {
  const _DirectoryPickerDialog({
    required this.initialPath,
  });

  final String initialPath;

  @override
  State<_DirectoryPickerDialog> createState() => _DirectoryPickerDialogState();
}

class _DirectoryPickerDialogState extends State<_DirectoryPickerDialog> {
  late TextEditingController _pathController;
  List<String> _commonPaths = [];

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.initialPath);
    _initCommonPaths();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _initCommonPaths() {
    try {
      final homeDir = Platform.environment['USERPROFILE'] ?? 
                     Platform.environment['HOME'] ?? 
                     Directory.current.path;
      
      _commonPaths = [
        homeDir,
        path.join(homeDir, 'Documents'),
        path.join(homeDir, 'Desktop'),
        path.join(homeDir, 'Downloads'),
        Directory.current.path,
      ].where((p) => Directory(p).existsSync()).toList();
    } catch (e) {
      _commonPaths = [Directory.current.path];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Select Save Directory'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Path input
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'Directory Path',
                hintText: 'Enter or select directory path',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Common paths
            Text(
              'Common Locations',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _commonPaths.length,
                itemBuilder: (context, index) {
                  final pathStr = _commonPaths[index];
                  final dirName = path.basename(pathStr);
                  
                  return ListTile(
                    leading: PhosphorIcon(
                      PhosphorIconsRegular.folder,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(dirName.isEmpty ? pathStr : dirName),
                    subtitle: Text(
                      pathStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    onTap: () {
                      _pathController.text = pathStr;
                    },
                  );
                },
              ),
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
          onPressed: () {
            final path = _pathController.text.trim();
            if (path.isNotEmpty && Directory(path).existsSync()) {
              Navigator.of(context).pop(path);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please select a valid directory path'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}