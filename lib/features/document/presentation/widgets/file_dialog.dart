import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../types/document.dart';
import '../providers/document_providers.dart';

/// 文件选择对话框类型
enum FileDialogType {
  open, // 打开文件
  save, // 保存文件
}

/// 文件选择对话框
class FileDialog extends ConsumerStatefulWidget {
  final FileDialogType type;
  final String? initialFileName;
  final String? title;

  const FileDialog({
    super.key,
    required this.type,
    this.initialFileName,
    this.title,
  });

  @override
  ConsumerState<FileDialog> createState() => _FileDialogState();
}

class _FileDialogState extends ConsumerState<FileDialog> {
  late TextEditingController _searchController;
  late TextEditingController _fileNameController;
  String _searchQuery = '';
  Document? _selectedDocument;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fileNameController = TextEditingController(text: widget.initialFileName ?? '');
    
    // 搜索输入监听
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentListProvider);
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 对话框标题和操作
            _buildHeader(theme),
            
            const SizedBox(height: 16),
            
            // 搜索栏
            _buildSearchBar(theme),
            
            const SizedBox(height: 16),
            
            // 主内容区域
            Expanded(
              child: Row(
                children: [
                  // 文件列表
                  Expanded(
                    flex: _showPreview ? 1 : 2,
                    child: _buildFileList(documentsAsync, theme),
                  ),
                  
                  // 预览区域
                  if (_showPreview) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildPreviewArea(theme),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 底部区域
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(ThemeData theme) {
    String title = widget.title ?? 
        (widget.type == FileDialogType.open ? 'Open Document' : 'Save Document');

    return Row(
      children: [
        Icon(
          widget.type == FileDialogType.open ? PhosphorIconsRegular.folderOpen : PhosphorIconsRegular.floppyDisk,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // 预览切换按钮
        IconButton(
          icon: Icon(_showPreview ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye),
          onPressed: () {
            setState(() {
              _showPreview = !_showPreview;
            });
          },
          tooltip: _showPreview ? '隐藏预览' : '显示预览',
        ),
        // 关闭按钮
        IconButton(
          icon: Icon(PhosphorIconsRegular.x),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '关闭',
        ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索文档...',
        prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(PhosphorIconsRegular.x),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 构建文件列表
  Widget _buildFileList(AsyncValue<List<Document>> documentsAsync, ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 列表头部
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.files, size: 16),
                const SizedBox(width: 8),
                Text(
                  '文档列表',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // 排序按钮
                PopupMenuButton<String>(
                  icon: Icon(PhosphorIconsRegular.sortAscending, size: 16),
                  tooltip: '排序',
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'name', child: Text('按名称')),
                    const PopupMenuItem(value: 'date', child: Text('按日期')),
                    const PopupMenuItem(value: 'size', child: Text('按大小')),
                  ],
                  onSelected: (value) {
                    // TODO: 实现排序
                  },
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 文件列表内容
          Expanded(
            child: documentsAsync.when(
              data: (documents) => _buildDocumentList(documents, theme),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.warning, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('加载文档失败'),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文档列表
  Widget _buildDocumentList(List<Document> documents, ThemeData theme) {
    // 过滤文档
    final filteredDocuments = documents.where((doc) {
      if (_searchQuery.isEmpty) return true;
      return doc.title.toLowerCase().contains(_searchQuery) ||
             doc.content.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.fileX, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '暂无文档' : '未找到匹配的文档',
              style: theme.textTheme.bodyLarge,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '尝试使用不同的关键词搜索',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = filteredDocuments[index];
        final isSelected = _selectedDocument?.id == document.id;

        return GestureDetector(
          onDoubleTap: () {
            if (widget.type == FileDialogType.open) {
              _handleConfirm();
            }
          },
          child: ListTile(
            selected: isSelected,
            leading: Icon(
              PhosphorIconsRegular.fileText,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
            title: Text(
              document.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(document.updatedAt),
                  style: theme.textTheme.bodySmall,
                ),
                if (document.content.isNotEmpty)
                  Text(
                    _getDocumentPreview(document.content),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              _formatFileSize(document.content.length),
              style: theme.textTheme.bodySmall,
            ),
            onTap: () {
              setState(() {
                _selectedDocument = document;
                if (widget.type == FileDialogType.save) {
                  _fileNameController.text = document.title;
                }
              });
            },
          ),
        );
      },
    );
  }

  /// 构建预览区域
  Widget _buildPreviewArea(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 预览头部
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.eye, size: 16),
                const SizedBox(width: 8),
                Text(
                  '预览',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 预览内容
          Expanded(
            child: _selectedDocument != null
                ? _buildDocumentPreview(_selectedDocument!, theme)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.fileText,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '选择文档以查看预览',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建文档预览
  Widget _buildDocumentPreview(Document document, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文档信息
          _buildInfoRow(theme, '标题', document.title),
          _buildInfoRow(theme, '创建时间', _formatDate(document.createdAt)),
          _buildInfoRow(theme, '修改时间', _formatDate(document.updatedAt)),
          _buildInfoRow(theme, '字符数', '${document.content.length}'),
          _buildInfoRow(theme, '行数', '${document.content.split('\n').length}'),
          
          const SizedBox(height: 16),
          
          // 内容预览
          Text(
            '内容预览',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  document.content.isNotEmpty ? document.content : '(空文档)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部
  Widget _buildFooter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 保存模式的文件名输入
        if (widget.type == FileDialogType.save) ...[
          Text(
            '文件名',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fileNameController,
            decoration: InputDecoration(
              hintText: '输入文件名...',
              suffixText: '.${AppConstants.defaultFileExtension}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // 按钮区域
        Row(
          children: [
            // 统计信息
            if (_selectedDocument != null)
              Text(
                '已选择: ${_selectedDocument!.title}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            
            const Spacer(),
            
            // 取消按钮
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            
            const SizedBox(width: 8),
            
            // 确认按钮
            FilledButton(
              onPressed: _canConfirm ? _handleConfirm : null,
              child: Text(widget.type == FileDialogType.open ? 'Open' : 'Save'),
            ),
          ],
        ),
      ],
    );
  }

  /// 是否可以确认
  bool get _canConfirm {
    if (widget.type == FileDialogType.open) {
      return _selectedDocument != null;
    } else {
      return _fileNameController.text.trim().isNotEmpty;
    }
  }

  /// 处理确认
  void _handleConfirm() {
    if (!_canConfirm) return;

    if (widget.type == FileDialogType.open) {
      // Open document to Tab
      if (_selectedDocument != null) {
        final tabsNotifier = ref.read(documentTabsProvider.notifier);
        tabsNotifier.openDocumentTab(_selectedDocument!);
      }
      Navigator.of(context).pop(_selectedDocument);
    } else {
      final fileName = _fileNameController.text.trim();
      Navigator.of(context).pop(fileName);
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 获取文档预览
  String _getDocumentPreview(String content) {
    final lines = content.split('\n');
    final firstLine = lines.isNotEmpty ? lines.first.trim() : '';
    
    // 移除Markdown标记
    String preview = firstLine.replaceAll(RegExp(r'^#+\s*'), ''); // 标题
    preview = preview.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'); // 粗体
    preview = preview.replaceAll(RegExp(r'\*(.*?)\*'), r'$1'); // 斜体
    preview = preview.replaceAll(RegExp(r'`(.*?)`'), r'$1'); // 代码
    
    return preview.isEmpty ? '(空文档)' : preview;
  }
}

/// 显示打开文件对话框
Future<Document?> showOpenFileDialog(BuildContext context) {
  return showDialog<Document>(
    context: context,
    builder: (context) => const FileDialog(type: FileDialogType.open),
  );
}

/// 显示保存文件对话框
Future<String?> showSaveFileDialog(BuildContext context, {String? initialFileName}) {
  return showDialog<String>(
    context: context,
    builder: (context) => FileDialog(
      type: FileDialogType.save,
      initialFileName: initialFileName,
    ),
  );
}