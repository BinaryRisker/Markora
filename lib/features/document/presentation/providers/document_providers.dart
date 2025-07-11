import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../types/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/services/document_service.dart';
import '../../domain/services/file_service.dart';
import '../../infrastructure/repositories/hive_document_repository.dart';
import '../../../export/domain/entities/export_settings.dart';

/// Document repository provider
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final repo = HiveDocumentRepository();
  // Note: Initialization will be completed in main.dart
  return repo;
});

/// Document service provider
final documentServiceProvider = Provider<DocumentService>((ref) {
  final repository = ref.read(documentRepositoryProvider);
  return DocumentService(repository);
});

/// File service provider
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

/// Document tab information
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

/// Document tabs manager
class DocumentTabsNotifier extends StateNotifier<List<DocumentTab>> {
  DocumentTabsNotifier(this._documentService) : super([]);

  final DocumentService _documentService;
  int _activeTabIndex = -1;

  /// Current active tab index
  int get activeTabIndex => _activeTabIndex;

  /// Current active document
  Document? get activeDocument => 
      _activeTabIndex >= 0 && _activeTabIndex < state.length 
          ? state[_activeTabIndex].document 
          : null;

  /// Open document tab
  void openDocumentTab(Document document) {
    // Check if document is already open (prioritize file path, then ID)
    int existingIndex = -1;
    
    if (document.filePath != null && document.filePath!.isNotEmpty) {
      // If has file path, search by file path
      existingIndex = state.indexWhere((tab) => 
          tab.document.filePath != null && 
          tab.document.filePath == document.filePath);
    }
    
    if (existingIndex < 0) {
      // If not found by file path, search by ID
      existingIndex = state.indexWhere((tab) => tab.document.id == document.id);
    }
    
    if (existingIndex >= 0) {
      // If already open, switch to that tab
      setActiveTab(existingIndex);
    } else {
      // If not open, create new tab
      final newTab = DocumentTab(document: document);
      state = [...state, newTab];
      _activeTabIndex = state.length - 1;
    }
  }

  /// Create new document tab
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

  /// Close tab
  void closeTab(int index) {
    if (index < 0 || index >= state.length) return;

    final newState = List<DocumentTab>.from(state);
    newState.removeAt(index);
    state = newState;

    // Adjust active tab index
    if (_activeTabIndex == index) {
      // If closing the currently active tab
      if (newState.isEmpty) {
        _activeTabIndex = -1;
      } else if (index >= newState.length) {
        _activeTabIndex = newState.length - 1;
      }
      // Otherwise keep current index
    } else if (_activeTabIndex > index) {
      _activeTabIndex--;
    }
  }

  /// Set active tab
  void setActiveTab(int index) {
    if (index >= 0 && index < state.length && _activeTabIndex != index) {
      _activeTabIndex = index;
      // Notify state change, trigger UI update
      state = [...state];
    }
  }

  /// Update tab content
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

  /// Save tab document
  Future<void> saveTab(int index) async {
    if (index < 0 || index >= state.length) return;

    try {
      final tab = state[index];
      await _documentService.saveDocument(tab.document);
      
      // Update tab state to saved
      final updatedTab = tab.copyWith(isModified: false);
      final newState = List<DocumentTab>.from(state);
      newState[index] = updatedTab;
      state = newState;
    } catch (e) {
      rethrow;
    }
  }

  /// Save current active tab
  Future<void> saveActiveTab() async {
    if (_activeTabIndex >= 0) {
      await saveTab(_activeTabIndex);
    }
  }

  /// Close all tabs
  void closeAllTabs() {
    state = [];
    _activeTabIndex = -1;
  }

  /// Get tab title (show modification status)
  String getTabTitle(int index) {
    if (index < 0 || index >= state.length) return '';
    
    final tab = state[index];
    final title = tab.document.title;
    return tab.isModified ? '$title *' : title;
  }
}

/// Document tabs management provider
final documentTabsProvider = StateNotifierProvider<DocumentTabsNotifier, List<DocumentTab>>((ref) {
  final documentService = ref.read(documentServiceProvider);
  return DocumentTabsNotifier(documentService);
});

/// Current active document provider
final activeDocumentProvider = Provider<Document?>((ref) {
  final tabsNotifier = ref.read(documentTabsProvider.notifier);
  ref.watch(documentTabsProvider); // Listen to tabs changes
  return tabsNotifier.activeDocument;
});

/// Current document provider
class CurrentDocumentNotifier extends StateNotifier<Document?> {
  CurrentDocumentNotifier(this._documentService) : super(null);

  final DocumentService _documentService;

  /// Create new document
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
      // Error handling
      rethrow;
    }
  }

  /// Open document
  Future<void> openDocument(String id) async {
    try {
      final document = await _documentService.openDocument(id);
      state = document;
    } catch (e) {
      rethrow;
    }
  }

  /// Update document content
  void updateContent(String content) {
    if (state != null) {
      state = state!.copyWith(content: content);
    }
  }

  /// Update document title
  void updateTitle(String title) {
    if (state != null) {
      state = state!.copyWith(title: title);
    }
  }

  /// Save document
  Future<void> saveDocument() async {
    if (state != null) {
      try {
        await _documentService.saveDocument(state!);
        // Update save time
        state = state!.copyWith(
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Save as
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

  /// Import document
  Future<void> importDocument(String filePath) async {
    try {
      final document = await _documentService.importDocument(filePath);
      state = document;
    } catch (e) {
      rethrow;
    }
  }

  /// Export document
  Future<String> exportDocument(
    String exportPath, {
    ExportFormat format = ExportFormat.html,
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
    throw Exception('No document to export');
  }

  /// Set current document
  void setCurrentDocument(Document document) {
    state = document;
  }

  /// Close document
  void closeDocument() {
    state = null;
  }
}

final currentDocumentProvider = StateNotifierProvider<CurrentDocumentNotifier, Document?>((ref) {
  final documentService = ref.read(documentServiceProvider);
  return CurrentDocumentNotifier(documentService);
});

/// Document list provider
final documentListProvider = FutureProvider<List<Document>>((ref) async {
  final documentService = ref.read(documentServiceProvider);
  return await documentService.getAllDocuments();
});

/// Document list provider (alias)
final documentsListProvider = FutureProvider<List<Document>>((ref) async {
  final documentService = ref.read(documentServiceProvider);
  return await documentService.getAllDocuments();
});

/// Recent documents provider
final recentDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final documentService = ref.read(documentServiceProvider);
  return await documentService.getRecentDocuments();
});

/// Document search provider
final documentSearchProvider = FutureProvider.family<List<Document>, String>((ref, query) async {
  final documentService = ref.read(documentServiceProvider);
  return await documentService.searchDocuments(query);
});

/// Document modification status provider
final documentModifiedProvider = Provider<bool>((ref) {
  final currentDocument = ref.watch(currentDocumentProvider);
  if (currentDocument == null) return false;
  
  // Check if document is modified (simple check of update time here)
  return true; // In actual implementation, can compare content hash or other identifiers
});