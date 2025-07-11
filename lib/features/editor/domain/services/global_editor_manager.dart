import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'undo_redo_manager.dart';

/// Global undo/redo state
class GlobalUndoRedoState {
  final bool canUndo;
  final bool canRedo;
  
  const GlobalUndoRedoState({
    required this.canUndo,
    required this.canRedo,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlobalUndoRedoState &&
        other.canUndo == canUndo &&
        other.canRedo == canRedo;
  }
  
  @override
  int get hashCode => canUndo.hashCode ^ canRedo.hashCode;
}

/// Global editor manager
/// Manages editor instances and undo/redo state for multiple tabs
class GlobalEditorManager extends ChangeNotifier {
  // Store undo/redo managers for each tab
  final Map<String, UndoRedoManager> _undoRedoManagers = {};
  
  // Store undo/redo callbacks for each tab
  final Map<String, VoidCallback> _undoCallbacks = {};
  final Map<String, VoidCallback> _redoCallbacks = {};
  
  // Current active tab ID
  String? _activeTabId;
  
  /// Register editor for tab
  void registerEditor({
    required String tabId,
    required UndoRedoManager undoRedoManager,
    required VoidCallback undoCallback,
    required VoidCallback redoCallback,
  }) {
    _undoRedoManagers[tabId] = undoRedoManager;
    _undoCallbacks[tabId] = undoCallback;
    _redoCallbacks[tabId] = redoCallback;
  }
  
  /// Unregister editor for tab
  void unregisterEditor(String tabId) {
    _undoRedoManagers.remove(tabId);
    _undoCallbacks.remove(tabId);
    _redoCallbacks.remove(tabId);
    
    // If unregistering the current active tab, clear active state
    if (_activeTabId == tabId) {
      _activeTabId = null;
    }
  }
  
  /// Set active tab
  void setActiveTab(String tabId) {
    _activeTabId = tabId;
    notifyListeners();
  }
  
  /// Get current undo/redo state
  GlobalUndoRedoState getCurrentState() {
    if (_activeTabId == null || !_undoRedoManagers.containsKey(_activeTabId)) {
      return const GlobalUndoRedoState(canUndo: false, canRedo: false);
    }
    
    final manager = _undoRedoManagers[_activeTabId]!;
    return GlobalUndoRedoState(
      canUndo: manager.canUndo,
      canRedo: manager.canRedo,
    );
  }
  
  /// Get undo/redo manager for current active tab
  UndoRedoManager? get activeUndoRedoManager {
    if (_activeTabId == null) return null;
    return _undoRedoManagers[_activeTabId];
  }
  
  /// Whether current can undo
  bool get canUndo {
    final manager = activeUndoRedoManager;
    return manager?.canUndo ?? false;
  }
  
  /// Whether current can redo
  bool get canRedo {
    final manager = activeUndoRedoManager;
    return manager?.canRedo ?? false;
  }
  
  /// Execute undo operation
  void undo() {
    if (_activeTabId != null && _undoCallbacks.containsKey(_activeTabId)) {
      _undoCallbacks[_activeTabId]!();
      notifyListeners();
    }
  }
  
  /// Execute redo operation
  void redo() {
    if (_activeTabId != null && _redoCallbacks.containsKey(_activeTabId)) {
      _redoCallbacks[_activeTabId]!();
      notifyListeners();
    }
  }
  
  /// Notify content change (for updating undo/redo state)
  void notifyContentChanged(String tabId, String text, TextSelection selection) {
    // This method is mainly used to trigger state updates, actual content changes are handled by respective editors
    // Notify listeners that state may have changed
    if (tabId == _activeTabId) {
      notifyListeners();
    }
  }
  
  /// Clear all editors
  void clear() {
    _undoRedoManagers.clear();
    _undoCallbacks.clear();
    _redoCallbacks.clear();
    _activeTabId = null;
  }
  
  /// Get debug information
  String getDebugInfo() {
    return 'GlobalEditorManager: ${_undoRedoManagers.length} editors, '
           'active: $_activeTabId, canUndo: $canUndo, canRedo: $canRedo';
  }
}

/// Global editor manager provider
final globalEditorManagerProvider = ChangeNotifierProvider<GlobalEditorManager>((ref) {
  return GlobalEditorManager();
});

/// Global undo/redo state provider
final globalUndoRedoStateProvider = Provider<GlobalUndoRedoState>((ref) {
  final manager = ref.watch(globalEditorManagerProvider);
  return manager.getCurrentState();
});