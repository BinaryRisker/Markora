import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/services/pandoc_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Pandoc导出对话框
class PandocExportDialog extends StatefulWidget {
  const PandocExportDialog({
    Key? key,
    required this.markdownContent,
    this.initialFormat = PandocExportFormat.pdf,
  }) : super(key: key);

  final String markdownContent;
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

    final available = await PandocService.isPandocInstalled();
    final version = await PandocService.getPandocVersion();

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
      final options = {
        ...PandocService.getDefaultExportOptions(_selectedFormat),
        ..._customOptions,
      };

      final result = await PandocService.exportFromMarkdown(
        markdownContent: widget.markdownContent,
        format: _selectedFormat,
        outputPath: _outputPath!,
        options: options,
      );

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.exportSuccessful}: ${result.filePath}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.exportFailed}: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.exportFailed}: $e'),
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
              AppLocalizations.of(context)!.platformNotSupported,
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
                AppLocalizations.of(context)!.pandocNotInstalled,
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
            AppLocalizations.of(context)!.pandocRequired,
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
          AppLocalizations.of(context)!.exportFormat,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PandocExportFormat>(
          value: _selectedFormat,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: PandocService.getSupportedExportFormats().map((format) {
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
      ],
    );
  }

  Widget _buildOutputPathSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.outputPath,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _outputPath ?? ''),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: AppLocalizations.of(context)!.selectOutputFile,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _selectOutputPath,
              icon: const Icon(PhosphorIconsRegular.folder),
              label: Text(AppLocalizations.of(context)!.browse),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.exportWithPandoc),
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
                          '${AppLocalizations.of(context)!.pandocAvailable}: $_pandocVersion',
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
                
                // 输出路径选择
                _buildOutputPathSection(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        if (_pandocAvailable)
          ElevatedButton(
            onPressed: _outputPath != null && !_isExporting ? _exportDocument : null,
            child: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context)!.export),
          ),
      ],
    );
  }
} 