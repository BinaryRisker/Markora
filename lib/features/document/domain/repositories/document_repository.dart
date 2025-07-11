import '../../../../types/document.dart';

/// Document repository interface
abstract class DocumentRepository {
  /// Create new document
  Future<Document> createDocument({
    String? title,
    String? content,
    DocumentType type = DocumentType.markdown,
  });

  /// Get document
  Future<Document?> getDocument(String id);

  /// Get all documents
  Future<List<Document>> getAllDocuments();

  /// Save document
  Future<void> saveDocument(Document document);

  /// Delete document
  Future<void> deleteDocument(String id);

  /// Import document
  Future<Document> importDocument(String filePath);

  /// Export document
  Future<String> exportDocument(Document document, String exportPath);

  /// Search documents
  Future<List<Document>> searchDocuments(String query);

  /// Get recent documents
  Future<List<Document>> getRecentDocuments({int limit = 10});
}