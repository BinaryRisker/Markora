import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../types/document.dart';
import '../providers/document_providers.dart';

/// File dialog type
enum FileDialogType {
  open, // Open file
  save, // Save file
}

/// File selection dialog
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
    
    // Search input listener
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
            // Dialog title and actions
            _buildHeader(theme),
            
            const SizedBox(height: 16),
            
            // Search bar
            _buildSearchBar(theme),
            
            const SizedBox(height: 16),
            
            // Main content area
            Expanded(
              child: Row(
                children: [
                  // File list
                  Expanded(
                    flex: _showPreview ? 1 : 2,
                    child: _buildFileList(documentsAsync, theme),
                  ),
                  
                  // Preview area
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
            
            // Footer area
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  /// Build header
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
        // Preview toggle button
        IconButton(
          icon: Icon(_showPreview ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye),
          onPressed: () {
            setState(() {
              _showPreview = !_showPreview;
            });
          },
          tooltip: _showPreview ? 'Hide Preview' : 'Show Preview',
        ),
        // Close button
        IconButton(
          icon: Icon(PhosphorIconsRegular.x),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search documents...',
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

  /// Build file list
  Widget _buildFileList(AsyncValue<List<Document>> documentsAsync, ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.files, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Document List',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Sort button
                PopupMenuButton<String>(
                  icon: Icon(PhosphorIconsRegular.sortAscending, size: 16),
                  tooltip: 'Sort',
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'name', child: Text('By Name')),
                    const PopupMenuItem(value: 'date', child: Text('By Date')),
                    const PopupMenuItem(value: 'size', child: Text('By Size')),
                  ],
                  onSelected: (value) {
                    // TODO: Implement sorting
                  },
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // File list content
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
                    Text('Failed to load documents'),
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

  /// Build document list
  Widget _buildDocumentList(List<Document> documents, ThemeData theme) {
    // Filter documents
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
              _searchQuery.isEmpty ? 'No documents' : 'No matching documents found',
              style: theme.textTheme.bodyLarge,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
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

  /// Build preview area
  Widget _buildPreviewArea(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.eye, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Preview content
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
                          'Select a document to view preview',
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

  /// Build document preview
  Widget _buildDocumentPreview(Document document, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document information
          _buildInfoRow(theme, 'Title', document.title),
          _buildInfoRow(theme, 'Created', _formatDate(document.createdAt)),
          _buildInfoRow(theme, 'Modified', _formatDate(document.updatedAt)),
          _buildInfoRow(theme, 'Characters', '${document.content.length}'),
          _buildInfoRow(theme, 'Lines', '${document.content.split('\n').length}'),
          
          const SizedBox(height: 16),
          
          // Content preview
          Text(
            'Content Preview',
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
                  document.content.isNotEmpty ? document.content : '(Empty document)',
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

  /// Build info row
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

  /// Build footer
  Widget _buildFooter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File name input for save mode
        if (widget.type == FileDialogType.save) ...[
          Text(
            'File Name',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fileNameController,
            decoration: InputDecoration(
              hintText: 'Enter file name...',
              suffixText: '.${AppConstants.defaultFileExtension}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Button area
        Row(
          children: [
            // Statistics
            if (_selectedDocument != null)
              Text(
                'Selected: ${_selectedDocument!.title}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            
            const Spacer(),
            
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            
            const SizedBox(width: 8),
            
            // Confirm button
            FilledButton(
              onPressed: _canConfirm ? _handleConfirm : null,
              child: Text(widget.type == FileDialogType.open ? 'Open' : 'Save'),
            ),
          ],
        ),
      ],
    );
  }

  /// Whether can confirm
  bool get _canConfirm {
    if (widget.type == FileDialogType.open) {
      return _selectedDocument != null;
    } else {
      return _fileNameController.text.trim().isNotEmpty;
    }
  }

  /// Handle confirm
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

  /// Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// Get document preview
  String _getDocumentPreview(String content) {
    final lines = content.split('\n');
    final firstLine = lines.isNotEmpty ? lines.first.trim() : '';
    
    // Remove Markdown markers
    String preview = firstLine.replaceAll(RegExp(r'^#+\s*'), ''); // Headers
    preview = preview.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'); // Bold
    preview = preview.replaceAll(RegExp(r'\*(.*?)\*'), r'$1'); // Italic
    preview = preview.replaceAll(RegExp(r'`(.*?)`'), r'$1'); // Code
    
    return preview.isEmpty ? '(Empty document)' : preview;
  }
}

/// Show open file dialog
Future<Document?> showOpenFileDialog(BuildContext context) {
  return showDialog<Document>(
    context: context,
    builder: (context) => const FileDialog(type: FileDialogType.open),
  );
}

/// Show save file dialog
Future<String?> showSaveFileDialog(BuildContext context, {String? initialFileName}) {
  return showDialog<String>(
    context: context,
    builder: (context) => FileDialog(
      type: FileDialogType.save,
      initialFileName: initialFileName,
    ),
  );
}