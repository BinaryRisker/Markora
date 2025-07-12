import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../types/document.dart';
import '../providers/document_providers.dart';

/// File dialog constants
class _FileDialogConstants {
  static const double dialogWidth = 800.0;
  static const double dialogHeight = 600.0;
  static const double borderRadius = 8.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double padding = 12.0;
  static const int maxPreviewLength = 200;
  static const int maxPreviewLines = 5;
}

/// Document sort type
enum DocumentSortType {
  name,
  date,
  size,
}

/// Document sort order
enum SortOrder {
  ascending,
  descending,
}

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
  DocumentSortType _sortType = DocumentSortType.date;
  SortOrder _sortOrder = SortOrder.descending;
  
  // Cached regex patterns for performance
  static final RegExp _headerRegex = RegExp(r'^#+\s*');
  static final RegExp _boldRegex = RegExp(r'\*\*(.*?)\*\*');
  static final RegExp _italicRegex = RegExp(r'\*(.*?)\*');
  static final RegExp _codeRegex = RegExp(r'`(.*?)`');
  static final RegExp _linkRegex = RegExp(r'\[([^\]]+)\]\([^\)]+\)');
  static final RegExp _imageRegex = RegExp(r'!\[([^\]]*)\]\([^\)]+\)');
  static final RegExp _listRegex = RegExp(r'^[\s]*[-*+]\s+');
  static final RegExp _numberedListRegex = RegExp(r'^[\s]*\d+\.\s+');
  static final RegExp _blockquoteRegex = RegExp(r'^>\s*');

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
        width: _FileDialogConstants.dialogWidth,
        height: _FileDialogConstants.dialogHeight,
        padding: const EdgeInsets.all(_FileDialogConstants.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog title and actions
            _buildHeader(theme),
            
            const SizedBox(height: _FileDialogConstants.spacing),
            
            // Search bar
            _buildSearchBar(theme),
            
            const SizedBox(height: _FileDialogConstants.spacing),
            
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
                    const SizedBox(width: _FileDialogConstants.spacing),
                    Expanded(
                      flex: 1,
                      child: _buildPreviewArea(theme),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: _FileDialogConstants.spacing),
            
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search documents...',
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(PhosphorIconsRegular.x),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_FileDialogConstants.borderRadius),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(width: _FileDialogConstants.smallSpacing),
        _buildSortButton(theme),
        const SizedBox(width: _FileDialogConstants.smallSpacing),
        IconButton(
          icon: Icon(
            _showPreview ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye,
          ),
          onPressed: () {
            setState(() {
              _showPreview = !_showPreview;
            });
          },
          tooltip: _showPreview ? 'Hide Preview' : 'Show Preview',
        ),
      ],
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

  /// Build sort button
  Widget _buildSortButton(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        _sortOrder == SortOrder.ascending 
            ? PhosphorIconsRegular.sortAscending 
            : PhosphorIconsRegular.sortDescending,
        size: 20,
      ),
      tooltip: 'Sort documents',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'name',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.textAa, size: 16),
              const SizedBox(width: 8),
              const Text('By Name'),
              if (_sortType == DocumentSortType.name) ...[
                const Spacer(),
                Icon(PhosphorIconsRegular.check, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'date',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.calendar, size: 16),
              const SizedBox(width: 8),
              const Text('By Date'),
              if (_sortType == DocumentSortType.date) ...[
                const Spacer(),
                Icon(PhosphorIconsRegular.check, size: 16),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'size',
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.fileText, size: 16),
              const SizedBox(width: 8),
              const Text('By Size'),
              if (_sortType == DocumentSortType.size) ...[
                const Spacer(),
                Icon(PhosphorIconsRegular.check, size: 16),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'toggle_order',
          child: Row(
            children: [
              Icon(
                _sortOrder == SortOrder.ascending 
                    ? PhosphorIconsRegular.sortDescending 
                    : PhosphorIconsRegular.sortAscending,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _sortOrder == SortOrder.ascending 
                    ? 'Sort Descending' 
                    : 'Sort Ascending',
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        setState(() {
          switch (value) {
            case 'name':
              _sortType = DocumentSortType.name;
              break;
            case 'date':
              _sortType = DocumentSortType.date;
              break;
            case 'size':
              _sortType = DocumentSortType.size;
              break;
            case 'toggle_order':
              _sortOrder = _sortOrder == SortOrder.ascending 
                  ? SortOrder.descending 
                  : SortOrder.ascending;
              break;
          }
        });
      },
    );
  }

  /// Build document list
  Widget _buildDocumentList(List<Document> documents, ThemeData theme) {
    try {
      // Filter documents based on search query
      final filteredDocuments = _filterDocuments(documents);
      
      // Sort documents
      _sortDocuments(filteredDocuments);

      if (filteredDocuments.isEmpty) {
        return _buildEmptyState(theme);
      }

      return ListView.builder(
        itemCount: filteredDocuments.length,
        itemBuilder: (context, index) {
          final document = filteredDocuments[index];
          final isSelected = _selectedDocument?.id == document.id;
          
          return _buildDocumentListItem(document, isSelected, theme);
        },
      );
    } catch (e) {
      return _buildErrorState(theme, e.toString());
    }
  }
  
  /// Filter documents based on search query
  List<Document> _filterDocuments(List<Document> documents) {
    if (_searchQuery.isEmpty) {
      return List.from(documents);
    }
    
    final query = _searchQuery.toLowerCase();
    return documents.where((doc) {
      return doc.title.toLowerCase().contains(query) ||
             doc.content.toLowerCase().contains(query) ||
             _getDocumentPreview(doc.content).toLowerCase().contains(query);
    }).toList();
  }
  
  /// Sort documents based on current sort settings
  void _sortDocuments(List<Document> documents) {
    documents.sort((a, b) {
      int comparison;
      switch (_sortType) {
        case DocumentSortType.name:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case DocumentSortType.date:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case DocumentSortType.size:
          comparison = a.content.length.compareTo(b.content.length);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
  }
  
  /// Build empty state widget
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty 
                ? PhosphorIconsRegular.magnifyingGlass 
                : PhosphorIconsRegular.fileX,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: _FileDialogConstants.spacing),
          Text(
            _searchQuery.isNotEmpty ? 'No documents found' : 'No documents available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: _FileDialogConstants.smallSpacing),
            Text(
              'Try adjusting your search terms or clear the search',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(height: _FileDialogConstants.smallSpacing),
            Text(
              'Create your first document to get started',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build error state widget
  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.warning,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: _FileDialogConstants.spacing),
          Text(
            'Error loading documents',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: _FileDialogConstants.smallSpacing),
          Text(
            'Please try again later',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: _FileDialogConstants.smallSpacing),
            Text(
              'Error: $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build document list item
  Widget _buildDocumentListItem(Document document, bool isSelected, ThemeData theme) {
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
  }

  /// Build preview area
  Widget _buildPreviewArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(_FileDialogConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(_FileDialogConstants.padding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_FileDialogConstants.borderRadius),
                topRight: Radius.circular(_FileDialogConstants.borderRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.eye,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: _FileDialogConstants.smallSpacing),
                Text(
                  'Preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedDocument != null) ...[
                  const Spacer(),
                  Text(
                    _formatFileSize(_selectedDocument!.content.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Preview content
          Expanded(
            child: _selectedDocument != null
                ? _buildDocumentPreview(_selectedDocument!, theme)
                : _buildNoPreviewState(theme),
          ),
        ],
      ),
    );
  }
  
  /// Build no preview state
  Widget _buildNoPreviewState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.fileText,
            size: 48,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: _FileDialogConstants.spacing),
          Text(
            'Select a document to preview',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: _FileDialogConstants.smallSpacing),
          Text(
            'Document content will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Build document preview
  Widget _buildDocumentPreview(Document document, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(_FileDialogConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document info
          _buildInfoSection(document, theme),
          
          const SizedBox(height: _FileDialogConstants.spacing),
          
          // Content preview section
          _buildContentPreviewSection(document, theme),
        ],
      ),
    );
  }
  
  /// Build document info section
  Widget _buildInfoSection(Document document, ThemeData theme) {
    final stats = _getDocumentStats(document);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Info',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: _FileDialogConstants.smallSpacing),
        _buildInfoRow(theme, 'Title', document.title),
        _buildInfoRow(theme, 'Created', _formatDate(document.createdAt)),
        _buildInfoRow(theme, 'Modified', _formatDate(document.updatedAt)),
        _buildInfoRow(theme, 'Size', _formatFileSize(document.content.length)),
        _buildInfoRow(theme, 'Lines', '${stats['lines']}'),
        _buildInfoRow(theme, 'Words', '${stats['words']}'),
        _buildInfoRow(theme, 'Characters', '${stats['characters']}'),
      ],
    );
  }
  
  /// Build content preview section
  Widget _buildContentPreviewSection(Document document, ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Content Preview',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (document.content.length > _FileDialogConstants.maxPreviewLength * 5)
                Text(
                  'Truncated',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: _FileDialogConstants.smallSpacing),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(_FileDialogConstants.padding),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(_FileDialogConstants.borderRadius),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  document.content.isNotEmpty 
                      ? _getLimitedContent(document.content)
                      : '(Empty document)',
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
  
  /// Get document statistics
  Map<String, int> _getDocumentStats(Document document) {
    final content = document.content;
    final lines = content.split('\n');
    final words = content.trim().isEmpty 
        ? 0 
        : content.trim().split(RegExp(r'\s+')).length;
    
    return {
      'lines': lines.length,
      'words': words,
      'characters': content.length,
    };
  }
  
  /// Get limited content for preview
  String _getLimitedContent(String content) {
    const maxLines = 50;
    const maxChars = 2000;
    
    final lines = content.split('\n');
    
    if (lines.length <= maxLines && content.length <= maxChars) {
      return content;
    }
    
    if (lines.length > maxLines) {
      final limitedLines = lines.take(maxLines).join('\n');
      return '$limitedLines\n\n... (${lines.length - maxLines} more lines)';
    }
    
    if (content.length > maxChars) {
      return '${content.substring(0, maxChars)}\n\n... (${content.length - maxChars} more characters)';
    }
    
    return content;
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
          const SizedBox(height: _FileDialogConstants.smallSpacing),
          TextField(
            controller: _fileNameController,
            decoration: InputDecoration(
              hintText: 'Enter file name...',
              suffixText: '.${AppConstants.defaultFileExtension}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_FileDialogConstants.borderRadius),
              ),
              errorText: _getFileNameError(),
            ),
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update error state
            },
          ),
          const SizedBox(height: _FileDialogConstants.spacing),
        ],
        
        // Status and button area
        Row(
          children: [
            // Status information
            Expanded(
              child: _buildStatusInfo(theme),
            ),
            
            // Action buttons
            _buildActionButtons(theme),
          ],
        ),
      ],
    );
  }
  
  /// Build status information
  Widget _buildStatusInfo(ThemeData theme) {
    if (_selectedDocument != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected: ${_selectedDocument!.title}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${_formatFileSize(_selectedDocument!.content.length)} • ${_formatDate(_selectedDocument!.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }
    
    if (widget.type == FileDialogType.save && _fileNameController.text.isNotEmpty) {
      return Text(
        'File will be saved as: ${_fileNameController.text}.${AppConstants.defaultFileExtension}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  /// Build action buttons
  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        
        const SizedBox(width: _FileDialogConstants.smallSpacing),
        
        // Confirm button
        FilledButton(
          onPressed: _canConfirm ? _handleConfirm : null,
          child: Text(widget.type == FileDialogType.open ? 'Open' : 'Save'),
        ),
      ],
    );
  }
  
  /// Get file name validation error
  String? _getFileNameError() {
    if (widget.type != FileDialogType.save) return null;
    
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) return null;
    
    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) {
      return 'File name contains invalid characters';
    }
    
    // Check for reserved names (Windows)
    final reservedNames = ['CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'];
    if (reservedNames.contains(fileName.toUpperCase())) {
      return 'File name is reserved';
    }
    
    // Check length
    if (fileName.length > 255) {
      return 'File name is too long';
    }
    
    return null;
  }

  /// Whether can confirm
  bool get _canConfirm {
    if (widget.type == FileDialogType.open) {
      return _selectedDocument != null;
    } else {
      final fileName = _fileNameController.text.trim();
      return fileName.isNotEmpty && _getFileNameError() == null;
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
    if (content.isEmpty) {
      return '(Empty document)';
    }
    
    final lines = content.split('\n');
    final previewLines = lines.take(_FileDialogConstants.maxPreviewLines).toList();
    
    // Join lines and limit length
    String preview = previewLines.join(' ').trim();
    
    // Remove Markdown markers using cached regex patterns
    preview = _cleanMarkdownText(preview);
    
    // Limit preview length
    if (preview.length > _FileDialogConstants.maxPreviewLength) {
      preview = '${preview.substring(0, _FileDialogConstants.maxPreviewLength)}...';
    }
    
    return preview.isEmpty ? '(Empty document)' : preview;
  }
  
  /// Clean markdown text by removing formatting
  String _cleanMarkdownText(String text) {
    String cleaned = text;
    
    // Remove headers
    cleaned = cleaned.replaceAll(_headerRegex, '');
    
    // Remove bold and italic
    cleaned = cleaned.replaceAll(_boldRegex, r'$1');
    cleaned = cleaned.replaceAll(_italicRegex, r'$1');
    
    // Remove inline code
    cleaned = cleaned.replaceAll(_codeRegex, r'$1');
    
    // Remove links but keep text
    cleaned = cleaned.replaceAll(_linkRegex, r'$1');
    
    // Remove images
    cleaned = cleaned.replaceAll(_imageRegex, r'$1');
    
    // Remove list markers
    cleaned = cleaned.replaceAll(_listRegex, '');
    cleaned = cleaned.replaceAll(_numberedListRegex, '');
    
    // Remove blockquotes
    cleaned = cleaned.replaceAll(_blockquoteRegex, '');
    
    // Clean up extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
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