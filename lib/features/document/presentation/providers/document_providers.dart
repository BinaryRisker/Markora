import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../types/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/services/document_service.dart';
import '../../infrastructure/repositories/hive_document_repository.dart';

/// 文档仓库Provider
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return HiveDocumentRepository();
});

/// 文档服务Provider
final documentServiceProvider = Provider<DocumentService>((ref) {
  final repository = ref.read(documentRepositoryProvider);
  return DocumentService(repository);
});

/// 当前文档Provider
class CurrentDocumentNotifier extends StateNotifier<Document?> {
  CurrentDocumentNotifier(this._documentService) : super(null);

  final DocumentService _documentService;

  /// 创建新文档
  Future<void> createNewDocument({
    String? title,
    String? content,
  }) async {
    try {
      final document = await _documentService.createNewDocument(
        title: title,
        content: content,
      );
      state = document;
    } catch (e) {
      // 错误处理
      rethrow;
    }
  }

  /// 打开文档
  Future<void> openDocument(String id) async {
    try {
      final document = await _documentService.openDocument(id);
      state = document;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新文档内容
  void updateContent(String content) {
    if (state != null) {
      state = state!.copyWith(content: content);
    }
  }

  /// 更新文档标题
  void updateTitle(String title) {
    if (state != null) {
      state = state!.copyWith(title: title);
    }
  }

  /// 保存文档
  Future<void> saveDocument() async {
    if (state != null) {
      try {
        await _documentService.saveDocument(state!);
        // 更新保存时间
        state = state!.copyWith(
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        rethrow;
      }
    }
  }

  /// 另存为
  Future<void> saveAsDocument({
    String? newTitle,
    String? newPath,
  }) async {
    if (state != null) {
      try {
        final newDocument = await _documentService.saveAsDocument(
          state!,
          newTitle: newTitle,
          newPath: newPath,
        );
        state = newDocument;
      } catch (e) {
        rethrow;
      }
    }
  }

  /// 导入文档
  Future<void> importDocument(String filePath) async {
    try {
      final document = await _documentService.importDocument(filePath);
      state = document;
    } catch (e) {
      rethrow;
    }
  }

  /// 导出文档
  Future<String> exportDocument(
    String exportPath, {
    ExportFormat format = ExportFormat.markdown,
  }) async {
    if (state != null) {
      try {
        return await _documentService.exportDocument(
          state!,
          exportPath,
          format: format,
        );
      } catch (e) {
        rethrow;
      }
    }
    throw Exception('没有可导出的文档');
  }

  /// 设置当前文档
  void setCurrentDocument(Document document) {
    state = document;
  }

  /// 关闭文档
  void closeDocument() {
    state = null;
  }
}

final currentDocumentProvider = StateNotifierProvider<CurrentDocumentNotifier, Document?>((ref) {
  final documentService = ref.read(documentServiceProvider);
  return CurrentDocumentNotifier(documentService);
});

/// 文档列表Provider
final documentListProvider = FutureProvider<List<Document>>((ref) async {
  final documentService = ref.read(documentServiceProvider);
  return await documentService.getAllDocuments();
});

/// 文档列表Provider（别名）
final documentsListProvider = FutureProvider<List<Document>>((ref) async {
  final documentService = ref.read(documentServiceProvider);
  return await documentService.getAllDocuments();
});

/// 最近文档Provider
final recentDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final documentService = ref.read(documentServiceProvider);
  return await documentService.getRecentDocuments();
});

/// 文档搜索Provider
final documentSearchProvider = FutureProvider.family<List<Document>, String>((ref, query) async {
  final documentService = ref.read(documentServiceProvider);
  return await documentService.searchDocuments(query);
});

/// 文档修改状态Provider
final documentModifiedProvider = Provider<bool>((ref) {
  final currentDocument = ref.watch(currentDocumentProvider);
  if (currentDocument == null) return false;
  
  // 检查文档是否已修改（这里简单地检查更新时间）
  return true; // 实际实现中可以比较内容哈希或其他标识
}); 