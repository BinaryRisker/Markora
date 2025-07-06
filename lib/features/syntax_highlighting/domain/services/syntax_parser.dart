import '../../../../types/syntax_highlighting.dart';

/// Syntax parser service
class SyntaxParser {
  /// Parse code and return syntax element list
  static List<SyntaxElement> parseCode(String code, ProgrammingLanguage? language) {
    if (language == null || code.isEmpty) {
      return [
        SyntaxElement(
          type: SyntaxElementType.plain,
          text: code,
          startIndex: 0,
          endIndex: code.length,
        ),
      ];
    }

    final rules = _getLanguageRules(language);
    return _applyRules(code, rules);
  }

  /// Get syntax rules for specified language
  static List<SyntaxRule> _getLanguageRules(ProgrammingLanguage language) {
    switch (language) {
      case ProgrammingLanguage.dart:
        return _getDartRules();
      case ProgrammingLanguage.javascript:
      case ProgrammingLanguage.typescript:
        return _getJavaScriptRules();
      case ProgrammingLanguage.python:
        return _getPythonRules();
      case ProgrammingLanguage.java:
        return _getJavaRules();
      case ProgrammingLanguage.html:
        return _getHtmlRules();
      case ProgrammingLanguage.css:
        return _getCssRules();
      case ProgrammingLanguage.json:
        return _getJsonRules();
      case ProgrammingLanguage.yaml:
        return _getYamlRules();
      default:
        return _getBasicRules();
    }
  }

  /// Apply syntax rules to code
  static List<SyntaxElement> _applyRules(String code, List<SyntaxRule> rules) {
    final elements = <SyntaxElement>[];
    final processedRanges = <_Range>[];

    // Sort rules by priority
    rules.sort((a, b) => b.priority.compareTo(a.priority));

    for (final rule in rules) {
      final matches = rule.pattern.allMatches(code);
      
      for (final match in matches) {
        final start = match.start;
        final end = match.end;
        
        // Check if overlapping with processed ranges
        if (_isOverlapping(start, end, processedRanges)) {
          continue;
        }

        elements.add(SyntaxElement(
          type: rule.elementType,
          text: match.group(0)!,
          startIndex: start,
          endIndex: end,
        ));

        processedRanges.add(_Range(start, end));
      }
    }

    // Fill unprocessed text as plain text
    _fillPlainText(code, elements, processedRanges);

    // Sort by position
    elements.sort((a, b) => a.startIndex.compareTo(b.startIndex));

    return elements;
  }

  /// Fill plain text
  static void _fillPlainText(String code, List<SyntaxElement> elements, List<_Range> processedRanges) {
    processedRanges.sort((a, b) => a.start.compareTo(b.start));
    
    int currentIndex = 0;
    
    for (final range in processedRanges) {
      if (currentIndex < range.start) {
        final plainText = code.substring(currentIndex, range.start);
        if (plainText.isNotEmpty) {
          elements.add(SyntaxElement(
            type: SyntaxElementType.plain,
            text: plainText,
            startIndex: currentIndex,
            endIndex: range.start,
          ));
        }
      }
      currentIndex = range.end;
    }

    // Process remaining text at the end
    if (currentIndex < code.length) {
      final plainText = code.substring(currentIndex);
      if (plainText.isNotEmpty) {
        elements.add(SyntaxElement(
          type: SyntaxElementType.plain,
          text: plainText,
          startIndex: currentIndex,
          endIndex: code.length,
        ));
      }
    }
  }

  /// Check if ranges overlap
  static bool _isOverlapping(int start, int end, List<_Range> ranges) {
    for (final range in ranges) {
      if ((start >= range.start && start < range.end) ||
          (end > range.start && end <= range.end) ||
          (start <= range.start && end >= range.end)) {
        return true;
      }
    }
    return false;
  }

  /// Dart language rules
  static List<SyntaxRule> _getDartRules() {
    return [
      // Strings (high priority)
      SyntaxRule(
        pattern: RegExp(r'"(?:[^"\\]|\\.)*"'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      SyntaxRule(
        pattern: RegExp(r"'(?:[^'\\]|\\.)*'"),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      SyntaxRule(
        pattern: RegExp(r'r"[^"]*"'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      
      // Comments
      SyntaxRule(
        pattern: RegExp(r'//.*$', multiLine: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
      ),
      SyntaxRule(
        pattern: RegExp(r'/\*.*?\*/', multiLine: true, dotAll: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
        isMultiLine: true,
      ),
      
      // Keywords
      SyntaxRule(
        pattern: RegExp(r'\b(abstract|as|assert|async|await|break|case|catch|class|const|continue|default|deferred|do|dynamic|else|enum|export|extends|external|factory|false|final|finally|for|get|hide|if|implements|import|in|interface|is|library|mixin|new|null|on|operator|part|rethrow|return|set|show|static|super|switch|sync|this|throw|true|try|typedef|var|void|while|with|yield)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 8,
      ),
      
      // Types
      SyntaxRule(
        pattern: RegExp(r'\b(bool|int|double|num|String|List|Map|Set|Future|Stream|Object|Function)\b'),
        elementType: SyntaxElementType.type,
        priority: 7,
      ),
      
      // Numbers
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // Function names
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()'),
        elementType: SyntaxElementType.function,
        priority: 5,
      ),
      
      // Operators
      SyntaxRule(
        pattern: RegExp(r'[+\-*/=<>!&|^%~?:]'),
        elementType: SyntaxElementType.operator,
        priority: 4,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// JavaScript/TypeScript language rules
  static List<SyntaxRule> _getJavaScriptRules() {
    return [
      // String
      SyntaxRule(
        pattern: RegExp(r'"(?:[^"\\]|\\.)*"'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      SyntaxRule(
        pattern: RegExp(r"'(?:[^'\\]|\\.)*'"),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      SyntaxRule(
        pattern: RegExp(r'`(?:[^`\\]|\\.)*`'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      
      // Comment
      SyntaxRule(
        pattern: RegExp(r'//.*$', multiLine: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
      ),
      SyntaxRule(
        pattern: RegExp(r'/\*.*?\*/', multiLine: true, dotAll: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
        isMultiLine: true,
      ),
      
      // Keyword
      SyntaxRule(
        pattern: RegExp(r'\b(abstract|arguments|await|boolean|break|byte|case|catch|char|class|const|continue|debugger|default|delete|do|double|else|enum|eval|export|extends|false|final|finally|float|for|function|goto|if|implements|import|in|instanceof|int|interface|let|long|native|new|null|package|private|protected|public|return|short|static|super|switch|synchronized|this|throw|throws|transient|true|try|typeof|var|void|volatile|while|with|yield)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 8,
      ),
      
      // Number
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // Function name
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z_$][a-zA-Z0-9_$]*(?=\s*\()'),
        elementType: SyntaxElementType.function,
        priority: 5,
      ),
      
      // Operator
      SyntaxRule(
        pattern: RegExp(r'[+\-*/=<>!&|^%~?:]'),
        elementType: SyntaxElementType.operator,
        priority: 4,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// Python language rules
  static List<SyntaxRule> _getPythonRules() {
    return [
      // String
      SyntaxRule(
        pattern: RegExp(r'""".*?"""', multiLine: true, dotAll: true),
        elementType: SyntaxElementType.string,
        priority: 11,
        isMultiLine: true,
      ),
      SyntaxRule(
        pattern: RegExp(r"'''.*?'''", multiLine: true, dotAll: true),
        elementType: SyntaxElementType.string,
        priority: 11,
        isMultiLine: true,
      ),
      SyntaxRule(
        pattern: RegExp(r'"(?:[^"\\]|\\.)*"'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      SyntaxRule(
        pattern: RegExp(r"'(?:[^'\\]|\\.)*'"),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      
      // Comment
      SyntaxRule(
        pattern: RegExp(r'#.*$', multiLine: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
      ),
      
      // Keyword
      SyntaxRule(
        pattern: RegExp(r'\b(False|None|True|and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 8,
      ),
      
      // Number
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // Function name
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()'),
        elementType: SyntaxElementType.function,
        priority: 5,
      ),
      
      // Operator
      SyntaxRule(
        pattern: RegExp(r'[+\-*/=<>!&|^%~]'),
        elementType: SyntaxElementType.operator,
        priority: 4,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.:@]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// Java language rules
  static List<SyntaxRule> _getJavaRules() {
    return [
      // String
      SyntaxRule(
        pattern: RegExp(r'"(?:[^"\\]|\\.)*"'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      SyntaxRule(
        pattern: RegExp(r"'(?:[^'\\]|\\.)*'"),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      
      // Comment
      SyntaxRule(
        pattern: RegExp(r'//.*$', multiLine: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
      ),
      SyntaxRule(
        pattern: RegExp(r'/\*.*?\*/', multiLine: true, dotAll: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
        isMultiLine: true,
      ),
      
      // Keyword
      SyntaxRule(
        pattern: RegExp(r'\b(abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 8,
      ),
      
      // Number
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*[fFdDlL]?\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // Function name
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()'),
        elementType: SyntaxElementType.function,
        priority: 5,
      ),
      
      // Operator
      SyntaxRule(
        pattern: RegExp(r'[+\-*/=<>!&|^%~?:]'),
        elementType: SyntaxElementType.operator,
        priority: 4,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// HTML language rules
  static List<SyntaxRule> _getHtmlRules() {
    return [
      // Comment
      SyntaxRule(
        pattern: RegExp(r'<!--.*?-->', multiLine: true, dotAll: true),
        elementType: SyntaxElementType.comment,
        priority: 10,
        isMultiLine: true,
      ),
      
      // Tags
      SyntaxRule(
        pattern: RegExp(r'</?[a-zA-Z][a-zA-Z0-9]*'),
        elementType: SyntaxElementType.tag,
        priority: 8,
      ),
      
      // Attributes
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z-]+(?==)'),
        elementType: SyntaxElementType.attribute,
        priority: 7,
      ),
      
      // Strings (attribute values)
      SyntaxRule(
        pattern: RegExp(r'"[^"]*"'),
        elementType: SyntaxElementType.string,
        priority: 6,
      ),
      SyntaxRule(
        pattern: RegExp(r"'[^']*'"),
        elementType: SyntaxElementType.string,
        priority: 6,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[<>/=]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// CSS language rules
  static List<SyntaxRule> _getCssRules() {
    return [
      // Comment
      SyntaxRule(
        pattern: RegExp(r'/\*.*?\*/', multiLine: true, dotAll: true),
        elementType: SyntaxElementType.comment,
        priority: 10,
        isMultiLine: true,
      ),
      
      // Selectors
      SyntaxRule(
        pattern: RegExp(r'[.#]?[a-zA-Z][a-zA-Z0-9-_]*(?=\s*{)'),
        elementType: SyntaxElementType.selector,
        priority: 8,
      ),
      
      // Property
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z-]+(?=\s*:)'),
        elementType: SyntaxElementType.property,
        priority: 7,
      ),
      
      // String
      SyntaxRule(
        pattern: RegExp(r'"[^"]*"'),
        elementType: SyntaxElementType.string,
        priority: 6,
      ),
      SyntaxRule(
        pattern: RegExp(r"'[^']*'"),
        elementType: SyntaxElementType.string,
        priority: 6,
      ),
      
      // Numbers and units
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*[a-zA-Z%]*\b'),
        elementType: SyntaxElementType.number,
        priority: 5,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[{}();:,]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// JSON language rules
  static List<SyntaxRule> _getJsonRules() {
    return [
      // String
      SyntaxRule(
        pattern: RegExp(r'"(?:[^"\\]|\\.)*"'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      
      // Number
      SyntaxRule(
        pattern: RegExp(r'-?\d+\.?\d*([eE][+-]?\d+)?'),
        elementType: SyntaxElementType.number,
        priority: 8,
      ),
      
      // Keyword
      SyntaxRule(
        pattern: RegExp(r'\b(true|false|null)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 7,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[{}\[\]:,]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// YAML language rules
  static List<SyntaxRule> _getYamlRules() {
    return [
      // Comment
      SyntaxRule(
        pattern: RegExp(r'#.*$', multiLine: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
      ),
      
      // Keys
      SyntaxRule(
        pattern: RegExp(r'^[a-zA-Z0-9_-]+(?=\s*:)', multiLine: true),
        elementType: SyntaxElementType.property,
        priority: 8,
      ),
      
      // String
      SyntaxRule(
        pattern: RegExp(r'"[^"]*"'),
        elementType: SyntaxElementType.string,
        priority: 7,
      ),
      SyntaxRule(
        pattern: RegExp(r"'[^']*'"),
        elementType: SyntaxElementType.string,
        priority: 7,
      ),
      
      // Number
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // Keyword
      SyntaxRule(
        pattern: RegExp(r'\b(true|false|null|yes|no|on|off)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 5,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[:\-|>]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// Basic syntax rules (for unsupported languages)
  static List<SyntaxRule> _getBasicRules() {
    return [
      // String
      SyntaxRule(
        pattern: RegExp(r'"[^"]*"'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      SyntaxRule(
        pattern: RegExp(r"'[^']*'"),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      
      // Number
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // Punctuation
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }
}

/// Range class
class _Range {
  const _Range(this.start, this.end);
  
  final int start;
  final int end;
}