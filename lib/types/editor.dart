import 'package:equatable/equatable.dart';

/// Editor mode enumeration
enum EditorMode {
  /// Source code editing mode
  source('Source Mode'),
  /// Preview mode
  preview('Preview Mode'),
  /// Split mode (edit + preview)
  split('Split Mode'),
  /// Live rendering mode (similar to Typora)
  live('Live Rendering');

  const EditorMode(this.displayName);
  final String displayName;
}

/// Cursor position information
class CursorPosition extends Equatable {
  const CursorPosition({
    required this.line,
    required this.column,
    required this.offset,
  });

  /// Line number (starting from 0)
  final int line;
  
  /// Column number (starting from 0)
  final int column;
  
  /// Character offset
  final int offset;

  @override
  List<Object> get props => [line, column, offset];
}

/// Text selection range
class EditorTextSelection extends Equatable {
  const EditorTextSelection({
    required this.start,
    required this.end,
  });

  /// Selection start position
  final CursorPosition start;
  
  /// Selection end position
  final CursorPosition end;

  /// Whether it's an empty selection (cursor position)
  bool get isEmpty => start == end;

  @override
  List<Object> get props => [start, end];
}

/// Editor configuration
class EditorConfig extends Equatable {
  const EditorConfig({
    this.fontSize = 14.0,
    this.fontFamily = 'monospace',
    this.lineHeight = 1.5,
    this.tabSize = 2,
    this.wordWrap = true,
    this.showLineNumbers = true,
    this.showInvisibles = false,
    this.enableAutoSave = true,
    this.autoSaveInterval = 30,
    this.enableSpellCheck = true,
    this.enableSyntaxHighlight = true,
    this.enableCodeFolding = true,
    this.enableBracketMatching = true,
    this.enableAutoIndent = true,
    this.enableAutoCompletion = true,
    this.theme = 'default',
  });

  /// Font size
  final double fontSize;
  
  /// Font family
  final String fontFamily;
  
  /// Line height
  final double lineHeight;
  
  /// Tab size
  final int tabSize;
  
  /// Word wrap
  final bool wordWrap;
  
  /// Show line numbers
  final bool showLineNumbers;
  
  /// Show invisible characters
  final bool showInvisibles;
  
  /// Enable auto save
  final bool enableAutoSave;
  
  /// Auto save interval (seconds)
  final int autoSaveInterval;
  
  /// Enable spell check
  final bool enableSpellCheck;
  
  /// Enable syntax highlighting
  final bool enableSyntaxHighlight;
  
  /// Enable code folding
  final bool enableCodeFolding;
  
  /// Enable bracket matching
  final bool enableBracketMatching;
  
  /// Enable auto indent
  final bool enableAutoIndent;
  
  /// Enable auto completion
  final bool enableAutoCompletion;
  
  /// Theme name
  final String theme;

  EditorConfig copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    int? tabSize,
    bool? wordWrap,
    bool? showLineNumbers,
    bool? showInvisibles,
    bool? enableAutoSave,
    int? autoSaveInterval,
    bool? enableSpellCheck,
    bool? enableSyntaxHighlight,
    bool? enableCodeFolding,
    bool? enableBracketMatching,
    bool? enableAutoIndent,
    bool? enableAutoCompletion,
    String? theme,
  }) {
    return EditorConfig(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      tabSize: tabSize ?? this.tabSize,
      wordWrap: wordWrap ?? this.wordWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      showInvisibles: showInvisibles ?? this.showInvisibles,
      enableAutoSave: enableAutoSave ?? this.enableAutoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      enableSpellCheck: enableSpellCheck ?? this.enableSpellCheck,
      enableSyntaxHighlight: enableSyntaxHighlight ?? this.enableSyntaxHighlight,
      enableCodeFolding: enableCodeFolding ?? this.enableCodeFolding,
      enableBracketMatching: enableBracketMatching ?? this.enableBracketMatching,
      enableAutoIndent: enableAutoIndent ?? this.enableAutoIndent,
      enableAutoCompletion: enableAutoCompletion ?? this.enableAutoCompletion,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object> get props => [
        fontSize,
        fontFamily,
        lineHeight,
        tabSize,
        wordWrap,
        showLineNumbers,
        showInvisibles,
        enableAutoSave,
        autoSaveInterval,
        enableSpellCheck,
        enableSyntaxHighlight,
        enableCodeFolding,
        enableBracketMatching,
        enableAutoIndent,
        enableAutoCompletion,
        theme,
      ];
}

/// Editor state
class EditorState extends Equatable {
  const EditorState({
    required this.mode,
    required this.cursorPosition,
    this.selection,
    this.isModified = false,
    this.isReadOnly = false,
    this.canUndo = false,
    this.canRedo = false,
  });

  /// Current editing mode
  final EditorMode mode;
  
  /// Cursor position
  final CursorPosition cursorPosition;
  
  /// Selection range
  final EditorTextSelection? selection;
  
  /// Whether modified
  final bool isModified;
  
  /// Whether read-only
  final bool isReadOnly;
  
  /// Whether can undo
  final bool canUndo;
  
  /// Whether can redo
  final bool canRedo;

  EditorState copyWith({
    EditorMode? mode,
    CursorPosition? cursorPosition,
    EditorTextSelection? selection,
    bool? isModified,
    bool? isReadOnly,
    bool? canUndo,
    bool? canRedo,
  }) {
    return EditorState(
      mode: mode ?? this.mode,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      selection: selection ?? this.selection,
      isModified: isModified ?? this.isModified,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        cursorPosition,
        selection,
        isModified,
        isReadOnly,
        canUndo,
        canRedo,
      ];
}