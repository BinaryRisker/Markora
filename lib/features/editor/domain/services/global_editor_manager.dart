import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'undo_redo_manager.dart';

/// 全局撤销重做状态
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

/// 全局编辑器管理器
/// 管理多个标签页的编辑器实例和撤销重做状态
class GlobalEditorManager extends ChangeNotifier {
  // 存储每个标签页的撤销重做管理器
  final Map<String, UndoRedoManager> _undoRedoManagers = {};
  
  // 存储每个标签页的撤销重做回调
  final Map<String, VoidCallback> _undoCallbacks = {};
  final Map<String, VoidCallback> _redoCallbacks = {};
  
  // 当前活跃的标签页ID
  String? _activeTabId;
  
  /// 注册标签页的编辑器
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
  
  /// 注销标签页的编辑器
  void unregisterEditor(String tabId) {
    _undoRedoManagers.remove(tabId);
    _undoCallbacks.remove(tabId);
    _redoCallbacks.remove(tabId);
    
    // 如果注销的是当前活跃标签页，清除活跃状态
    if (_activeTabId == tabId) {
      _activeTabId = null;
    }
  }
  
  /// 设置活跃标签页
  void setActiveTab(String tabId) {
    _activeTabId = tabId;
    notifyListeners();
  }
  
  /// 获取当前撤销重做状态
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
  
  /// 获取当前活跃标签页的撤销重做管理器
  UndoRedoManager? get activeUndoRedoManager {
    if (_activeTabId == null) return null;
    return _undoRedoManagers[_activeTabId];
  }
  
  /// 当前是否可以撤销
  bool get canUndo {
    final manager = activeUndoRedoManager;
    return manager?.canUndo ?? false;
  }
  
  /// 当前是否可以重做
  bool get canRedo {
    final manager = activeUndoRedoManager;
    return manager?.canRedo ?? false;
  }
  
  /// 执行撤销操作
  void undo() {
    if (_activeTabId != null && _undoCallbacks.containsKey(_activeTabId)) {
      _undoCallbacks[_activeTabId]!();
      notifyListeners();
    }
  }
  
  /// 执行重做操作
  void redo() {
    if (_activeTabId != null && _redoCallbacks.containsKey(_activeTabId)) {
      _redoCallbacks[_activeTabId]!();
      notifyListeners();
    }
  }
  
  /// 通知内容变化（用于更新撤销重做状态）
  void notifyContentChanged(String tabId, String text, TextSelection selection) {
    // 这个方法主要用于触发状态更新，实际的内容变化由各自的编辑器处理
    // 通知监听器状态可能已经改变
    if (tabId == _activeTabId) {
      notifyListeners();
    }
  }
  
  /// 清除所有编辑器
  void clear() {
    _undoRedoManagers.clear();
    _undoCallbacks.clear();
    _redoCallbacks.clear();
    _activeTabId = null;
  }
  
  /// 获取调试信息
  String getDebugInfo() {
    return 'GlobalEditorManager: ${_undoRedoManagers.length} editors, '
           'active: $_activeTabId, canUndo: $canUndo, canRedo: $canRedo';
  }
}

/// 全局编辑器管理器提供者
final globalEditorManagerProvider = ChangeNotifierProvider<GlobalEditorManager>((ref) {
  return GlobalEditorManager();
});

/// 全局撤销重做状态提供者
final globalUndoRedoStateProvider = Provider<GlobalUndoRedoState>((ref) {
  final manager = ref.watch(globalEditorManagerProvider);
  return manager.getCurrentState();
});