import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:path/path.dart' as path;

import '../../../../types/document.dart';
import '../providers/document_providers.dart';
import '../../../export/domain/entities/export_settings.dart';

/// 文件保存格式
enum SaveFormat {
  markdown('Markdown', '.md', 'Markdown文件'),
  html('HTML', '.html', 'HTML文件'),
  pdf('PDF', '.pdf', 'PDF文件'),
  docx('Word', '.docx', 'Word文档'),
  txt('纯文本', '.txt', '纯文本文件');

  const SaveFormat(this.displayName, this.extension, this.description);
  
  final String displayName;
  final String extension;
  final String description;
  
  /// 转换为ExportFormat（如果适用）
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
        return null; // 这些格式直接保存，不需要导出
    }
  }
}

/// 文件保存结果
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

/// 文件另存为对话框
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
    
    // 初始化文件名（去掉扩展名）
    final baseName = path.basenameWithoutExtension(widget.document.title);
    _fileNameController = TextEditingController(text: baseName);
    
    // 初始化路径
    _selectedDirectory = widget.initialPath ?? _getDefaultSaveDirectory();
    _pathController = TextEditingController(text: _selectedDirectory);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  /// 获取默认保存目录
  String _getDefaultSaveDirectory() {
    try {
      // 尝试获取用户文档目录
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

  /// 选择保存目录
  Future<void> _selectDirectory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 这里应该使用文件选择器，暂时使用简单的目录输入
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
            content: Text('选择目录失败: $e'),
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

  /// 验证输入
  String? _validateInput() {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      return '请输入文件名';
    }

    final directory = _selectedDirectory;
    if (directory == null || directory.isEmpty) {
      return '请选择保存目录';
    }

    if (!Directory(directory).existsSync()) {
      return '选择的目录不存在';
    }

    // 检查文件名是否包含非法字符
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) {
      return '文件名包含非法字符';
    }

    return null;
  }

  /// 保存文件
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

      // 根据格式选择保存方式
      final fileService = ref.read(fileServiceProvider);
      final exportFormat = _selectedFormat.toExportFormat();
      
      if (exportFormat != null) {
        // 需要导出的格式（HTML、PDF、DOCX）
        final settings = ExportSettings(
          format: exportFormat,
          outputPath: '',
          fileName: fileName,
        );
        await fileService.exportDocument(widget.document, settings, targetPath: filePath);
      } else {
        // 直接保存的格式（Markdown、纯文本）
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
            content: Text('保存失败: $e'),
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
          const Text('另存为'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件名输入
            Text(
              '文件名',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                hintText: '输入文件名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 保存格式选择
            Text(
              '保存格式',
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
            
            // 保存路径选择
            Text(
              '保存位置',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      hintText: '选择保存位置',
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
                  label: const Text('浏览'),
                ),
              ],
            ),
            
            // 预览完整路径
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
                      '完整路径:',
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
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveFile,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}

/// 简单的目录选择对话框
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
      title: const Text('选择保存目录'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 路径输入
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: '目录路径',
                hintText: '输入或选择目录路径',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 常用路径
            Text(
              '常用位置',
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
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final path = _pathController.text.trim();
            if (path.isNotEmpty && Directory(path).existsSync()) {
              Navigator.of(context).pop(path);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('请选择有效的目录路径'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}