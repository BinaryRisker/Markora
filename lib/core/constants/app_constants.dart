/// Markora application constants definition
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  /// Application information
  static const String appName = 'Markora';
  static const String version = '1.0.0';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Next-Generation Cross-Platform Markdown Editor';
  
  /// Supported file extensions
  static const List<String> supportedExtensions = [
    'md',
    'markdown',
    'txt',
    'mdnb', // Markora notebook format
  ];
  
  /// Default file name
  static const String defaultFileName = 'Untitled Document';
  static const String defaultFileExtension = 'md';
  
  /// Storage key names
  static const String keyEditorConfig = 'editor_config';
  static const String keyAppSettings = 'app_settings';
  static const String keyRecentFiles = 'recent_files';
  static const String keyPluginConfigs = 'plugin_configs';
  static const String keyThemeSettings = 'theme_settings';
  
  /// Limit values
  static const int maxRecentFiles = 10;
  static const int maxDocumentSize = 100 * 1024 * 1024; // 100MB
  static const int autoSaveIntervalMin = 10; // seconds
  static const int autoSaveIntervalMax = 300; // seconds
  
  /// UI constants
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;
  static const double defaultSplitRatio = 0.5;
  static const double toolbarHeight = 48.0;
  static const double statusBarHeight = 24.0;
  
  /// Font settings
  static const List<String> availableFonts = [
    // Monospace fonts (for programming)
    'monospace',
    'Consolas',
    'Courier New',
    'Monaco',
    'Menlo',
    'Source Code Pro',
    'Fira Code',
    'JetBrains Mono',
    
    // Chinese fonts
    'Microsoft YaHei',
    'SimHei',
    'SimSun',
    'KaiTi',
    'FangSong',
    'Microsoft JhengHei',
    'PingFang SC',
    'Hiragino Sans GB',
    'STHeiti',
    'STSong',
    'STKaiti',
    'STFangsong',
    'Noto Sans CJK SC',
    'Source Han Sans CN',
    
    // Western fonts
    'Times New Roman',
    'Arial',
    'Helvetica',
    'Georgia',
    'Verdana',
    'Calibri',
    'Cambria',
    'Comic Sans MS',
    'Impact',
    'Trebuchet MS',
  ];
  
  /// Theme settings
  static const List<String> availableThemes = [
    'light',
    'dark',
    'auto',
  ];
  
  /// Editor configuration default values
  static const double defaultFontSize = 14.0;
  static const String defaultFontFamily = 'monospace';
  static const double defaultLineHeight = 1.5;
  static const int defaultTabSize = 2;
  
  /// Plugin related
  static const String pluginDirectory = 'plugins';
  static const String themeDirectory = 'themes';
  static const String templatesDirectory = 'templates';
  
  /// Network configuration
  static const int networkTimeoutSeconds = 30;
  static const String pluginRegistryUrl = 'https://plugins.markora.com';
  
  /// Regular expressions
  static const String markdownHeadingPattern = r'^#{1,6}\s+(.+)$';
  static const String markdownLinkPattern = r'\[([^\]]+)\]\(([^)]+)\)';
  static const String markdownImagePattern = r'!\[([^\]]*)\]\(([^)]+)\)';
  static const String markdownCodeBlockPattern = r'```(\w+)?\n([\s\S]+?)\n```';
  
  /// Math formulas
  static const String mathInlinePattern = r'\$([^$]+)\$';
  static const String mathBlockPattern = r'\$\$\n([\s\S]+?)\n\$\$';
  
  /// Mermaid charts
  static const String mermaidBlockPattern = r'```mermaid\n([\s\S]+?)\n```';
  
  /// Export formats
  static const List<String> exportFormats = [
    'pdf',
    'html',
    'docx',
    'png',
    'jpeg',
  ];
}