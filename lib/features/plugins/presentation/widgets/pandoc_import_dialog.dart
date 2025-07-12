import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/services/pandoc_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Pandoc导入对话框
class PandocImportDialog extends StatefulWidget {
  const PandocImportDialog({
    Key? key,
    this.onImportComplete,
  }) : super(key: key);

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

    final available = await PandocService.isPandocInstalled();
    final version = await PandocService.getPandocVersion();

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
      final result = await PandocService.importToMarkdown(
        inputPath: _inputPath!,
        format: _selectedFormat,
        options: _customOptions,
      );

      if (result.success && result.output != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Import successful'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 调用回调函数返回转换后的markdown内容
          widget.onImportComplete?.call(result.output!);
          Navigator.of(context).pop(result.output);
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

  Widget _buildPlatformWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.warning,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This feature is only available on desktop platforms (Windows, macOS, Linux).',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPandocNotAvailable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.x,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pandoc not installed',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pandoc is required for this feature. Please install Pandoc from https://pandoc.org/installing.html',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Format',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PandocImportFormat>(
          value: _selectedFormat,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: PandocService.getSupportedImportFormats().map((format) {
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
      ],
    );
  }

  Widget _buildInputPathSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input File',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _inputPath ?? ''),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select file to import...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _selectInputFile,
              icon: const Icon(PhosphorIconsRegular.folder),
              label: const Text('Browse'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import with Pandoc'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 平台检查
              if (!PandocService.isPlatformSupported()) ...[
                _buildPlatformWarning(),
                const SizedBox(height: 16),
              ],
              
              // Pandoc可用性检查
              if (PandocService.isPlatformSupported() && !_pandocAvailable) ...[
                _buildPandocNotAvailable(),
                const SizedBox(height: 16),
              ],
              
              // Pandoc版本信息
              if (_pandocAvailable && _pandocVersion != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.checkCircle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pandoc available: $_pandocVersion',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 格式选择
              if (_pandocAvailable) ...[
                _buildFormatSelection(),
                const SizedBox(height: 16),
                
                // 输入文件选择
                _buildInputPathSection(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_pandocAvailable)
          ElevatedButton(
            onPressed: _inputPath != null && !_isImporting ? _importDocument : null,
            child: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Import'),
          ),
      ],
    );
  }
} 