/// Markora应用常量定义
class AppConstants {
  // 阻止实例化
  AppConstants._();

  /// 应用信息
  static const String appName = 'Markora';
  static const String version = '1.0.0';
  static const String appVersion = '1.0.0';
  static const String appDescription = '下一代跨平台 Markdown 编辑器';
  
  /// 支持的文件扩展名
  static const List<String> supportedExtensions = [
    'md',
    'markdown',
    'txt',
    'mdnb', // Markora笔记本格式
  ];
  
  /// 默认文件名
  static const String defaultFileName = '未命名文档';
  static const String defaultFileExtension = 'md';
  
  /// 存储键名
  static const String keyEditorConfig = 'editor_config';
  static const String keyAppSettings = 'app_settings';
  static const String keyRecentFiles = 'recent_files';
  static const String keyPluginConfigs = 'plugin_configs';
  static const String keyThemeSettings = 'theme_settings';
  
  /// 限制值
  static const int maxRecentFiles = 10;
  static const int maxDocumentSize = 100 * 1024 * 1024; // 100MB
  static const int autoSaveIntervalMin = 10; // 秒
  static const int autoSaveIntervalMax = 300; // 秒
  
  /// UI常量
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;
  static const double defaultSplitRatio = 0.5;
  static const double toolbarHeight = 48.0;
  static const double statusBarHeight = 24.0;
  
  /// 字体设置
  static const List<String> availableFonts = [
    'monospace',
    'Consolas',
    'Courier New',
    'Monaco',
    'Menlo',
  ];
  
  /// 主题设置
  static const List<String> availableThemes = [
    'light',
    'dark',
    'auto',
  ];
  
  /// 编辑器配置默认值
  static const double defaultFontSize = 14.0;
  static const String defaultFontFamily = 'monospace';
  static const double defaultLineHeight = 1.5;
  static const int defaultTabSize = 2;
  
  /// 插件相关
  static const String pluginDirectory = 'plugins';
  static const String themeDirectory = 'themes';
  static const String templatesDirectory = 'templates';
  
  /// 网络配置
  static const int networkTimeoutSeconds = 30;
  static const String pluginRegistryUrl = 'https://plugins.markora.com';
  
  /// 正则表达式
  static const String markdownHeadingPattern = r'^#{1,6}\s+(.+)$';
  static const String markdownLinkPattern = r'\[([^\]]+)\]\(([^)]+)\)';
  static const String markdownImagePattern = r'!\[([^\]]*)\]\(([^)]+)\)';
  static const String markdownCodeBlockPattern = r'```(\w+)?\n([\s\S]+?)\n```';
  
  /// 数学公式
  static const String mathInlinePattern = r'\$([^$]+)\$';
  static const String mathBlockPattern = r'\$\$\n([\s\S]+?)\n\$\$';
  
  /// Mermaid图表
  static const String mermaidBlockPattern = r'```mermaid\n([\s\S]+?)\n```';
  
  /// 导出格式
  static const List<String> exportFormats = [
    'pdf',
    'html',
    'docx',
    'png',
    'jpeg',
  ];
} 