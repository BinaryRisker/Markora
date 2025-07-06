import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// Application settings entity
@HiveType(typeId: 1)
class AppSettings {
  /// Theme mode
  @HiveField(0)
  final ThemeMode themeMode;

  /// Editor theme
  @HiveField(1)
  final String editorTheme;

  /// Font size
  @HiveField(2)
  final double fontSize;

  /// Show line numbers
  @HiveField(3)
  final bool showLineNumbers;

  /// Word wrap
  @HiveField(4)
  final bool wordWrap;

  /// Default view mode
  @HiveField(5)
  final String defaultViewMode;

  /// Auto save
  @HiveField(6)
  final bool autoSave;

  /// Auto save interval (seconds)
  @HiveField(7)
  final int autoSaveInterval;

  /// Live preview
  @HiveField(8)
  final bool livePreview;

  /// Language setting
  @HiveField(9)
  final String language;

  /// Split ratio
  @HiveField(10)
  final double splitRatio;

  /// Enable spell check
  @HiveField(11)
  final bool enableSpellCheck;

  /// Enable syntax check
  @HiveField(12)
  final bool enableLinting;

  /// Auto complete
  @HiveField(13)
  final bool enableAutoComplete;

  /// Tab size
  @HiveField(14)
  final int tabSize;

  /// Use spaces instead of tabs
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

  /// Default settings
  factory AppSettings.defaultSettings() {
    // Detect system language, default to Chinese if system is Chinese, otherwise English
    String defaultLanguage = 'zh'; // Default to Chinese
    try {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (systemLocale.languageCode == 'zh') {
        defaultLanguage = 'zh';
      } else {
        defaultLanguage = 'en';
      }
    } catch (e) {
      // If detection fails, use Chinese as default
      defaultLanguage = 'zh';
    }
    
    return AppSettings(
      themeMode: ThemeMode.system,
      editorTheme: 'VS Code Light',
      fontSize: 14.0,
      showLineNumbers: true,
      wordWrap: true,
      defaultViewMode: 'split',
      autoSave: true,
      autoSaveInterval: 30,
      livePreview: true,
      language: defaultLanguage,
      splitRatio: 0.5,
      enableSpellCheck: false,
      enableLinting: true,
      enableAutoComplete: true,
      tabSize: 2,
      useSpacesForTab: true,
    );
  }

  /// Copy with modifications
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

  /// Convert to JSON
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

  /// Create from JSON
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
      language: json['language'] ?? 'en',
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

/// Hive adapter for ThemeMode
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