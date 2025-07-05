import '../../../../types/syntax_highlighting.dart';

/// 语法解析器服务
class SyntaxParser {
  /// 解析代码并返回语法元素列表
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

  /// 获取指定语言的语法规则
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

  /// 应用语法规则到代码
  static List<SyntaxElement> _applyRules(String code, List<SyntaxRule> rules) {
    final elements = <SyntaxElement>[];
    final processedRanges = <_Range>[];

    // 按优先级排序规则
    rules.sort((a, b) => b.priority.compareTo(a.priority));

    for (final rule in rules) {
      final matches = rule.pattern.allMatches(code);
      
      for (final match in matches) {
        final start = match.start;
        final end = match.end;
        
        // 检查是否与已处理的范围重叠
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

    // 填充未处理的文本为普通文本
    _fillPlainText(code, elements, processedRanges);

    // 按位置排序
    elements.sort((a, b) => a.startIndex.compareTo(b.startIndex));

    return elements;
  }

  /// 填充普通文本
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

    // 处理最后剩余的文本
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

  /// 检查范围是否重叠
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

  /// Dart语言规则
  static List<SyntaxRule> _getDartRules() {
    return [
      // 字符串 (高优先级)
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
      
      // 注释
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
      
      // 关键字
      SyntaxRule(
        pattern: RegExp(r'\b(abstract|as|assert|async|await|break|case|catch|class|const|continue|default|deferred|do|dynamic|else|enum|export|extends|external|factory|false|final|finally|for|get|hide|if|implements|import|in|interface|is|library|mixin|new|null|on|operator|part|rethrow|return|set|show|static|super|switch|sync|this|throw|true|try|typedef|var|void|while|with|yield)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 8,
      ),
      
      // 类型
      SyntaxRule(
        pattern: RegExp(r'\b(bool|int|double|num|String|List|Map|Set|Future|Stream|Object|Function)\b'),
        elementType: SyntaxElementType.type,
        priority: 7,
      ),
      
      // 数字
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // 函数名
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()'),
        elementType: SyntaxElementType.function,
        priority: 5,
      ),
      
      // 操作符
      SyntaxRule(
        pattern: RegExp(r'[+\-*/=<>!&|^%~?:]'),
        elementType: SyntaxElementType.operator,
        priority: 4,
      ),
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// JavaScript/TypeScript语言规则
  static List<SyntaxRule> _getJavaScriptRules() {
    return [
      // 字符串
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
      
      // 注释
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
      
      // 关键字
      SyntaxRule(
        pattern: RegExp(r'\b(abstract|arguments|await|boolean|break|byte|case|catch|char|class|const|continue|debugger|default|delete|do|double|else|enum|eval|export|extends|false|final|finally|float|for|function|goto|if|implements|import|in|instanceof|int|interface|let|long|native|new|null|package|private|protected|public|return|short|static|super|switch|synchronized|this|throw|throws|transient|true|try|typeof|var|void|volatile|while|with|yield)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 8,
      ),
      
      // 数字
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // 函数名
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z_$][a-zA-Z0-9_$]*(?=\s*\()'),
        elementType: SyntaxElementType.function,
        priority: 5,
      ),
      
      // 操作符
      SyntaxRule(
        pattern: RegExp(r'[+\-*/=<>!&|^%~?:]'),
        elementType: SyntaxElementType.operator,
        priority: 4,
      ),
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// Python语言规则
  static List<SyntaxRule> _getPythonRules() {
    return [
      // 字符串
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
      
      // 注释
      SyntaxRule(
        pattern: RegExp(r'#.*$', multiLine: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
      ),
      
      // 关键字
      SyntaxRule(
        pattern: RegExp(r'\b(False|None|True|and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 8,
      ),
      
      // 数字
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // 函数名
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()'),
        elementType: SyntaxElementType.function,
        priority: 5,
      ),
      
      // 操作符
      SyntaxRule(
        pattern: RegExp(r'[+\-*/=<>!&|^%~]'),
        elementType: SyntaxElementType.operator,
        priority: 4,
      ),
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.:@]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// Java语言规则
  static List<SyntaxRule> _getJavaRules() {
    return [
      // 字符串
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
      
      // 注释
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
      
      // 关键字
      SyntaxRule(
        pattern: RegExp(r'\b(abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 8,
      ),
      
      // 数字
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*[fFdDlL]?\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // 函数名
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\()'),
        elementType: SyntaxElementType.function,
        priority: 5,
      ),
      
      // 操作符
      SyntaxRule(
        pattern: RegExp(r'[+\-*/=<>!&|^%~?:]'),
        elementType: SyntaxElementType.operator,
        priority: 4,
      ),
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// HTML语言规则
  static List<SyntaxRule> _getHtmlRules() {
    return [
      // 注释
      SyntaxRule(
        pattern: RegExp(r'<!--.*?-->', multiLine: true, dotAll: true),
        elementType: SyntaxElementType.comment,
        priority: 10,
        isMultiLine: true,
      ),
      
      // 标签
      SyntaxRule(
        pattern: RegExp(r'</?[a-zA-Z][a-zA-Z0-9]*'),
        elementType: SyntaxElementType.tag,
        priority: 8,
      ),
      
      // 属性
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z-]+(?==)'),
        elementType: SyntaxElementType.attribute,
        priority: 7,
      ),
      
      // 字符串（属性值）
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
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[<>/=]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// CSS语言规则
  static List<SyntaxRule> _getCssRules() {
    return [
      // 注释
      SyntaxRule(
        pattern: RegExp(r'/\*.*?\*/', multiLine: true, dotAll: true),
        elementType: SyntaxElementType.comment,
        priority: 10,
        isMultiLine: true,
      ),
      
      // 选择器
      SyntaxRule(
        pattern: RegExp(r'[.#]?[a-zA-Z][a-zA-Z0-9-_]*(?=\s*{)'),
        elementType: SyntaxElementType.selector,
        priority: 8,
      ),
      
      // 属性
      SyntaxRule(
        pattern: RegExp(r'\b[a-zA-Z-]+(?=\s*:)'),
        elementType: SyntaxElementType.property,
        priority: 7,
      ),
      
      // 字符串
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
      
      // 数字和单位
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*[a-zA-Z%]*\b'),
        elementType: SyntaxElementType.number,
        priority: 5,
      ),
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[{}();:,]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// JSON语言规则
  static List<SyntaxRule> _getJsonRules() {
    return [
      // 字符串
      SyntaxRule(
        pattern: RegExp(r'"(?:[^"\\]|\\.)*"'),
        elementType: SyntaxElementType.string,
        priority: 10,
      ),
      
      // 数字
      SyntaxRule(
        pattern: RegExp(r'-?\d+\.?\d*([eE][+-]?\d+)?'),
        elementType: SyntaxElementType.number,
        priority: 8,
      ),
      
      // 关键字
      SyntaxRule(
        pattern: RegExp(r'\b(true|false|null)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 7,
      ),
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[{}\[\]:,]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// YAML语言规则
  static List<SyntaxRule> _getYamlRules() {
    return [
      // 注释
      SyntaxRule(
        pattern: RegExp(r'#.*$', multiLine: true),
        elementType: SyntaxElementType.comment,
        priority: 9,
      ),
      
      // 键
      SyntaxRule(
        pattern: RegExp(r'^[a-zA-Z0-9_-]+(?=\s*:)', multiLine: true),
        elementType: SyntaxElementType.property,
        priority: 8,
      ),
      
      // 字符串
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
      
      // 数字
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // 关键字
      SyntaxRule(
        pattern: RegExp(r'\b(true|false|null|yes|no|on|off)\b'),
        elementType: SyntaxElementType.keyword,
        priority: 5,
      ),
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[:\-|>]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }

  /// 基础语法规则（用于不支持的语言）
  static List<SyntaxRule> _getBasicRules() {
    return [
      // 字符串
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
      
      // 数字
      SyntaxRule(
        pattern: RegExp(r'\b\d+\.?\d*\b'),
        elementType: SyntaxElementType.number,
        priority: 6,
      ),
      
      // 标点符号
      SyntaxRule(
        pattern: RegExp(r'[{}()\[\];,.]'),
        elementType: SyntaxElementType.punctuation,
        priority: 3,
      ),
    ];
  }
}

/// 范围类
class _Range {
  const _Range(this.start, this.end);
  
  final int start;
  final int end;
} 