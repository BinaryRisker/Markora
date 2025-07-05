import 'package:hive/hive.dart';

import '../../../../types/document.dart';
import '../../domain/repositories/document_repository.dart';

/// Hive文档仓库实现
class HiveDocumentRepository implements DocumentRepository {
  static const String _boxName = 'documents';
  late Box<Document> _box;

  /// 初始化
  Future<void> init() async {
    _box = await Hive.openBox<Document>(_boxName);
  }

  @override
  Future<Document> createDocument({
    String? title,
    String? content,
    DocumentType type = DocumentType.markdown,
  }) async {
    final now = DateTime.now();
    final document = Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? '未命名文档',
      content: content ?? '',
      type: type,
      createdAt: now,
      updatedAt: now,
    );

    await _box.put(document.id, document);
    return document;
  }

  @override
  Future<Document?> getDocument(String id) async {
    return _box.get(id);
  }

  @override
  Future<List<Document>> getAllDocuments() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveDocument(Document document) async {
    await _box.put(document.id, document);
  }

  @override
  Future<void> deleteDocument(String id) async {
    await _box.delete(id);
  }

  @override
  Future<Document> importDocument(String filePath) async {
    // 这里的实现将在DocumentService中处理
    // 此方法主要用于保存导入的文档
    throw UnimplementedError('请使用DocumentService的importDocument方法');
  }

  @override
  Future<String> exportDocument(Document document, String exportPath) async {
    // 这里的实现将在DocumentService中处理
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
    
    // 按更新时间排序
    allDocuments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return allDocuments.take(limit).toList();
  }

  /// 统计单词数
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// 关闭数据库
  Future<void> close() async {
    await _box.close();
  }
} 