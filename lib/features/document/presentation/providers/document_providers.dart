import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../types/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/services/document_service.dart';
import '../../domain/services/file_service.dart';
import '../../infrastructure/repositories/hive_document_repository.dart';

/// 文档仓库Provider
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final repo = HiveDocumentRepository();
  // 注意：初始化将在main.dart中完成
  return repo;
});

/// 文档服务Provider
final documentServiceProvider = Provider<DocumentService>((ref) {
  final repository = ref.read(documentRepositoryProvider);
  return DocumentService(repository);
});

/// 文件服务Provider
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

/// 文档Tab信息
class DocumentTab {
  const DocumentTab({
    required this.document,
    this.isModified = false,
    this.lastEditTime,
  });

  final Document document;
  final bool isModified;
  final DateTime? lastEditTime;

  DocumentTab copyWith({
    Document? document,
    bool? isModified,
    DateTime? lastEditTime,
  }) {
    return DocumentTab(
      document: document ?? this.document,
      isModified: isModified ?? this.isModified,
      lastEditTime: lastEditTime ?? this.lastEditTime,
    );
  }
}

/// 文档Tab管理器
class DocumentTabsNotifier extends StateNotifier<List<DocumentTab>> {
  DocumentTabsNotifier(this._documentService) : super([]);

  final DocumentService _documentService;
  int _activeTabIndex = -1;

  /// 当前激活的Tab索引
  int get activeTabIndex => _activeTabIndex;

  /// 当前激活的文档
  Document? get activeDocument => 
      _activeTabIndex >= 0 && _activeTabIndex < state.length 
          ? state[_activeTabIndex].document 
          : null;

  /// 打开文档Tab
  void openDocumentTab(Document document) {
    // 检查文档是否已经打开
    final existingIndex = state.indexWhere((tab) => tab.document.id == document.id);
    
    if (existingIndex >= 0) {
      // 如果已经打开，切换到该Tab
      setActiveTab(existingIndex);
    } else {
      // 如果没有打开，创建新Tab
      final newTab = DocumentTab(document: document);
      state = [...state, newTab];
      _activeTabIndex = state.length - 1;
    }
  }

  /// 创建新文档Tab
  Future<void> createNewDocumentTab({
    String? title,
    String? content,
  }) async {
    try {
      final document = await _documentService.createNewDocument(
        title: title,
        content: content,
      );
      openDocumentTab(document);
    } catch (e) {
      rethrow;
    }
  }

  /// 关闭Tab
  void closeTab(int index) {
    if (index < 0 || index >= state.length) return;

    final newState = List<DocumentTab>.from(state);
    newState.removeAt(index);
    state = newState;

    // 调整激活Tab索引
    if (_activeTabIndex == index) {
      // 如果关闭的是当前激活Tab
      if (newState.isEmpty) {
        _activeTabIndex = -1;
      } else if (index >= newState.length) {
        _activeTabIndex = newState.length - 1;
      }
      // 否则保持当前索引
    } else if (_activeTabIndex > index) {
      _activeTabIndex--;
    }
  }

  /// 设置激活Tab
  void setActiveTab(int index) {
    if (index >= 0 && index < state.length && _activeTabIndex != index) {
      _activeTabIndex = index;
      // 通知状态变化，触发UI更新
      state = [...state];
    }
  }

  /// 更新Tab内容
  void updateTabContent(int index, String content) {
    if (index < 0 || index >= state.length) return;

    final tab = state[index];
    final updatedDocument = tab.document.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );
    
    final updatedTab = tab.copyWith(
      document: updatedDocument,
      isModified: true,
      lastEditTime: DateTime.now(),
    );

    final newState = List<DocumentTab>.from(state);
    newState[index] = updatedTab;
    state = newState;
  }

  /// 保存Tab文档
  Future<void> saveTab(int index) async {
    if (index < 0 || index >= state.length) return;

    try {
      final tab = state[index];
      await _documentService.saveDocument(tab.document);
      
      // 更新Tab状态为已保存
      final updatedTab = tab.copyWith(isModified: false);
      final newState = List<DocumentTab>.from(state);
      newState[index] = updatedTab;
      state = newState;
    } catch (e) {
      rethrow;
    }
  }

  /// 保存当前激活Tab
  Future<void> saveActiveTab() async {
    if (_activeTabIndex >= 0) {
      await saveTab(_activeTabIndex);
    }
  }

  /// 关闭所有Tab
  void closeAllTabs() {
    state = [];
    _activeTabIndex = -1;
  }

  /// 获取Tab标题（显示修改状态）
  String getTabTitle(int index) {
    if (index < 0 || index >= state.length) return '';
    
    final tab = state[index];
    final title = tab.document.title;
    return tab.isModified ? '$title *' : title;
  }
}

/// 文档Tab管理Provider
final documentTabsProvider = StateNotifierProvider<DocumentTabsNotifier, List<DocumentTab>>((ref) {
  final documentService = ref.read(documentServiceProvider);
  return DocumentTabsNotifier(documentService);
});

/// 当前激活文档Provider
final activeDocumentProvider = Provider<Document?>((ref) {
  final tabsNotifier = ref.read(documentTabsProvider.notifier);
  ref.watch(documentTabsProvider); // 监听tabs变化
  return tabsNotifier.activeDocument;
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