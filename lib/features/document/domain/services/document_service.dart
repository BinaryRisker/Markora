import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../../../types/document.dart';
import '../repositories/document_repository.dart';
import '../../../export/domain/services/export_service.dart';
import '../../../export/domain/entities/export_settings.dart';

/// Document service
class DocumentService {
  const DocumentService(this._repository);

  final DocumentRepository _repository;
  static const _uuid = Uuid();

  /// Create new document
  Future<Document> createNewDocument({
    String? title,
    String? content,
  }) async {
    final now = DateTime.now();
    final document = Document(
      id: _uuid.v4(),
      title: title ?? 'Untitled Document',
      content: content ?? '',
      type: DocumentType.markdown,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveDocument(document);
    return document;
  }

  /// Open document
  Future<Document?> openDocument(String id) async {
    return await _repository.getDocument(id);
  }

  /// Save document
  Future<void> saveDocument(Document document) async {
    // Update metadata
    final updatedDocument = document.copyWith(
      updatedAt: DateTime.now(),
    );

    await _repository.saveDocument(updatedDocument);
  }

  /// Save as
  Future<Document> saveAsDocument(Document document, {
    String? newTitle,
    String? newPath,
  }) async {
    final newDocument = document.copyWith(
      id: _uuid.v4(),
      title: newTitle ?? '${document.title} - Copy',
      filePath: newPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.saveDocument(newDocument);
    return newDocument;
  }

  /// Import document
  Future<Document> importDocument(String filePath) async {
    try {
      if (kIsWeb) {
        // Web environment: File import should be handled by file picker
        // This method should not be called directly in Web environment
        throw Exception('File import in Web environment should use file picker');
      }
      
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File does not exist: $filePath');
      }

      final content = await file.readAsString();
      final fileName = path.basenameWithoutExtension(filePath);
      final extension = path.extension(filePath).toLowerCase();

      DocumentType type;
      switch (extension) {
        case '.md':
        case '.markdown':
          type = DocumentType.markdown;
          break;
        case '.txt':
          type = DocumentType.text;
          break;
        case '.html':
          type = DocumentType.html;
          break;
        default:
          type = DocumentType.markdown;
      }

      final document = await createNewDocument(
        title: fileName,
        content: content,
      );

      return document.copyWith(
        type: type,
        filePath: filePath,
      );
    } catch (e) {
      throw Exception('Failed to import document: $e');
    }
  }

  /// Import document from content (Web-compatible)
  Future<Document> importDocumentFromContent(
    String content,
    String fileName, {
    String? filePath,
  }) async {
    try {
      final extension = path.extension(fileName).toLowerCase();

      DocumentType type;
      switch (extension) {
        case '.md':
        case '.markdown':
          type = DocumentType.markdown;
          break;
        case '.txt':
          type = DocumentType.text;
          break;
        case '.html':
          type = DocumentType.html;
          break;
        default:
          type = DocumentType.markdown;
      }

      final documentTitle = path.basenameWithoutExtension(fileName);
      final document = await createNewDocument(
        title: documentTitle,
        content: content,
      );

      return document.copyWith(
        type: type,
        filePath: filePath,
      );
    } catch (e) {
      throw Exception('Failed to import document from content: $e');
    }
  }

  /// Export document
  Future<String> exportDocument(
    Document document,
    String exportPath, {
    ExportFormat format = ExportFormat.html,
  }) async {
    try {
      switch (format) {
        case ExportFormat.html:
          final content = _convertToHtml(document.content);
          final fileName = path.basenameWithoutExtension(exportPath);
          final finalPath = path.join(
            path.dirname(exportPath),
            '$fileName.html',
          );
          
          if (kIsWeb) {
            // Use export service for Web environment
            final exportService = ExportServiceImpl();
            final settings = ExportSettings(
              format: ExportFormat.html,
              outputPath: path.dirname(exportPath),
              fileName: '$fileName.html',
              pdfSettings: const PdfExportSettings(),
              htmlSettings: const HtmlExportSettings(),
            );
            final result = await exportService.exportDocument(document, settings);
            if (!result.success) {
              throw Exception(result.errorMessage ?? 'HTML export failed');
            }
            return finalPath;
          } else {
            // Use File API for non-Web platforms
            final file = File(finalPath);
            await file.writeAsString(content);
            return finalPath;
          }
          
        case ExportFormat.pdf:
          // Use export service for PDF generation
          final exportService = ExportServiceImpl();
          final settings = ExportSettings(
            format: ExportFormat.pdf,
            outputPath: path.dirname(exportPath),
            fileName: path.basename(exportPath),
            pdfSettings: const PdfExportSettings(),
            htmlSettings: const HtmlExportSettings(),
          );
          final result = await exportService.exportDocument(document, settings);
          if (!result.success) {
            throw Exception(result.errorMessage ?? 'PDF export failed');
          }
          return exportPath;
          
        case ExportFormat.docx:
        case ExportFormat.png:
        case ExportFormat.jpeg:
        default:
          throw Exception('${format.displayName} export is not supported yet');
      }
    } catch (e) {
      throw Exception('Failed to export document: $e');
    }
  }

  /// Delete document
  Future<void> deleteDocument(String id) async {
    await _repository.deleteDocument(id);
  }

  /// Get all documents
  Future<List<Document>> getAllDocuments() async {
    return await _repository.getAllDocuments();
  }

  /// Get recent documents
  Future<List<Document>> getRecentDocuments({int limit = 10}) async {
    return await _repository.getRecentDocuments(limit: limit);
  }

  /// Search documents
  Future<List<Document>> searchDocuments(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return await _repository.searchDocuments(query);
  }

  /// Count words
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Convert to HTML
  String _convertToHtml(String markdown) {
    // Simple Markdown to HTML conversion
    // In actual projects, professional Markdown parsers should be used
    return markdown
        .replaceAll(RegExp(r'^# (.+)$', multiLine: true), '<h1>\$1</h1>')
        .replaceAll(RegExp(r'^## (.+)$', multiLine: true), '<h2>\$1</h2>')
        .replaceAll(RegExp(r'^### (.+)$', multiLine: true), '<h3>\$1</h3>')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), '<strong>\$1</strong>')
        .replaceAll(RegExp(r'\*(.+?)\*'), '<em>\$1</em>')
        .replaceAll('\n\n', '</p><p>')
        .replaceAll('\n', '<br>')
        .trim();
  }

  /// Strip Markdown formatting
  String _stripMarkdown(String markdown) {
    return markdown
        .replaceAll(RegExp(r'^#+\s+'), '')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), '\$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), '\$1')
        .replaceAll(RegExp(r'`(.+?)`'), '\$1')
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), '\$1')
        .trim();
  }
}