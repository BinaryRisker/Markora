import '../../../../types/document.dart';

/// 文档仓库接口
abstract class DocumentRepository {
  /// 创建新文档
  Future<Document> createDocument({
    String? title,
    String? content,
    DocumentType type = DocumentType.markdown,
  });

  /// 获取文档
  Future<Document?> getDocument(String id);

  /// 获取所有文档
  Future<List<Document>> getAllDocuments();

  /// 保存文档
  Future<void> saveDocument(Document document);

  /// 删除文档
  Future<void> deleteDocument(String id);

  /// 导入文档
  Future<Document> importDocument(String filePath);

  /// 导出文档
  Future<String> exportDocument(Document document, String exportPath);

  /// 搜索文档
  Future<List<Document>> searchDocuments(String query);

  /// 获取最近文档
  Future<List<Document>> getRecentDocuments({int limit = 10});
} 