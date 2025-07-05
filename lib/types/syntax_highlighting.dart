/// 语法高亮相关类型定义

/// 支持的编程语言
enum ProgrammingLanguage {
  dart('Dart', ['dart', 'dt']),
  javascript('JavaScript', ['js', 'javascript', 'jsx']),
  typescript('TypeScript', ['ts', 'typescript', 'tsx']),
  python('Python', ['py', 'python']),
  java('Java', ['java']),
  kotlin('Kotlin', ['kt', 'kotlin']),
  swift('Swift', ['swift']),
  cpp('C++', ['cpp', 'c++', 'cxx', 'cc']),
  c('C', ['c']),
  csharp('C#', ['cs', 'csharp']),
  go('Go', ['go']),
  rust('Rust', ['rs', 'rust']),
  php('PHP', ['php']),
  ruby('Ruby', ['rb', 'ruby']),
  html('HTML', ['html', 'htm']),
  css('CSS', ['css']),
  scss('SCSS', ['scss']),
  sass('Sass', ['sass']),
  xml('XML', ['xml']),
  json('JSON', ['json']),
  yaml('YAML', ['yaml', 'yml']),
  markdown('Markdown', ['md', 'markdown']),
  sql('SQL', ['sql']),
  bash('Bash', ['sh', 'bash']),
  powershell('PowerShell', ['ps1', 'powershell']),
  dockerfile('Dockerfile', ['dockerfile']),
  plain('Plain Text', ['txt', 'text', 'plain']);

  const ProgrammingLanguage(this.displayName, this.extensions);

  /// 显示名称
  final String displayName;
  
  /// 文件扩展名列表
  final List<String> extensions;

  /// 根据扩展名或语言标识符获取语言类型
  static ProgrammingLanguage? fromIdentifier(String? identifier) {
    if (identifier == null || identifier.isEmpty) return null;
    
    final lowercaseId = identifier.toLowerCase();
    
    for (final lang in ProgrammingLanguage.values) {
      if (lang.extensions.contains(lowercaseId)) {
        return lang;
      }
    }
    
    return null;
  }
}

/// 语法元素类型
enum SyntaxElementType {
  keyword,      // 关键字
  string,       // 字符串
  comment,      // 注释
  number,       // 数字
  operator,     // 操作符
  function,     // 函数名
  variable,     // 变量名
  type,         // 类型名
  punctuation,  // 标点符号
  annotation,   // 注解
  property,     // 属性
  constant,     // 常量
  parameter,    // 参数
  namespace,    // 命名空间
  tag,          // HTML标签
  attribute,    // HTML属性
  selector,     // CSS选择器
  regex,        // 正则表达式
  escape,       // 转义字符
  plain,        // 普通文本
}

/// 语法元素
class SyntaxElement {
  const SyntaxElement({
    required this.type,
    required this.text,
    required this.startIndex,
    required this.endIndex,
  });

  /// 元素类型
  final SyntaxElementType type;
  
  /// 文本内容
  final String text;
  
  /// 开始位置
  final int startIndex;
  
  /// 结束位置
  final int endIndex;

  @override
  String toString() {
    return 'SyntaxElement(type: $type, text: $text, range: $startIndex-$endIndex)';
  }
}

/// 语法高亮规则
class SyntaxRule {
  const SyntaxRule({
    required this.pattern,
    required this.elementType,
    this.priority = 0,
    this.isMultiLine = false,
  });

  /// 正则表达式模式
  final RegExp pattern;
  
  /// 对应的语法元素类型
  final SyntaxElementType elementType;
  
  /// 优先级（数字越大优先级越高）
  final int priority;
  
  /// 是否支持多行匹配
  final bool isMultiLine;
}

/// 语法高亮主题
class SyntaxHighlightTheme {
  const SyntaxHighlightTheme({
    required this.name,
    required this.isDark,
    required this.elementStyles,
    required this.backgroundColor,
    required this.defaultTextColor,
  });

  /// 主题名称
  final String name;
  
  /// 是否为深色主题
  final bool isDark;
  
  /// 各语法元素的样式
  final Map<SyntaxElementType, SyntaxElementStyle> elementStyles;
  
  /// 背景颜色
  final int backgroundColor;
  
  /// 默认文本颜色
  final int defaultTextColor;
}

/// 语法元素样式
class SyntaxElementStyle {
  const SyntaxElementStyle({
    required this.color,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.backgroundColor,
  });

  /// 文字颜色
  final int color;
  
  /// 是否粗体
  final bool isBold;
  
  /// 是否斜体
  final bool isItalic;
  
  /// 是否下划线
  final bool isUnderlined;
  
  /// 背景颜色（可选）
  final int? backgroundColor;
}

/// 代码块信息
class CodeBlock {
  const CodeBlock({
    required this.content,
    required this.language,
    required this.startLine,
    required this.endLine,
    this.fileName,
    this.showLineNumbers = true,
    this.showCopyButton = true,
  });

  /// 代码内容
  final String content;
  
  /// 编程语言
  final ProgrammingLanguage? language;
  
  /// 开始行号
  final int startLine;
  
  /// 结束行号
  final int endLine;
  
  /// 文件名（可选）
  final String? fileName;
  
  /// 是否显示行号
  final bool showLineNumbers;
  
  /// 是否显示复制按钮
  final bool showCopyButton;
}

/// 语法高亮配置
class SyntaxHighlightConfig {
  const SyntaxHighlightConfig({
    this.enableSyntaxHighlighting = true,
    this.enableLineNumbers = true,
    this.enableCodeFolding = true,
    this.enableAutoIndentation = true,
    this.tabSize = 2,
    this.fontSize = 14.0,
    this.fontFamily = 'Courier New',
    this.theme,
  });

  /// 是否启用语法高亮
  final bool enableSyntaxHighlighting;
  
  /// 是否启用行号
  final bool enableLineNumbers;
  
  /// 是否启用代码折叠
  final bool enableCodeFolding;
  
  /// 是否启用自动缩进
  final bool enableAutoIndentation;
  
  /// Tab大小
  final int tabSize;
  
  /// 字体大小
  final double fontSize;
  
  /// 字体系列
  final String fontFamily;
  
  /// 语法高亮主题
  final SyntaxHighlightTheme? theme;
} 