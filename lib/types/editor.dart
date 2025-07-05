import 'package:equatable/equatable.dart';

/// 编辑器模式枚举
enum EditorMode {
  /// 源码编辑模式
  source('源码模式'),
  /// 预览模式
  preview('预览模式'),
  /// 分屏模式（编辑+预览）
  split('分屏模式'),
  /// 实时渲染模式（类似Typora）
  live('实时渲染');

  const EditorMode(this.displayName);
  final String displayName;
}

/// 光标位置信息
class CursorPosition extends Equatable {
  const CursorPosition({
    required this.line,
    required this.column,
    required this.offset,
  });

  /// 行号（从0开始）
  final int line;
  
  /// 列号（从0开始）
  final int column;
  
  /// 字符偏移量
  final int offset;

  @override
  List<Object> get props => [line, column, offset];
}

/// 文本选择范围
class EditorTextSelection extends Equatable {
  const EditorTextSelection({
    required this.start,
    required this.end,
  });

  /// 选择开始位置
  final CursorPosition start;
  
  /// 选择结束位置
  final CursorPosition end;

  /// 是否为空选择（光标位置）
  bool get isEmpty => start == end;

  @override
  List<Object> get props => [start, end];
}

/// 编辑器配置
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

  /// 字体大小
  final double fontSize;
  
  /// 字体族
  final String fontFamily;
  
  /// 行高
  final double lineHeight;
  
  /// Tab大小
  final int tabSize;
  
  /// 自动换行
  final bool wordWrap;
  
  /// 显示行号
  final bool showLineNumbers;
  
  /// 显示不可见字符
  final bool showInvisibles;
  
  /// 启用自动保存
  final bool enableAutoSave;
  
  /// 自动保存间隔（秒）
  final int autoSaveInterval;
  
  /// 启用拼写检查
  final bool enableSpellCheck;
  
  /// 启用语法高亮
  final bool enableSyntaxHighlight;
  
  /// 启用代码折叠
  final bool enableCodeFolding;
  
  /// 启用括号匹配
  final bool enableBracketMatching;
  
  /// 启用自动缩进
  final bool enableAutoIndent;
  
  /// 启用自动补全
  final bool enableAutoCompletion;
  
  /// 主题名称
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

/// 编辑器状态
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

  /// 当前编辑模式
  final EditorMode mode;
  
  /// 光标位置
  final CursorPosition cursorPosition;
  
  /// 选择范围
  final EditorTextSelection? selection;
  
  /// 是否已修改
  final bool isModified;
  
  /// 是否只读
  final bool isReadOnly;
  
  /// 是否可以撤销
  final bool canUndo;
  
  /// 是否可以重做
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