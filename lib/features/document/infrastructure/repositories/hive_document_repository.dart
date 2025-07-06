import 'package:hive/hive.dart';

import '../../../../types/document.dart';
import '../../domain/repositories/document_repository.dart';

/// Hive document repository implementation
class HiveDocumentRepository implements DocumentRepository {
  static const String _boxName = 'documents';
  Box<Document>? _box;

  /// Ensure Box is initialized
  Future<Box<Document>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Document>(_boxName);
    }
    return _box!;
  }

  /// Initialize
  Future<void> init() async {
    await _getBox();
  }

  @override
  Future<Document> createDocument({
    String? title,
    String? content,
    DocumentType type = DocumentType.markdown,
  }) async {
    final box = await _getBox();
    final now = DateTime.now();
    final document = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? '未命名文档',
      content: content ?? '',
      type: type,
      createdAt: now,
      updatedAt: now,
    );

    await box.put(document.id, document);
    return document;
  }

  @override
  Future<Document?> getDocument(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  @override
  Future<List<Document>> getAllDocuments() async {
    final box = await _getBox();
    return box.values.toList();
  }

  @override
  Future<void> saveDocument(Document document) async {
    final box = await _getBox();
    await box.put(document.id, document);
  }

  @override
  Future<void> deleteDocument(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<Document> importDocument(String filePath) async {
    // Implementation will be handled in DocumentService
    // This method is mainly used to save imported documents
    throw UnimplementedError('请使用DocumentService的importDocument方法');
  }

  @override
  Future<String> exportDocument(Document document, String exportPath) async {
    // Implementation will be handled in DocumentService
    throw UnimplementedError('请使用DocumentService的exportDocument方法');
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    final allDocuments = await getAllDocuments();
    final queryLower = query.toLowerCase();
    
    return allDocuments.where((doc) {
      return doc.title.toLowerCase().contains(queryLower) ||
          doc.content.toLowerCase().contains(queryLower) ||
          doc.tags.any((tag) => tag.toLowerCase().contains(queryLower));
    }).toList();
  }

  @override
  Future<List<Document>> getRecentDocuments({int limit = 10}) async {
    final allDocuments = await getAllDocuments();
    
    // Sort by update time
    allDocuments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return allDocuments.take(limit).toList();
  }

  /// Count words
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Close database
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}