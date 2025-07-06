import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../types/document.dart';
import '../../domain/entities/export_settings.dart';
import '../../domain/services/export_service.dart';
import '../../../document/presentation/providers/document_providers.dart';

/// 导出对话框
class ExportDialog extends ConsumerStatefulWidget {
  final Document document;

  const ExportDialog({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.html;
  late TextEditingController _fileNameController;
  bool _isExporting = false;
  ExportProgress? _currentProgress;

  // 导出设置
  PdfExportSettings _pdfSettings = const PdfExportSettings();
  HtmlExportSettings _htmlSettings = const HtmlExportSettings();
  ImageExportSettings _imageSettings = const ImageExportSettings();

  @override
  void initState() {
    super.initState();
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
            // 标题
            _buildHeader(theme),
            
            const SizedBox(height: 24),
            
            // 主要内容
            Expanded(
              child: _isExporting
                  ? _buildExportProgress(theme)
                  : _buildExportSettings(theme),
            ),
            
            const SizedBox(height: 24),
            
            // 底部按钮
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  /// 构建头部
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
              '导出文档',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '将 "${widget.document.title}" 导出为其他格式',
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
          tooltip: '关闭',
        ),
      ],
    );
  }

  /// 构建导出设置
  Widget _buildExportSettings(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 格式选择
          _buildFormatSelection(theme),
          
          const SizedBox(height: 24),
          
          // 文件名设置
          _buildFileNameSection(theme),
          
          const SizedBox(height: 24),
          
          // 格式特定设置
          _buildFormatSpecificSettings(theme),
        ],
      ),
    );
  }

  /// 构建格式选择
  Widget _buildFormatSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导出格式',
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
              tooltip: isSupported ? format.description : '此格式暂未支持',
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建文件名部分
  Widget _buildFileNameSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '文件名',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: _fileNameController,
          decoration: InputDecoration(
            hintText: '输入文件名...',
            suffixText: '.${_selectedFormat.extension}',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建格式特定设置
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

  /// 构建HTML设置
  Widget _buildHtmlSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HTML导出设置',
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
                // 主题选择
                Row(
                  children: [
                    Expanded(
                      child: Text('主题'),
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
                
                // 功能开关
                _buildSettingsSwitch(
                  '包含目录',
                  _htmlSettings.includeTableOfContents,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(includeTableOfContents: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  '启用语法高亮',
                  _htmlSettings.enableSyntaxHighlighting,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(enableSyntaxHighlighting: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  '启用数学公式',
                  _htmlSettings.enableMathJax,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(enableMathJax: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  '启用Mermaid图表',
                  _htmlSettings.enableMermaid,
                  (value) => setState(() {
                    _htmlSettings = _htmlSettings.copyWith(enableMermaid: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  '响应式设计',
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

  /// 构建PDF设置
  Widget _buildPdfSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PDF导出设置',
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
                // 页面大小
                Row(
                  children: [
                    Expanded(child: Text('页面大小')),
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
                
                // 字体大小
                Row(
                  children: [
                    Expanded(child: Text('字体大小')),
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
                
                // 功能开关
                _buildSettingsSwitch(
                  '包含目录',
                  _pdfSettings.includeTableOfContents,
                  (value) => setState(() {
                    _pdfSettings = _pdfSettings.copyWith(includeTableOfContents: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  '包含页码',
                  _pdfSettings.includePageNumbers,
                  (value) => setState(() {
                    _pdfSettings = _pdfSettings.copyWith(includePageNumbers: value);
                  }),
                ),
                
                _buildSettingsSwitch(
                  '启用语法高亮',
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

  /// 构建图像设置
  Widget _buildImageSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '图像导出设置',
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
                  '图像导出功能正在开发中',
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

  /// 构建DOCX设置
  Widget _buildDocxSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word文档导出设置',
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
                  'Word文档导出功能正在开发中',
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

  /// 构建导出进度
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
            _currentProgress?.status ?? '准备导出...',
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
              _currentProgress?.errorMessage ?? '导出过程中出现错误',
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

  /// 构建底部按钮
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
              child: const Text('重试'),
            ),
          if (_currentProgress?.isCompleted == true)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('完成'),
            ),
        ],
      );
    }

    return Row(
      children: [
        // 导出预览
        TextButton.icon(
          icon: Icon(PhosphorIconsRegular.eye),
          label: const Text('预览'),
          onPressed: () => _showPreview(),
        ),
        
        const Spacer(),
        
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        
        const SizedBox(width: 12),
        
        // 导出按钮
        FilledButton.icon(
          icon: Icon(PhosphorIconsRegular.export),
          label: const Text('开始导出'),
          onPressed: _canExport() ? _startExport : null,
        ),
      ],
    );
  }

  /// 构建设置开关
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

  /// 获取格式图标
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

  /// 获取建议的文件名
  String _getSuggestedFileName() {
    final baseName = widget.document.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return baseName;
  }

  /// 是否可以导出
  bool _canExport() {
    return _fileNameController.text.trim().isNotEmpty &&
           ExportServiceImpl().isFormatSupported(_selectedFormat);
  }

  /// 开始导出
  void _startExport() async {
    setState(() {
      _isExporting = true;
      _currentProgress = const ExportProgress(
        progress: 0.0,
        status: '初始化导出...',
      );
    });

    try {
      // 使用FileService进行真正的文件导出
      final fileService = ref.read(fileServiceProvider);
      
      setState(() {
        _currentProgress = const ExportProgress(
          progress: 0.3,
          status: '选择保存位置...',
        );
      });

      final settings = ExportSettings(
        format: _selectedFormat,
        outputPath: '', // 将由FileService处理
        fileName: _fileNameController.text.trim(),
        pdfSettings: _pdfSettings,
        htmlSettings: _htmlSettings,
        imageSettings: _imageSettings,
      );

      setState(() {
        _currentProgress = const ExportProgress(
          progress: 0.6,
          status: '正在导出...',
        );
      });

      // 使用FileService导出文档
      await fileService.exportDocument(widget.document, settings);

      setState(() {
        _currentProgress = const ExportProgress(
          progress: 1.0,
          status: '导出完成！',
          isCompleted: true,
        );
      });

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文档已成功导出为 ${_selectedFormat.displayName}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _currentProgress = ExportProgress(
          progress: 0.0,
          status: '导出失败',
          hasError: true,
          errorMessage: e.toString(),
        );
      });
    }
  }

  /// 显示预览
  void _showPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出预览'),
        content: const Text('预览功能即将推出'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 显示导出对话框
Future<void> showExportDialog(BuildContext context, Document document) {
  return showDialog(
    context: context,
    builder: (context) => ExportDialog(document: document),
  );
}