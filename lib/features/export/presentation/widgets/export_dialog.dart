import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../types/document.dart';
import '../../domain/entities/export_settings.dart';
import '../../domain/services/export_service.dart';
import '../../../document/presentation/providers/document_providers.dart';

/// Export dialog
class ExportDialog extends ConsumerStatefulWidget {
  final Document document;
  final ExportFormat? initialFormat;

  const ExportDialog({
    super.key,
    required this.document,
    this.initialFormat,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  late ExportFormat _selectedFormat;
  late TextEditingController _fileNameController;
  bool _isExporting = false;
  ExportProgress? _currentProgress;

  // Export settings
  PdfExportSettings _pdfSettings = const PdfExportSettings();
  HtmlExportSettings _htmlSettings = const HtmlExportSettings();
  ImageExportSettings _imageSettings = const ImageExportSettings();

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat ?? ExportFormat.html;
    _fileNameController = TextEditingController(
      text: _getSuggestedFileName(),
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _buildHeader(theme),
            
            const SizedBox(height: 24),
            
            // Main content
            Expanded(
              child: _isExporting
                  ? _buildExportProgress(theme)
                  : _buildExportSettings(theme),
            ),
            
            const SizedBox(height: 24),
            
            // Bottom buttons
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  /// Build header
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          PhosphorIconsRegular.export,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Document',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Export "${widget.document.title}" to other formats',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: Icon(PhosphorIconsRegular.x),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
      ],
    );
  }

  /// Build export settings
  Widget _buildExportSettings(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format selection
          _buildFormatSelection(theme),
          
          const SizedBox(height: 24),
          
          // Filename settings
          _buildFileNameSection(theme),
          
          const SizedBox(height: 24),
          
          // Format-specific settings
          _buildFormatSpecificSettings(theme),
        ],
      ),
    );
  }

  /// Build format selection
  Widget _buildFormatSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: ExportFormat.values.map((format) {
            final isSelected = _selectedFormat == format;
            final isSupported = ExportServiceImpl().isFormatSupported(format);
            
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFormatIcon(format),
                    size: 16,
                    color: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(format.displayName),
                  if (!isSupported) ...[
                    const SizedBox(width: 4),
                    Icon(
                      PhosphorIconsRegular.warning,
                      size: 12,
                      color: theme.colorScheme.error,
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: isSupported ? (selected) {
                if (selected) {
                  setState(() {
                    _selectedFormat = format;
                    _fileNameController.text = _getSuggestedFileName();
                  });
                }
              } : null,
              tooltip: isSupported ? format.description : 'This format is not supported yet',
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build filename section
  Widget _buildFileNameSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File Name',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: _fileNameController,
          decoration: InputDecoration(
            hintText: 'Enter file name...',
            suffixText: '.${_selectedFormat.extension}',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// Build format-specific settings
  Widget _buildFormatSpecificSettings(ThemeData theme) {
    switch (_selectedFormat) {
      case ExportFormat.html:
        return _buildHtmlSettings(theme);
      case ExportFormat.pdf:
        return _buildPdfSettings(theme);
      case ExportFormat.png:
      case ExportFormat.jpeg:
        return _buildImageSettings(theme);
      case ExportFormat.docx:
        return _buildDocxSettings(theme);
    }
  }

  /// Build HTML settings
  Widget _buildHtmlSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HTML Export Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Theme selection
                Row(
                  children: [
                    Expanded(
                      child: Text('Theme'),
                    ),
                    DropdownButton<String>(
                      value: _htmlSettings.theme,
                      items: ['GitHub', 'Typora', 'Custom'].map((theme) => 
                        DropdownMenuItem(value: theme, child: Text(theme)),
                      ).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _htmlSettings = _htmlSettings.copyWith(theme: value);
                          });
                        }
                      },
                    ),
                  ],
                ),
                
                const Divider(),
                
                // Feature toggles
                _buildSettingsSwitch(
                  'Include Table of Contents',
                  _htmlSettings.includeTableOfContents,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(includeTableOfContents: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  'Enable Syntax Highlighting',
                  _htmlSettings.enableSyntaxHighlighting,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(enableSyntaxHighlighting: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  'Enable Math Formulas',
                  _htmlSettings.enableMathJax,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(enableMathJax: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  'Enable Mermaid Charts',
                  _htmlSettings.enableMermaid,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(enableMermaid: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  'Responsive Design',
                  _htmlSettings.responsiveDesign,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(responsiveDesign: value);
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build PDF settings
  Widget _buildPdfSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PDF Export Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Page size
                Row(
                  children: [
                    Expanded(child: Text('Page Size')),
                    DropdownButton<String>(
                      value: _pdfSettings.pageSize,
                      items: ['A4', 'A3', 'Letter', 'Legal'].map((size) => 
                        DropdownMenuItem(value: size, child: Text(size)),
                      ).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _pdfSettings = _pdfSettings.copyWith(pageSize: value);
                          });
                        }
                      },
                    ),
                  ],
                ),
                
                const Divider(),
                
                // Font size
                Row(
                  children: [
                    Expanded(child: Text('Font Size')),
                    SizedBox(
                      width: 100,
                      child: Slider(
                        value: _pdfSettings.fontSize,
                        min: 8,
                        max: 20,
                        divisions: 12,
                        label: '${_pdfSettings.fontSize.toInt()}pt',
                        onChanged: (value) {
                          setState(() {
                            _pdfSettings = _pdfSettings.copyWith(fontSize: value);
                          });
                        },
                      ),
                    ),
                    Text('${_pdfSettings.fontSize.toInt()}pt'),
                  ],
                ),
                
                const Divider(),
                
                // Feature toggles
                _buildSettingsSwitch(
                  'Include Table of Contents',
                  _pdfSettings.includeTableOfContents,
                  (value) => setState(() {
                    _pdfSettings = _pdfSettings.copyWith(includeTableOfContents: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  'Include Page Numbers',
                  _pdfSettings.includePageNumbers,
                  (value) => setState(() {
                    _pdfSettings = _pdfSettings.copyWith(includePageNumbers: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  'Enable Syntax Highlighting',
                  _pdfSettings.enableSyntaxHighlighting,
                  (value) => setState(() {
                    _pdfSettings = _pdfSettings.copyWith(enableSyntaxHighlighting: value);
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build image settings
  Widget _buildImageSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image Export Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Image export feature is under development',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  PhosphorIconsRegular.hammer,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build DOCX settings
  Widget _buildDocxSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word Document Export Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Word document export feature is under development',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  PhosphorIconsRegular.hammer,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build export progress
  Widget _buildExportProgress(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: _currentProgress?.progress,
              strokeWidth: 6,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            _currentProgress?.status ?? 'Preparing export...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          if (_currentProgress?.currentStep != null) ...[
            const SizedBox(height: 8),
            Text(
              _currentProgress!.currentStep!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          
          if (_currentProgress?.progress != null) ...[
            const SizedBox(height: 16),
            Text(
              '${(_currentProgress!.progress * 100).toInt()}%',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          
          if (_currentProgress?.hasError == true) ...[
            const SizedBox(height: 16),
            Icon(
              PhosphorIconsRegular.warning,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              _currentProgress?.errorMessage ?? 'An error occurred during export',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Build bottom buttons
  Widget _buildFooter(ThemeData theme) {
    if (_isExporting) {
      return Row(
        children: [
          const Spacer(),
          if (_currentProgress?.hasError == true)
            TextButton(
              onPressed: () {
                setState(() {
                  _isExporting = false;
                  _currentProgress = null;
                });
              },
              child: const Text('Retry'),
            ),
          if (_currentProgress?.isCompleted == true)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
        ],
      );
    }

    return Row(
      children: [
        // Export preview
        TextButton.icon(
          icon: Icon(PhosphorIconsRegular.eye),
          label: const Text('Preview'),
          onPressed: () => _showPreview(),
        ),
        
        const Spacer(),
        
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        
        const SizedBox(width: 12),
        
        // Export button
        FilledButton.icon(
          icon: Icon(PhosphorIconsRegular.export),
          label: const Text('Start Export'),
          onPressed: _canExport() ? _startExport : null,
        ),
      ],
    );
  }

  /// Build settings switch
  Widget _buildSettingsSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Get format icon
  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.html:
        return PhosphorIconsRegular.globe;
      case ExportFormat.pdf:
        return PhosphorIconsRegular.filePdf;
      case ExportFormat.png:
      case ExportFormat.jpeg:
        return PhosphorIconsRegular.image;
      case ExportFormat.docx:
        return PhosphorIconsRegular.fileDoc;
    }
  }

  /// Get suggested filename
  String _getSuggestedFileName() {
    final baseName = widget.document.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return baseName;
  }

  /// Whether export is possible
  bool _canExport() {
    return _fileNameController.text.trim().isNotEmpty &&
           ExportServiceImpl().isFormatSupported(_selectedFormat);
  }

  /// Start export
  void _startExport() async {
    setState(() {
      _isExporting = true;
      _currentProgress = const ExportProgress(
        progress: 0.0,
        status: 'Initializing export...',
      );
    });

    try {
      // Use FileService for actual file export
      final fileService = ref.read(fileServiceProvider);
      
      setState(() {
        _currentProgress = const ExportProgress(
          progress: 0.3,
          status: 'Selecting save location...',
        );
      });

      final settings = ExportSettings(
        format: _selectedFormat,
        outputPath: '', // Will be handled by FileService
        fileName: _fileNameController.text.trim(),
        pdfSettings: _pdfSettings,
        htmlSettings: _htmlSettings,
        imageSettings: _imageSettings,
      );

      setState(() {
        _currentProgress = const ExportProgress(
          progress: 0.6,
          status: 'Exporting...',
        );
      });

      // Use FileService to export document
      await fileService.exportDocument(widget.document, settings);

      setState(() {
        _currentProgress = const ExportProgress(
          progress: 1.0,
          status: 'Export completed!',
          isCompleted: true,
        );
      });

      // Show success message with location info
      if (mounted) {
        String message = 'Document successfully exported as ${_selectedFormat.displayName}';
        
        // Add location info for web PDF exports
        if (_selectedFormat == ExportFormat.pdf && kIsWeb) {
          message += '\nFile saved to browser\'s default download folder';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 5), // Extended display time
            action: _selectedFormat == ExportFormat.pdf && kIsWeb
                ? SnackBarAction(
                    label: 'View Downloads',
                    textColor: Colors.white,
                    onPressed: () {
                      // Show more detailed explanation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('PDF File Downloaded'),
                          content: const Text(
                            'PDF file has been saved to your browser\'s default download folder.\n\n'
            'Common locations:\n'
            '• Windows: C:\\Users\\username\\Downloads\\\n'
            '• macOS: /Users/username/Downloads/\n'
            '• Linux: /home/username/Downloads/\n\n'
            'You can also press Ctrl+J (Windows/Linux) or Cmd+Shift+J (macOS) to view browser download history.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _currentProgress = ExportProgress(
          progress: 0.0,
          status: 'Export failed',
          hasError: true,
          errorMessage: e.toString(),
        );
      });
    }
  }

  /// Show preview
  void _showPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Preview'),
        content: const Text('Preview feature coming soon'),
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

/// Show export dialog
Future<void> showExportDialog(
  BuildContext context, 
  Document document, {
  ExportFormat? initialFormat,
}) {
  return showDialog(
    context: context,
    builder: (context) => ExportDialog(
      document: document,
      initialFormat: initialFormat,
    ),
  );
}