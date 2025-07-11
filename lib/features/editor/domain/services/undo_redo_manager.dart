import 'package:flutter/material.dart';

/// Editor history state
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

/// Undo/redo manager
class UndoRedoManager {
  UndoRedoManager({
    this.maxHistoryLength = 100,
    Duration? mergeTimeThreshold,
  }) : mergeTimeThreshold = mergeTimeThreshold ?? const Duration(seconds: 1);

  /// Maximum history length
  final int maxHistoryLength;
  
  /// Time threshold for merging operations
  final Duration mergeTimeThreshold;

  /// History stack
  final List<EditorHistoryState> _history = [];
  
  /// Current position
  int _currentIndex = -1;
  
  /// Whether applying undo/redo operation
  bool _isApplying = false;

  /// Whether can undo currently
  bool get canUndo => _currentIndex > 0;

  /// Whether can redo currently
  bool get canRedo => _currentIndex < _history.length - 1;

  /// Current state
  EditorHistoryState? get currentState => 
      _currentIndex >= 0 && _currentIndex < _history.length 
          ? _history[_currentIndex] 
          : null;

  /// History count
  int get historyLength => _history.length;

  /// Add new state
  void addState(EditorHistoryState state) {
    if (_isApplying) return;

    // Check if operations should be merged
    if (_shouldMergeWithPrevious(state)) {
      _mergeWithPrevious(state);
      return;
    }

    // If current position is not at the end, remove subsequent history
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Add new state
    _history.add(state);
    _currentIndex = _history.length - 1;

    // Limit history length
    if (_history.length > maxHistoryLength) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  /// Undo operation
  EditorHistoryState? undo() {
    if (!canUndo) return null;

    _currentIndex--;
    _isApplying = true;
    
    final state = _history[_currentIndex];
    
    // Delay resetting flag to avoid triggering new history when applying state
    Future.microtask(() => _isApplying = false);
    
    return state;
  }

  /// Redo operation
  EditorHistoryState? redo() {
    if (!canRedo) return null;

    _currentIndex++;
    _isApplying = true;
    
    final state = _history[_currentIndex];
    
    // Delay resetting flag to avoid triggering new history when applying state
    Future.microtask(() => _isApplying = false);
    
    return state;
  }

  /// Clear history
  void clear() {
    _history.clear();
    _currentIndex = -1;
  }

  /// Check if should merge with previous state
  bool _shouldMergeWithPrevious(EditorHistoryState state) {
    if (_history.isEmpty || _currentIndex < 0) return false;

    final previous = _history[_currentIndex];
    
    // Check time interval
    final timeDiff = state.timestamp.difference(previous.timestamp);
    if (timeDiff > mergeTimeThreshold) return false;

    // Check if text change is single character edit
    return _isSingleCharacterEdit(previous.text, state.text);
  }

  /// Check if is single character edit
  bool _isSingleCharacterEdit(String oldText, String newText) {
    final lengthDiff = (newText.length - oldText.length).abs();
    
    // Only consider merging for single character difference
    if (lengthDiff != 1) return false;

    // Check if is simple insertion or deletion
    if (newText.length > oldText.length) {
      // Insert character
      return newText.contains(oldText);
    } else {
      // Delete character
      return oldText.contains(newText);
    }
  }

  /// Merge with previous state
  void _mergeWithPrevious(EditorHistoryState state) {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      _history[_currentIndex] = state;
    }
  }

  /// Get debug information
  String getDebugInfo() {
    return 'UndoRedoManager: ${_history.length} states, current: $_currentIndex, '
           'canUndo: $canUndo, canRedo: $canRedo';
  }
}