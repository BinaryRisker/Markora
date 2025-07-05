import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// 应用设置实体
@HiveType(typeId: 1)
class AppSettings {
  /// 主题模式
  @HiveField(0)
  final ThemeMode themeMode;

  /// 编辑器主题
  @HiveField(1)
  final String editorTheme;

  /// 字体大小
  @HiveField(2)
  final double fontSize;

  /// 显示行号
  @HiveField(3)
  final bool showLineNumbers;

  /// 自动换行
  @HiveField(4)
  final bool wordWrap;

  /// 默认视图模式
  @HiveField(5)
  final String defaultViewMode;

  /// 自动保存
  @HiveField(6)
  final bool autoSave;

  /// 自动保存间隔（秒）
  @HiveField(7)
  final int autoSaveInterval;

  /// 实时预览
  @HiveField(8)
  final bool livePreview;

  /// 语言设置
  @HiveField(9)
  final String language;

  /// 分屏比例
  @HiveField(10)
  final double splitRatio;

  /// 启用拼写检查
  @HiveField(11)
  final bool enableSpellCheck;

  /// 启用语法检查
  @HiveField(12)
  final bool enableLinting;

  /// 自动完成
  @HiveField(13)
  final bool enableAutoComplete;

  /// Tab大小
  @HiveField(14)
  final int tabSize;

  /// 使用空格代替Tab
  @HiveField(15)
  final bool useSpacesForTab;

  const AppSettings({
    required this.themeMode,
    required this.editorTheme,
    required this.fontSize,
    required this.showLineNumbers,
    required this.wordWrap,
    required this.defaultViewMode,
    required this.autoSave,
    required this.autoSaveInterval,
    required this.livePreview,
    required this.language,
    required this.splitRatio,
    required this.enableSpellCheck,
    required this.enableLinting,
    required this.enableAutoComplete,
    required this.tabSize,
    required this.useSpacesForTab,
  });

  /// 默认设置
  factory AppSettings.defaultSettings() {
    return const AppSettings(
      themeMode: ThemeMode.system,
      editorTheme: 'VS Code Light',
      fontSize: 14.0,
      showLineNumbers: true,
      wordWrap: true,
      defaultViewMode: 'split',
      autoSave: true,
      autoSaveInterval: 30,
      livePreview: true,
      language: 'zh-CN',
      splitRatio: 0.5,
      enableSpellCheck: false,
      enableLinting: true,
      enableAutoComplete: true,
      tabSize: 2,
      useSpacesForTab: true,
    );
  }

  /// 复制并修改
  AppSettings copyWith({
    ThemeMode? themeMode,
    String? editorTheme,
    double? fontSize,
    bool? showLineNumbers,
    bool? wordWrap,
    String? defaultViewMode,
    bool? autoSave,
    int? autoSaveInterval,
    bool? livePreview,
    String? language,
    double? splitRatio,
    bool? enableSpellCheck,
    bool? enableLinting,
    bool? enableAutoComplete,
    int? tabSize,
    bool? useSpacesForTab,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      editorTheme: editorTheme ?? this.editorTheme,
      fontSize: fontSize ?? this.fontSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wordWrap: wordWrap ?? this.wordWrap,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      livePreview: livePreview ?? this.livePreview,
      language: language ?? this.language,
      splitRatio: splitRatio ?? this.splitRatio,
      enableSpellCheck: enableSpellCheck ?? this.enableSpellCheck,
      enableLinting: enableLinting ?? this.enableLinting,
      enableAutoComplete: enableAutoComplete ?? this.enableAutoComplete,
      tabSize: tabSize ?? this.tabSize,
      useSpacesForTab: useSpacesForTab ?? this.useSpacesForTab,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'editorTheme': editorTheme,
      'fontSize': fontSize,
      'showLineNumbers': showLineNumbers,
      'wordWrap': wordWrap,
      'defaultViewMode': defaultViewMode,
      'autoSave': autoSave,
      'autoSaveInterval': autoSaveInterval,
      'livePreview': livePreview,
      'language': language,
      'splitRatio': splitRatio,
      'enableSpellCheck': enableSpellCheck,
      'enableLinting': enableLinting,
      'enableAutoComplete': enableAutoComplete,
      'tabSize': tabSize,
      'useSpacesForTab': useSpacesForTab,
    };
  }

  /// 从JSON创建
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      editorTheme: json['editorTheme'] ?? 'VS Code Light',
      fontSize: (json['fontSize'] ?? 14.0).toDouble(),
      showLineNumbers: json['showLineNumbers'] ?? true,
      wordWrap: json['wordWrap'] ?? true,
      defaultViewMode: json['defaultViewMode'] ?? 'split',
      autoSave: json['autoSave'] ?? true,
      autoSaveInterval: json['autoSaveInterval'] ?? 30,
      livePreview: json['livePreview'] ?? true,
      language: json['language'] ?? 'zh-CN',
      splitRatio: (json['splitRatio'] ?? 0.5).toDouble(),
      enableSpellCheck: json['enableSpellCheck'] ?? false,
      enableLinting: json['enableLinting'] ?? true,
      enableAutoComplete: json['enableAutoComplete'] ?? true,
      tabSize: json['tabSize'] ?? 2,
      useSpacesForTab: json['useSpacesForTab'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.editorTheme == editorTheme &&
        other.fontSize == fontSize &&
        other.showLineNumbers == showLineNumbers &&
        other.wordWrap == wordWrap &&
        other.defaultViewMode == defaultViewMode &&
        other.autoSave == autoSave &&
        other.autoSaveInterval == autoSaveInterval &&
        other.livePreview == livePreview &&
        other.language == language &&
        other.splitRatio == splitRatio &&
        other.enableSpellCheck == enableSpellCheck &&
        other.enableLinting == enableLinting &&
        other.enableAutoComplete == enableAutoComplete &&
        other.tabSize == tabSize &&
        other.useSpacesForTab == useSpacesForTab;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      editorTheme,
      fontSize,
      showLineNumbers,
      wordWrap,
      defaultViewMode,
      autoSave,
      autoSaveInterval,
      livePreview,
      language,
      splitRatio,
      enableSpellCheck,
      enableLinting,
      enableAutoComplete,
      tabSize,
      useSpacesForTab,
    );
  }

  @override
  String toString() {
    return 'AppSettings('
        'themeMode: $themeMode, '
        'editorTheme: $editorTheme, '
        'fontSize: $fontSize, '
        'showLineNumbers: $showLineNumbers, '
        'wordWrap: $wordWrap, '
        'defaultViewMode: $defaultViewMode, '
        'autoSave: $autoSave, '
        'autoSaveInterval: $autoSaveInterval, '
        'livePreview: $livePreview, '
        'language: $language, '
        'splitRatio: $splitRatio, '
        'enableSpellCheck: $enableSpellCheck, '
        'enableLinting: $enableLinting, '
        'enableAutoComplete: $enableAutoComplete, '
        'tabSize: $tabSize, '
        'useSpacesForTab: $useSpacesForTab'
        ')';
  }
}

/// ThemeMode的Hive适配器
class ThemeModeAdapter extends TypeAdapter<ThemeMode> {
  @override
  final int typeId = 2;

  @override
  ThemeMode read(BinaryReader reader) {
    final index = reader.readByte();
    return ThemeMode.values[index];
  }

  @override
  void write(BinaryWriter writer, ThemeMode obj) {
    writer.writeByte(obj.index);
  }
} 