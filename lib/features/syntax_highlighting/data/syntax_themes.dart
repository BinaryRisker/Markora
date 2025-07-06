import 'package:flutter/material.dart';
import '../../../types/syntax_highlighting.dart';

/// Predefined syntax highlighting themes
class SyntaxThemes {
  static const _lightThemeStyles = {
    SyntaxElementType.keyword: SyntaxElementStyle(
      color: 0xFF0000FF, // Blue
      isBold: true,
    ),
    SyntaxElementType.string: SyntaxElementStyle(
      color: 0xFF008000, // Green
    ),
    SyntaxElementType.comment: SyntaxElementStyle(
      color: 0xFF808080, // Gray
      isItalic: true,
    ),
    SyntaxElementType.number: SyntaxElementStyle(
      color: 0xFFFF6600, // Orange
    ),
    SyntaxElementType.operator: SyntaxElementStyle(
      color: 0xFF800080, // Purple
    ),
    SyntaxElementType.function: SyntaxElementStyle(
      color: 0xFF795E26, // Brown
      isBold: true,
    ),
    SyntaxElementType.variable: SyntaxElementStyle(
      color: 0xFF001080, // Dark blue
    ),
    SyntaxElementType.type: SyntaxElementStyle(
      color: 0xFF267F99, // Cyan blue
    ),
    SyntaxElementType.punctuation: SyntaxElementStyle(
      color: 0xFF000000, // Black
    ),
    SyntaxElementType.annotation: SyntaxElementStyle(
      color: 0xFF808000, // Dark yellow
    ),
    SyntaxElementType.property: SyntaxElementStyle(
      color: 0xFF0451A5, // Deep blue
    ),
    SyntaxElementType.constant: SyntaxElementStyle(
      color: 0xFF0000FF, // Blue
      isBold: true,
    ),
    SyntaxElementType.parameter: SyntaxElementStyle(
      color: 0xFF795E26, // Brown
    ),
    SyntaxElementType.namespace: SyntaxElementStyle(
      color: 0xFF267F99, // Cyan blue
    ),
    SyntaxElementType.tag: SyntaxElementStyle(
      color: 0xFF800000, // Dark red
    ),
    SyntaxElementType.attribute: SyntaxElementStyle(
      color: 0xFF0000FF, // Blue
    ),
    SyntaxElementType.selector: SyntaxElementStyle(
      color: 0xFF800000, // Dark red
    ),
    SyntaxElementType.regex: SyntaxElementStyle(
      color: 0xFFD16969, // Red
    ),
    SyntaxElementType.escape: SyntaxElementStyle(
      color: 0xFFD7BA7D, // Light yellow
    ),
    SyntaxElementType.plain: SyntaxElementStyle(
      color: 0xFF000000, // Black
    ),
  };

  static const _darkThemeStyles = {
    SyntaxElementType.keyword: SyntaxElementStyle(
      color: 0xFF569CD6, // Bright blue
      isBold: true,
    ),
    SyntaxElementType.string: SyntaxElementStyle(
      color: 0xFFCE9178, // Light orange
    ),
    SyntaxElementType.comment: SyntaxElementStyle(
      color: 0xFF6A9955, // Green
      isItalic: true,
    ),
    SyntaxElementType.number: SyntaxElementStyle(
      color: 0xFFB5CEA8, // Light green
    ),
    SyntaxElementType.operator: SyntaxElementStyle(
      color: 0xFFD4D4D4, // Light white
    ),
    SyntaxElementType.function: SyntaxElementStyle(
      color: 0xFFDCDCAA, // Light yellow
      isBold: true,
    ),
    SyntaxElementType.variable: SyntaxElementStyle(
      color: 0xFF9CDCFE, // Light blue
    ),
    SyntaxElementType.type: SyntaxElementStyle(
      color: 0xFF4EC9B0, // Cyan green
    ),
    SyntaxElementType.punctuation: SyntaxElementStyle(
      color: 0xFFD4D4D4, // Light white
    ),
    SyntaxElementType.annotation: SyntaxElementStyle(
      color: 0xFFDCDCAA, // Light yellow
    ),
    SyntaxElementType.property: SyntaxElementStyle(
      color: 0xFF9CDCFE, // Light blue
    ),
    SyntaxElementType.constant: SyntaxElementStyle(
      color: 0xFF569CD6, // Bright blue
      isBold: true,
    ),
    SyntaxElementType.parameter: SyntaxElementStyle(
      color: 0xFFDCDCAA, // Light yellow
    ),
    SyntaxElementType.namespace: SyntaxElementStyle(
      color: 0xFF4EC9B0, // Cyan green
    ),
    SyntaxElementType.tag: SyntaxElementStyle(
      color: 0xFF569CD6, // Bright blue
    ),
    SyntaxElementType.attribute: SyntaxElementStyle(
      color: 0xFF92C5F8, // Light blue
    ),
    SyntaxElementType.selector: SyntaxElementStyle(
      color: 0xFFD7BA7D, // Light yellow
    ),
    SyntaxElementType.regex: SyntaxElementStyle(
      color: 0xFFD16969, // Red
    ),
    SyntaxElementType.escape: SyntaxElementStyle(
      color: 0xFFD7BA7D, // Light yellow
    ),
    SyntaxElementType.plain: SyntaxElementStyle(
      color: 0xFFD4D4D4, // Light white
    ),
  };

  /// VS Code Light theme
  static const vsCodeLight = SyntaxHighlightTheme(
    name: 'VS Code Light',
    isDark: false,
    elementStyles: _lightThemeStyles,
    backgroundColor: 0xFFFFFFFF, // White background
    defaultTextColor: 0xFF000000, // Black text
  );

  /// VS Code Dark theme
  static const vsCodeDark = SyntaxHighlightTheme(
    name: 'VS Code Dark',
    isDark: true,
    elementStyles: _darkThemeStyles,
    backgroundColor: 0xFF1E1E1E, // Dark gray background
    defaultTextColor: 0xFFD4D4D4, // Light white text
  );

  /// GitHub Light theme
  static const githubLight = SyntaxHighlightTheme(
    name: 'GitHub Light',
    isDark: false,
    elementStyles: {
      SyntaxElementType.keyword: SyntaxElementStyle(
        color: 0xFFD73A49, // GitHub red
        isBold: true,
      ),
      SyntaxElementType.string: SyntaxElementStyle(
        color: 0xFF032F62, // GitHub dark blue
      ),
      SyntaxElementType.comment: SyntaxElementStyle(
        color: 0xFF6A737D, // GitHub gray
        isItalic: true,
      ),
      SyntaxElementType.number: SyntaxElementStyle(
        color: 0xFF005CC5, // GitHub blue
      ),
      SyntaxElementType.operator: SyntaxElementStyle(
        color: 0xFFD73A49, // GitHub red
      ),
      SyntaxElementType.function: SyntaxElementStyle(
        color: 0xFF6F42C1, // GitHub purple
        isBold: true,
      ),
      SyntaxElementType.variable: SyntaxElementStyle(
        color: 0xFF24292E, // GitHub black
      ),
      SyntaxElementType.type: SyntaxElementStyle(
        color: 0xFF005CC5, // GitHub blue
      ),
      SyntaxElementType.punctuation: SyntaxElementStyle(
        color: 0xFF24292E, // GitHub black
      ),
      SyntaxElementType.annotation: SyntaxElementStyle(
        color: 0xFF6A737D, // GitHub gray
      ),
      SyntaxElementType.property: SyntaxElementStyle(
        color: 0xFF005CC5, // GitHub blue
      ),
      SyntaxElementType.constant: SyntaxElementStyle(
        color: 0xFF005CC5, // GitHub blue
        isBold: true,
      ),
      SyntaxElementType.parameter: SyntaxElementStyle(
        color: 0xFFE36209, // GitHub orange
      ),
      SyntaxElementType.namespace: SyntaxElementStyle(
        color: 0xFF6F42C1, // GitHub purple
      ),
      SyntaxElementType.tag: SyntaxElementStyle(
        color: 0xFF22863A, // GitHub green
      ),
      SyntaxElementType.attribute: SyntaxElementStyle(
        color: 0xFF6F42C1, // GitHub purple
      ),
      SyntaxElementType.selector: SyntaxElementStyle(
        color: 0xFF6F42C1, // GitHub purple
      ),
      SyntaxElementType.regex: SyntaxElementStyle(
        color: 0xFF032F62, // GitHub dark blue
      ),
      SyntaxElementType.escape: SyntaxElementStyle(
        color: 0xFFE36209, // GitHub orange
      ),
      SyntaxElementType.plain: SyntaxElementStyle(
        color: 0xFF24292E, // GitHub black
      ),
    },
    backgroundColor: 0xFFFFFFFF, // White background
    defaultTextColor: 0xFF24292E, // GitHub black
  );

  /// GitHub Dark theme
  static const githubDark = SyntaxHighlightTheme(
    name: 'GitHub Dark',
    isDark: true,
    elementStyles: {
      SyntaxElementType.keyword: SyntaxElementStyle(
        color: 0xFFFF7B72, // GitHub Dark red
        isBold: true,
      ),
      SyntaxElementType.string: SyntaxElementStyle(
        color: 0xFFA5D6FF, // GitHub Dark blue
      ),
      SyntaxElementType.comment: SyntaxElementStyle(
        color: 0xFF8B949E, // GitHub Dark gray
        isItalic: true,
      ),
      SyntaxElementType.number: SyntaxElementStyle(
        color: 0xFF79C0FF, // GitHub Dark blue
      ),
      SyntaxElementType.operator: SyntaxElementStyle(
        color: 0xFFFF7B72, // GitHub Dark red
      ),
      SyntaxElementType.function: SyntaxElementStyle(
        color: 0xFFD2A8FF, // GitHub Dark purple
        isBold: true,
      ),
      SyntaxElementType.variable: SyntaxElementStyle(
        color: 0xFFF0F6FC, // GitHub Dark white
      ),
      SyntaxElementType.type: SyntaxElementStyle(
        color: 0xFF79C0FF, // GitHub Dark blue
      ),
      SyntaxElementType.punctuation: SyntaxElementStyle(
        color: 0xFFF0F6FC, // GitHub Dark white
      ),
      SyntaxElementType.annotation: SyntaxElementStyle(
        color: 0xFF8B949E, // GitHub Dark gray
      ),
      SyntaxElementType.property: SyntaxElementStyle(
        color: 0xFF79C0FF, // GitHub Dark blue
      ),
      SyntaxElementType.constant: SyntaxElementStyle(
        color: 0xFF79C0FF, // GitHub Dark blue
        isBold: true,
      ),
      SyntaxElementType.parameter: SyntaxElementStyle(
        color: 0xFFFFA657, // GitHub Dark orange
      ),
      SyntaxElementType.namespace: SyntaxElementStyle(
        color: 0xFFD2A8FF, // GitHub Dark purple
      ),
      SyntaxElementType.tag: SyntaxElementStyle(
        color: 0xFF7EE787, // GitHub Dark green
      ),
      SyntaxElementType.attribute: SyntaxElementStyle(
        color: 0xFFD2A8FF, // GitHub Dark purple
      ),
      SyntaxElementType.selector: SyntaxElementStyle(
        color: 0xFFD2A8FF, // GitHub Dark purple
      ),
      SyntaxElementType.regex: SyntaxElementStyle(
        color: 0xFFA5D6FF, // GitHub Dark blue
      ),
      SyntaxElementType.escape: SyntaxElementStyle(
        color: 0xFFFFA657, // GitHub Dark orange
      ),
      SyntaxElementType.plain: SyntaxElementStyle(
        color: 0xFFF0F6FC, // GitHub Dark white
      ),
    },
    backgroundColor: 0xFF0D1117, // GitHub Dark background
    defaultTextColor: 0xFFF0F6FC, // GitHub Dark white
  );

  /// Get all predefined themes
  static List<SyntaxHighlightTheme> getAllThemes() {
    return [
      vsCodeLight,
      vsCodeDark,
      githubLight,
      githubDark,
    ];
  }

  /// Get theme by name
  static SyntaxHighlightTheme? getThemeByName(String name) {
    final themes = getAllThemes();
    try {
      return themes.firstWhere((theme) => theme.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get default theme based on dark mode
  static SyntaxHighlightTheme getDefaultTheme(bool isDark) {
    return isDark ? vsCodeDark : vsCodeLight;
  }

  /// Convert theme color to Flutter Color object
  static Color colorFromInt(int colorValue) {
    return Color(colorValue);
  }

  /// Get TextStyle based on syntax element type and theme
  static TextStyle getTextStyle(
    SyntaxElementType elementType,
    SyntaxHighlightTheme theme, {
    double? fontSize,
    String? fontFamily,
  }) {
    final elementStyle = theme.elementStyles[elementType];
    
    if (elementStyle == null) {
      return TextStyle(
        color: colorFromInt(theme.defaultTextColor),
        fontSize: fontSize,
        fontFamily: fontFamily,
      );
    }

    return TextStyle(
      color: colorFromInt(elementStyle.color),
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: elementStyle.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: elementStyle.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: elementStyle.isUnderlined ? TextDecoration.underline : TextDecoration.none,
      backgroundColor: elementStyle.backgroundColor != null 
          ? colorFromInt(elementStyle.backgroundColor!)
          : null,
    );
  }
}