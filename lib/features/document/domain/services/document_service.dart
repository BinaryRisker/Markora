import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../../../types/document.dart';
import '../repositories/document_repository.dart';

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

    // Save to repository (Hive database)
    await _repository.saveDocument(updatedDocument);
    
    // If document has a file path, also save to the original file
    if (updatedDocument.filePath != null && updatedDocument.filePath!.isNotEmpty && !kIsWeb) {
      try {
        final file = File(updatedDocument.filePath!);
        await file.writeAsString(updatedDocument.content, encoding: utf8);
      } catch (e) {
        // If file save fails, still keep the database save successful
        // This ensures the document is not lost even if file write fails
        print('Warning: Failed to save to file ${updatedDocument.filePath}: $e');
      }
    }
  }

  /// Save as
  Future<Document> saveAsDocument(Document document, {String? newPath}) async {
    if (newPath == null || newPath.isEmpty) {
      throw ArgumentError('New path cannot be null or empty for Save As');
    }

    // Determine new title from the new path
    final newTitle = path.basenameWithoutExtension(newPath);

    // Create a new document object with updated path and title
    final newDocument = document.copyWith(
      filePath: newPath,
      title: newTitle,
      updatedAt: DateTime.now(),
    );

    // Save the document to the new file path AND update the database record
    await saveDocument(newDocument);

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