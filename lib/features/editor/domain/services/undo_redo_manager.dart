import 'package:flutter/material.dart';

/// 编辑器历史状态
class EditorHistoryState {
  const EditorHistoryState({
    required this.text,
    required this.selection,
    required this.timestamp,
  });

  final String text;
  final TextSelection selection;
  final DateTime timestamp;

  EditorHistoryState copyWith({
    String? text,
    TextSelection? selection,
    DateTime? timestamp,
  }) {
    return EditorHistoryState(
      text: text ?? this.text,
      selection: selection ?? this.selection,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditorHistoryState &&
        other.text == text &&
        other.selection == selection;
  }

  @override
  int get hashCode => text.hashCode ^ selection.hashCode;
}

/// 撤销/重做管理器
class UndoRedoManager {
  UndoRedoManager({
    this.maxHistoryLength = 100,
    Duration? mergeTimeThreshold,
  }) : mergeTimeThreshold = mergeTimeThreshold ?? const Duration(seconds: 1);

  /// 最大历史记录长度
  final int maxHistoryLength;
  
  /// 合并操作的时间阈值
  final Duration mergeTimeThreshold;

  /// 历史记录栈
  final List<EditorHistoryState> _history = [];
  
  /// 当前位置
  int _currentIndex = -1;
  
  /// 是否正在应用撤销/重做操作
  bool _isApplying = false;

  /// 当前是否可以撤销
  bool get canUndo => _currentIndex > 0;

  /// 当前是否可以重做
  bool get canRedo => _currentIndex < _history.length - 1;

  /// 当前状态
  EditorHistoryState? get currentState => 
      _currentIndex >= 0 && _currentIndex < _history.length 
          ? _history[_currentIndex] 
          : null;

  /// 历史记录数量
  int get historyLength => _history.length;

  /// 添加新状态
  void addState(EditorHistoryState state) {
    if (_isApplying) return;

    // 检查是否应该合并操作
    if (_shouldMergeWithPrevious(state)) {
      _mergeWithPrevious(state);
      return;
    }

    // 如果当前位置不在末尾，删除后面的历史记录
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // 添加新状态
    _history.add(state);
    _currentIndex = _history.length - 1;

    // 限制历史记录长度
    if (_history.length > maxHistoryLength) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  /// 撤销操作
  EditorHistoryState? undo() {
    if (!canUndo) return null;

    _currentIndex--;
    _isApplying = true;
    
    final state = _history[_currentIndex];
    
    // 延迟重置标志，避免在应用状态时触发新的历史记录
    Future.microtask(() => _isApplying = false);
    
    return state;
  }

  /// 重做操作
  EditorHistoryState? redo() {
    if (!canRedo) return null;

    _currentIndex++;
    _isApplying = true;
    
    final state = _history[_currentIndex];
    
    // 延迟重置标志，避免在应用状态时触发新的历史记录
    Future.microtask(() => _isApplying = false);
    
    return state;
  }

  /// 清空历史记录
  void clear() {
    _history.clear();
    _currentIndex = -1;
  }

  /// 检查是否应该与前一个状态合并
  bool _shouldMergeWithPrevious(EditorHistoryState state) {
    if (_history.isEmpty || _currentIndex < 0) return false;

    final previous = _history[_currentIndex];
    
    // 检查时间间隔
    final timeDiff = state.timestamp.difference(previous.timestamp);
    if (timeDiff > mergeTimeThreshold) return false;

    // 检查文本变化是否为单字符编辑
    return _isSingleCharacterEdit(previous.text, state.text);
  }

  /// 检查是否为单字符编辑
  bool _isSingleCharacterEdit(String oldText, String newText) {
    final lengthDiff = (newText.length - oldText.length).abs();
    
    // 只有单字符差异才考虑合并
    if (lengthDiff != 1) return false;

    // 检查是否为简单的插入或删除
    if (newText.length > oldText.length) {
      // 插入字符
      return newText.contains(oldText);
    } else {
      // 删除字符
      return oldText.contains(newText);
    }
  }

  /// 与前一个状态合并
  void _mergeWithPrevious(EditorHistoryState state) {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      _history[_currentIndex] = state;
    }
  }

  /// 获取调试信息
  String getDebugInfo() {
    return 'UndoRedoManager: ${_history.length} states, current: $_currentIndex, '
           'canUndo: $canUndo, canRedo: $canRedo';
  }
} 