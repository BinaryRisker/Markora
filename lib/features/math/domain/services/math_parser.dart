import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Math formula type
enum MathType {
  /// Inline formula $...$
  inline,
  /// Block formula $$...$$
  block,
}

/// Math formula entity
class MathFormula {
  const MathFormula({
    required this.type,
    required this.content,
    required this.rawContent,
    required this.startIndex,
    required this.endIndex,
  });

  /// Formula type
  final MathType type;
  
  /// Parsed LaTeX content
  final String content;
  
  /// Original content (including $ symbols)
  final String rawContent;
  
  /// Start position in original text
  final int startIndex;
  
  /// End position in original text
  final int endIndex;

  @override
  String toString() {
    return 'MathFormula(type: $type, content: $content, range: $startIndex-$endIndex)';
  }
}

/// Math formula parser
class MathParser {
  /// Parse math formulas in text
  static List<MathFormula> parseFormulas(String text) {
    final formulas = <MathFormula>[];
    
    // Parse block formulas $$...$$ first
    formulas.addAll(_parseBlockFormulas(text));
    
    // Then parse inline formulas $...$ (avoid conflicts with block formulas)
    formulas.addAll(_parseInlineFormulas(text, formulas));
    
    // Sort by position
    formulas.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    return formulas;
  }

  /// Parse block formulas $$...$$
  static List<MathFormula> _parseBlockFormulas(String text) {
    final formulas = <MathFormula>[];
    final regex = RegExp(r'\$\$(.+?)\$\$', multiLine: true, dotAll: true);
    
    for (final match in regex.allMatches(text)) {
      final rawContent = match.group(0)!;
      var content = match.group(1)!.trim();
      
      // Additional cleaning: remove any remaining $ symbols inside
      content = content.replaceAll('\$', '');
      
      if (content.isNotEmpty) {
        debugPrint('Parsed block formula: raw="$rawContent", cleaned="$content"');
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

  /// Parse inline formulas $...$
  static List<MathFormula> _parseInlineFormulas(String text, List<MathFormula> existingFormulas) {
    final formulas = <MathFormula>[];
    final regex = RegExp(r'\$([^\$\n]+?)\$');
    
    for (final match in regex.allMatches(text)) {
      final startIndex = match.start;
      final endIndex = match.end;
      
      // Check if overlaps with existing block formulas
      bool isOverlapping = false;
      for (final existing in existingFormulas) {
        if (startIndex >= existing.startIndex && endIndex <= existing.endIndex) {
          isOverlapping = true;
          break;
        }
      }
      
      if (!isOverlapping) {
        final rawContent = match.group(0)!;
        var content = match.group(1)!.trim();
        
        // Additional cleaning: remove any remaining $ symbols inside
        content = content.replaceAll('\$', '');
        
        if (content.isNotEmpty && _isValidMathContent(content)) {
          debugPrint('Parsed inline formula: raw="$rawContent", cleaned="$content"');
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

  /// Validate if it's valid math content
  static bool _isValidMathContent(String content) {
    // Basic validation: contains math symbols or functions
    final mathSymbols = RegExp(r'[\+\-\*\/\=\^\{\}\(\)\[\]\\]|\\[a-zA-Z]+|\d');
    return mathSymbols.hasMatch(content);
  }

  /// Replace math formulas in text with placeholders
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

  /// Validate LaTeX syntax
  static bool validateLatex(String latex) {
    try {
      // Basic bracket matching check
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

  /// Preprocess LaTeX content
  static String preprocessLatex(String latex) {
    // Remove any remaining $ symbols that shouldn't be in the content
    String cleaned = latex
        .replaceAll(RegExp(r'^\$+'), '') // Remove leading $
        .replaceAll(RegExp(r'\$+$'), '') // Remove trailing $
        .replaceAll('\n', ' ') // Convert newlines to spaces
        .trim();
    
    debugPrint('Preprocessing LaTeX: "$latex" -> "$cleaned"');
    return cleaned;
  }

  /// Get common math formula examples
  static List<String> getMathExamples() {
    return [
      // Basic math
      'E = mc^2',
      'a^2 + b^2 = c^2',
      '\\pi r^2',
      
      // Fractions
      '\\frac{1}{2}',
      '\\frac{a}{b}',
      
      // Square roots
      '\\sqrt{x}',
      '\\sqrt[3]{x}',
      
      // Integrals
      '\\int_0^\\infty e^{-x^2} dx',
      '\\int_a^b f(x) dx',
      
      // Summation
      '\\sum_{i=1}^n i = \\frac{n(n+1)}{2}',
      '\\sum_{k=0}^\\infty \\frac{x^k}{k!} = e^x',
      
      // Limits
      '\\lim_{x \\to 0} \\frac{\\sin x}{x} = 1',
      '\\lim_{n \\to \\infty} \\left(1 + \\frac{1}{n}\\right)^n = e',
      
      // Matrices
      '\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}',
      
      // Greek letters
      '\\alpha, \\beta, \\gamma, \\delta',
      '\\sin(\\theta), \\cos(\\phi)',
    ];
  }
}