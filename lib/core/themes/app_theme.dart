import 'package:flutter/material.dart';

/// Markora application theme configuration
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

/// Editor theme configuration
class EditorTheme {
  const EditorTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.cursorColor,
    required this.selectionColor,
    required this.lineNumberColor,
    required this.currentLineColor,
    required this.syntaxColors,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color cursorColor;
  final Color selectionColor;
  final Color lineNumberColor;
  final Color currentLineColor;
  final SyntaxColors syntaxColors;

  /// Light editor theme
  static const EditorTheme light = EditorTheme(
    backgroundColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF212121),
    cursorColor: Color(0xFF2196F3),
    selectionColor: Color(0x402196F3),
    lineNumberColor: Color(0xFF9E9E9E),
    currentLineColor: Color(0xFFF5F5F5),
    syntaxColors: SyntaxColors.light,
  );

  /// Dark editor theme
  static const EditorTheme dark = EditorTheme(
    backgroundColor: Color(0xFF1E1E1E),
    textColor: Color(0xFFD4D4D4),
    cursorColor: Color(0xFF2196F3),
    selectionColor: Color(0x402196F3),
    lineNumberColor: Color(0xFF858585),
    currentLineColor: Color(0xFF2D2D30),
    syntaxColors: SyntaxColors.dark,
  );
}

/// Syntax highlighting color configuration
class SyntaxColors {
  const SyntaxColors({
    required this.keyword,
    required this.string,
    required this.comment,
    required this.number,
    required this.operator,
    required this.type,
    required this.function,
    required this.variable,
    required this.constant,
    required this.heading,
    required this.link,
    required this.emphasis,
    required this.strong,
    required this.code,
  });

  final Color keyword;
  final Color string;
  final Color comment;
  final Color number;
  final Color operator;
  final Color type;
  final Color function;
  final Color variable;
  final Color constant;
  final Color heading;
  final Color link;
  final Color emphasis;
  final Color strong;
  final Color code;

  /// Light syntax colors
  static const SyntaxColors light = SyntaxColors(
    keyword: Color(0xFF0000FF),
    string: Color(0xFF008000),
    comment: Color(0xFF008000),
    number: Color(0xFF098658),
    operator: Color(0xFF000000),
    type: Color(0xFF267F99),
    function: Color(0xFF795E26),
    variable: Color(0xFF001080),
    constant: Color(0xFF0070C1),
    heading: Color(0xFF800080),
    link: Color(0xFF0000EE),
    emphasis: Color(0xFF000000),
    strong: Color(0xFF000000),
    code: Color(0xFFE31A1C),
  );

  /// Dark syntax colors
  static const SyntaxColors dark = SyntaxColors(
    keyword: Color(0xFF569CD6),
    string: Color(0xFFCE9178),
    comment: Color(0xFF6A9955),
    number: Color(0xFFB5CEA8),
    operator: Color(0xFFD4D4D4),
    type: Color(0xFF4EC9B0),
    function: Color(0xFFDCDCAA),
    variable: Color(0xFF9CDCFE),
    constant: Color(0xFF4FC1FF),
    heading: Color(0xFFC586C0),
    link: Color(0xFF3794FF),
    emphasis: Color(0xFFD4D4D4),
    strong: Color(0xFFD4D4D4),
    code: Color(0xFFD7BA7D),
  );
}