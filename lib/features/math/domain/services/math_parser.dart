import 'dart:convert';

/// 数学公式类型
enum MathType {
  /// 行内公式 $...$
  inline,
  /// 块级公式 $$...$$
  block,
}

/// 数学公式实体
class MathFormula {
  const MathFormula({
    required this.type,
    required this.content,
    required this.rawContent,
    required this.startIndex,
    required this.endIndex,
  });

  /// 公式类型
  final MathType type;
  
  /// 解析后的LaTeX内容
  final String content;
  
  /// 原始内容（包含$符号）
  final String rawContent;
  
  /// 在原文本中的开始位置
  final int startIndex;
  
  /// 在原文本中的结束位置
  final int endIndex;

  @override
  String toString() {
    return 'MathFormula(type: $type, content: $content, range: $startIndex-$endIndex)';
  }
}

/// 数学公式解析器
class MathParser {
  /// 解析文本中的数学公式
  static List<MathFormula> parseFormulas(String text) {
    final formulas = <MathFormula>[];
    
    // 先解析块级公式 $$...$$
    formulas.addAll(_parseBlockFormulas(text));
    
    // 再解析行内公式 $...$（避免与块级公式冲突）
    formulas.addAll(_parseInlineFormulas(text, formulas));
    
    // 按位置排序
    formulas.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    return formulas;
  }

  /// 解析块级公式 $$...$$
  static List<MathFormula> _parseBlockFormulas(String text) {
    final formulas = <MathFormula>[];
    final regex = RegExp(r'\$\$(.+?)\$\$', multiLine: true, dotAll: true);
    
    for (final match in regex.allMatches(text)) {
      final rawContent = match.group(0)!;
      final content = match.group(1)!.trim();
      
      if (content.isNotEmpty) {
        formulas.add(MathFormula(
          type: MathType.block,
          content: content,
          rawContent: rawContent,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    }
    
    return formulas;
  }

  /// 解析行内公式 $...$
  static List<MathFormula> _parseInlineFormulas(String text, List<MathFormula> existingFormulas) {
    final formulas = <MathFormula>[];
    final regex = RegExp(r'\$([^\$\n]+?)\$');
    
    for (final match in regex.allMatches(text)) {
      final startIndex = match.start;
      final endIndex = match.end;
      
      // 检查是否与已有的块级公式重叠
      bool isOverlapping = false;
      for (final existing in existingFormulas) {
        if (startIndex >= existing.startIndex && endIndex <= existing.endIndex) {
          isOverlapping = true;
          break;
        }
      }
      
      if (!isOverlapping) {
        final rawContent = match.group(0)!;
        final content = match.group(1)!.trim();
        
        if (content.isNotEmpty && _isValidMathContent(content)) {
          formulas.add(MathFormula(
            type: MathType.inline,
            content: content,
            rawContent: rawContent,
            startIndex: startIndex,
            endIndex: endIndex,
          ));
        }
      }
    }
    
    return formulas;
  }

  /// 验证是否为有效的数学内容
  static bool _isValidMathContent(String content) {
    // 基本验证：包含数学符号或函数
    final mathSymbols = RegExp(r'[\+\-\*\/\=\^\{\}\(\)\[\]\\]|\\[a-zA-Z]+|\d');
    return mathSymbols.hasMatch(content);
  }

  /// 替换文本中的数学公式为占位符
  static String replaceMathWithPlaceholders(String text, List<MathFormula> formulas) {
    String result = text;
    int offset = 0;
    
    for (int i = 0; i < formulas.length; i++) {
      final formula = formulas[i];
      final placeholder = '<math-formula-$i>';
      
      final start = formula.startIndex - offset;
      final end = formula.endIndex - offset;
      
      result = result.substring(0, start) + 
               placeholder + 
               result.substring(end);
      
      offset += formula.rawContent.length - placeholder.length;
    }
    
    return result;
  }

  /// 验证LaTeX语法
  static bool validateLatex(String latex) {
    try {
      // 基本的括号匹配检查
      int braceCount = 0;
      int parenCount = 0;
      int bracketCount = 0;
      
      for (int i = 0; i < latex.length; i++) {
        switch (latex[i]) {
          case '{':
            braceCount++;
            break;
          case '}':
            braceCount--;
            if (braceCount < 0) return false;
            break;
          case '(':
            parenCount++;
            break;
          case ')':
            parenCount--;
            if (parenCount < 0) return false;
            break;
          case '[':
            bracketCount++;
            break;
          case ']':
            bracketCount--;
            if (bracketCount < 0) return false;
            break;
        }
      }
      
      return braceCount == 0 && parenCount == 0 && bracketCount == 0;
    } catch (e) {
      return false;
    }
  }

  /// 预处理LaTeX内容
  static String preprocessLatex(String latex) {
    return latex
        .replaceAll('\\\\', '\\\\\\\\') // 转义反斜杠
        .replaceAll('\n', ' ') // 将换行转为空格
        .trim();
  }

  /// 获取常用的数学公式示例
  static List<String> getMathExamples() {
    return [
      // 基础数学
      'E = mc^2',
      'a^2 + b^2 = c^2',
      '\\pi r^2',
      
      // 分数
      '\\frac{1}{2}',
      '\\frac{a}{b}',
      
      // 根号
      '\\sqrt{x}',
      '\\sqrt[3]{x}',
      
      // 积分
      '\\int_0^\\infty e^{-x^2} dx',
      '\\int_a^b f(x) dx',
      
      // 求和
      '\\sum_{i=1}^n i = \\frac{n(n+1)}{2}',
      '\\sum_{k=0}^\\infty \\frac{x^k}{k!} = e^x',
      
      // 极限
      '\\lim_{x \\to 0} \\frac{\\sin x}{x} = 1',
      '\\lim_{n \\to \\infty} \\left(1 + \\frac{1}{n}\\right)^n = e',
      
      // 矩阵
      '\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}',
      
      // 希腊字母
      '\\alpha, \\beta, \\gamma, \\delta',
      '\\sin(\\theta), \\cos(\\phi)',
    ];
  }
} 