import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../types/document.dart';
import '../repositories/document_repository.dart';

/// 文档服务
class DocumentService {
  const DocumentService(this._repository);

  final DocumentRepository _repository;
  static const _uuid = Uuid();

  /// 创建新文档
  Future<Document> createNewDocument({
    String? title,
    String? content,
  }) async {
    final now = DateTime.now();
    final document = Document(
      id: _uuid.v4(),
      title: title ?? '未命名文档',
      content: content ?? '',
      type: DocumentType.markdown,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveDocument(document);
    return document;
  }

  /// 打开文档
  Future<Document?> openDocument(String id) async {
    return await _repository.getDocument(id);
  }

  /// 保存文档
  Future<void> saveDocument(Document document) async {
    // 更新元数据
    final updatedDocument = document.copyWith(
      updatedAt: DateTime.now(),
    );

    await _repository.saveDocument(updatedDocument);
  }

  /// 另存为
  Future<Document> saveAsDocument(Document document, {
    String? newTitle,
    String? newPath,
  }) async {
    final newDocument = document.copyWith(
      id: _uuid.v4(),
      title: newTitle ?? '${document.title} - 副本',
      filePath: newPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.saveDocument(newDocument);
    return newDocument;
  }

  /// 导入文档
  Future<Document> importDocument(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('文件不存在: $filePath');
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
      throw Exception('导入文档失败: $e');
    }
  }

  /// 导出文档
  Future<String> exportDocument(
    Document document,
    String exportPath, {
    ExportFormat format = ExportFormat.markdown,
  }) async {
    try {
      String content;
      String extension;

      switch (format) {
        case ExportFormat.markdown:
          content = document.content;
          extension = '.md';
          break;
        case ExportFormat.html:
          content = _convertToHtml(document.content);
          extension = '.html';
          break;
        case ExportFormat.text:
          content = _stripMarkdown(document.content);
          extension = '.txt';
          break;
        case ExportFormat.pdf:
          // TODO: 实现PDF导出
          throw UnimplementedError('PDF导出功能即将推出');
      }

      final fileName = path.basenameWithoutExtension(exportPath);
      final finalPath = path.join(
        path.dirname(exportPath),
        '$fileName$extension',
      );

      final file = File(finalPath);
      await file.writeAsString(content);

      return finalPath;
    } catch (e) {
      throw Exception('导出文档失败: $e');
    }
  }

  /// 删除文档
  Future<void> deleteDocument(String id) async {
    await _repository.deleteDocument(id);
  }

  /// 获取所有文档
  Future<List<Document>> getAllDocuments() async {
    return await _repository.getAllDocuments();
  }

  /// 获取最近文档
  Future<List<Document>> getRecentDocuments({int limit = 10}) async {
    return await _repository.getRecentDocuments(limit: limit);
  }

  /// 搜索文档
  Future<List<Document>> searchDocuments(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return await _repository.searchDocuments(query);
  }

  /// 统计单词数
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// 转换为HTML
  String _convertToHtml(String markdown) {
    // 简单的Markdown到HTML转换
    // 在实际项目中，应该使用专业的Markdown解析器
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

  /// 去除Markdown格式
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

/// 导出格式枚举
enum ExportFormat {
  markdown('Markdown'),
  html('HTML'),
  text('纯文本'),
  pdf('PDF');

  const ExportFormat(this.displayName);
  final String displayName;
} 