/// Syntax highlighting related type definitions

/// Supported programming languages
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

  /// Display name
  final String displayName;
  
  /// File extension list
  final List<String> extensions;

  /// Get language type by extension or language identifier
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

/// Syntax element type
enum SyntaxElementType {
  keyword,      // Keywords
  string,       // Strings
  comment,      // Comments
  number,       // Numbers
  operator,     // Operators
  function,     // Function names
  variable,     // Variable names
  type,         // Type names
  punctuation,  // Punctuation
  annotation,   // Annotations
  property,     // Properties
  constant,     // Constants
  parameter,    // Parameters
  namespace,    // Namespaces
  tag,          // HTML tags
  attribute,    // HTML attributes
  selector,     // CSS selectors
  regex,        // Regular expressions
  escape,       // Escape characters
  plain,        // Plain text
}

/// Syntax element
class SyntaxElement {
  const SyntaxElement({
    required this.type,
    required this.text,
    required this.startIndex,
    required this.endIndex,
  });

  /// Element type
  final SyntaxElementType type;
  
  /// Text content
  final String text;
  
  /// Start position
  final int startIndex;
  
  /// End position
  final int endIndex;

  @override
  String toString() {
    return 'SyntaxElement(type: $type, text: $text, range: $startIndex-$endIndex)';
  }
}

/// Syntax highlighting rule
class SyntaxRule {
  const SyntaxRule({
    required this.pattern,
    required this.elementType,
    this.priority = 0,
    this.isMultiLine = false,
  });

  /// Regular expression pattern
  final RegExp pattern;
  
  /// Corresponding syntax element type
  final SyntaxElementType elementType;
  
  /// Priority (higher number means higher priority)
  final int priority;
  
  /// Whether to support multi-line matching
  final bool isMultiLine;
}

/// Syntax highlighting theme
class SyntaxHighlightTheme {
  const SyntaxHighlightTheme({
    required this.name,
    required this.isDark,
    required this.elementStyles,
    required this.backgroundColor,
    required this.defaultTextColor,
  });

  /// Theme name
  final String name;
  
  /// Whether it is a dark theme
  final bool isDark;
  
  /// Styles for each syntax element
  final Map<SyntaxElementType, SyntaxElementStyle> elementStyles;
  
  /// Background color
  final int backgroundColor;
  
  /// Default text color
  final int defaultTextColor;
}

/// Syntax element style
class SyntaxElementStyle {
  const SyntaxElementStyle({
    required this.color,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.backgroundColor,
  });

  /// Text color
  final int color;
  
  /// Whether bold
  final bool isBold;
  
  /// Whether italic
  final bool isItalic;
  
  /// Whether underlined
  final bool isUnderlined;
  
  /// Background color (optional)
  final int? backgroundColor;
}

/// Code block information
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

  /// Code content
  final String content;
  
  /// Programming language
  final ProgrammingLanguage? language;
  
  /// Start line number
  final int startLine;
  
  /// End line number
  final int endLine;
  
  /// File name (optional)
  final String? fileName;
  
  /// Whether to show line numbers
  final bool showLineNumbers;
  
  /// Whether to show copy button
  final bool showCopyButton;
}

/// Syntax highlighting configuration
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

  /// Whether to enable syntax highlighting
  final bool enableSyntaxHighlighting;
  
  /// Whether to enable line numbers
  final bool enableLineNumbers;
  
  /// Whether to enable code folding
  final bool enableCodeFolding;
  
  /// Whether to enable auto indentation
  final bool enableAutoIndentation;
  
  /// Tab size
  final int tabSize;
  
  /// Font size
  final double fontSize;
  
  /// Font family
  final String fontFamily;
  
  /// Syntax highlighting theme
  final SyntaxHighlightTheme? theme;
}