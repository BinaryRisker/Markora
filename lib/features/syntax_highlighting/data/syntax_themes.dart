import 'package:flutter/material.dart';
import '../../../types/syntax_highlighting.dart';

/// 预定义的语法高亮主题
class SyntaxThemes {
  static const _lightThemeStyles = {
    SyntaxElementType.keyword: SyntaxElementStyle(
      color: 0xFF0000FF, // 蓝色
      isBold: true,
    ),
    SyntaxElementType.string: SyntaxElementStyle(
      color: 0xFF008000, // 绿色
    ),
    SyntaxElementType.comment: SyntaxElementStyle(
      color: 0xFF808080, // 灰色
      isItalic: true,
    ),
    SyntaxElementType.number: SyntaxElementStyle(
      color: 0xFFFF6600, // 橙色
    ),
    SyntaxElementType.operator: SyntaxElementStyle(
      color: 0xFF800080, // 紫色
    ),
    SyntaxElementType.function: SyntaxElementStyle(
      color: 0xFF795E26, // 棕色
      isBold: true,
    ),
    SyntaxElementType.variable: SyntaxElementStyle(
      color: 0xFF001080, // 深蓝色
    ),
    SyntaxElementType.type: SyntaxElementStyle(
      color: 0xFF267F99, // 青蓝色
    ),
    SyntaxElementType.punctuation: SyntaxElementStyle(
      color: 0xFF000000, // 黑色
    ),
    SyntaxElementType.annotation: SyntaxElementStyle(
      color: 0xFF808000, // 暗黄色
    ),
    SyntaxElementType.property: SyntaxElementStyle(
      color: 0xFF0451A5, // 深蓝色
    ),
    SyntaxElementType.constant: SyntaxElementStyle(
      color: 0xFF0000FF, // 蓝色
      isBold: true,
    ),
    SyntaxElementType.parameter: SyntaxElementStyle(
      color: 0xFF795E26, // 棕色
    ),
    SyntaxElementType.namespace: SyntaxElementStyle(
      color: 0xFF267F99, // 青蓝色
    ),
    SyntaxElementType.tag: SyntaxElementStyle(
      color: 0xFF800000, // 深红色
    ),
    SyntaxElementType.attribute: SyntaxElementStyle(
      color: 0xFF0000FF, // 蓝色
    ),
    SyntaxElementType.selector: SyntaxElementStyle(
      color: 0xFF800000, // 深红色
    ),
    SyntaxElementType.regex: SyntaxElementStyle(
      color: 0xFFD16969, // 红色
    ),
    SyntaxElementType.escape: SyntaxElementStyle(
      color: 0xFFD7BA7D, // 淡黄色
    ),
    SyntaxElementType.plain: SyntaxElementStyle(
      color: 0xFF000000, // 黑色
    ),
  };

  static const _darkThemeStyles = {
    SyntaxElementType.keyword: SyntaxElementStyle(
      color: 0xFF569CD6, // 亮蓝色
      isBold: true,
    ),
    SyntaxElementType.string: SyntaxElementStyle(
      color: 0xFFCE9178, // 淡橙色
    ),
    SyntaxElementType.comment: SyntaxElementStyle(
      color: 0xFF6A9955, // 绿色
      isItalic: true,
    ),
    SyntaxElementType.number: SyntaxElementStyle(
      color: 0xFFB5CEA8, // 淡绿色
    ),
    SyntaxElementType.operator: SyntaxElementStyle(
      color: 0xFFD4D4D4, // 淡白色
    ),
    SyntaxElementType.function: SyntaxElementStyle(
      color: 0xFFDCDCAA, // 淡黄色
      isBold: true,
    ),
    SyntaxElementType.variable: SyntaxElementStyle(
      color: 0xFF9CDCFE, // 淡蓝色
    ),
    SyntaxElementType.type: SyntaxElementStyle(
      color: 0xFF4EC9B0, // 青绿色
    ),
    SyntaxElementType.punctuation: SyntaxElementStyle(
      color: 0xFFD4D4D4, // 淡白色
    ),
    SyntaxElementType.annotation: SyntaxElementStyle(
      color: 0xFFDCDCAA, // 淡黄色
    ),
    SyntaxElementType.property: SyntaxElementStyle(
      color: 0xFF9CDCFE, // 淡蓝色
    ),
    SyntaxElementType.constant: SyntaxElementStyle(
      color: 0xFF569CD6, // 亮蓝色
      isBold: true,
    ),
    SyntaxElementType.parameter: SyntaxElementStyle(
      color: 0xFFDCDCAA, // 淡黄色
    ),
    SyntaxElementType.namespace: SyntaxElementStyle(
      color: 0xFF4EC9B0, // 青绿色
    ),
    SyntaxElementType.tag: SyntaxElementStyle(
      color: 0xFF569CD6, // 亮蓝色
    ),
    SyntaxElementType.attribute: SyntaxElementStyle(
      color: 0xFF92C5F8, // 浅蓝色
    ),
    SyntaxElementType.selector: SyntaxElementStyle(
      color: 0xFFD7BA7D, // 淡黄色
    ),
    SyntaxElementType.regex: SyntaxElementStyle(
      color: 0xFFD16969, // 红色
    ),
    SyntaxElementType.escape: SyntaxElementStyle(
      color: 0xFFD7BA7D, // 淡黄色
    ),
    SyntaxElementType.plain: SyntaxElementStyle(
      color: 0xFFD4D4D4, // 淡白色
    ),
  };

  /// VS Code Light 主题
  static const vsCodeLight = SyntaxHighlightTheme(
    name: 'VS Code Light',
    isDark: false,
    elementStyles: _lightThemeStyles,
    backgroundColor: 0xFFFFFFFF, // 白色背景
    defaultTextColor: 0xFF000000, // 黑色文字
  );

  /// VS Code Dark 主题
  static const vsCodeDark = SyntaxHighlightTheme(
    name: 'VS Code Dark',
    isDark: true,
    elementStyles: _darkThemeStyles,
    backgroundColor: 0xFF1E1E1E, // 深灰色背景
    defaultTextColor: 0xFFD4D4D4, // 淡白色文字
  );

  /// GitHub Light 主题
  static const githubLight = SyntaxHighlightTheme(
    name: 'GitHub Light',
    isDark: false,
    elementStyles: {
      SyntaxElementType.keyword: SyntaxElementStyle(
        color: 0xFFD73A49, // GitHub红色
        isBold: true,
      ),
      SyntaxElementType.string: SyntaxElementStyle(
        color: 0xFF032F62, // GitHub深蓝色
      ),
      SyntaxElementType.comment: SyntaxElementStyle(
        color: 0xFF6A737D, // GitHub灰色
        isItalic: true,
      ),
      SyntaxElementType.number: SyntaxElementStyle(
        color: 0xFF005CC5, // GitHub蓝色
      ),
      SyntaxElementType.operator: SyntaxElementStyle(
        color: 0xFFD73A49, // GitHub红色
      ),
      SyntaxElementType.function: SyntaxElementStyle(
        color: 0xFF6F42C1, // GitHub紫色
        isBold: true,
      ),
      SyntaxElementType.variable: SyntaxElementStyle(
        color: 0xFF24292E, // GitHub黑色
      ),
      SyntaxElementType.type: SyntaxElementStyle(
        color: 0xFF005CC5, // GitHub蓝色
      ),
      SyntaxElementType.punctuation: SyntaxElementStyle(
        color: 0xFF24292E, // GitHub黑色
      ),
      SyntaxElementType.annotation: SyntaxElementStyle(
        color: 0xFF6A737D, // GitHub灰色
      ),
      SyntaxElementType.property: SyntaxElementStyle(
        color: 0xFF005CC5, // GitHub蓝色
      ),
      SyntaxElementType.constant: SyntaxElementStyle(
        color: 0xFF005CC5, // GitHub蓝色
        isBold: true,
      ),
      SyntaxElementType.parameter: SyntaxElementStyle(
        color: 0xFFE36209, // GitHub橙色
      ),
      SyntaxElementType.namespace: SyntaxElementStyle(
        color: 0xFF6F42C1, // GitHub紫色
      ),
      SyntaxElementType.tag: SyntaxElementStyle(
        color: 0xFF22863A, // GitHub绿色
      ),
      SyntaxElementType.attribute: SyntaxElementStyle(
        color: 0xFF6F42C1, // GitHub紫色
      ),
      SyntaxElementType.selector: SyntaxElementStyle(
        color: 0xFF6F42C1, // GitHub紫色
      ),
      SyntaxElementType.regex: SyntaxElementStyle(
        color: 0xFF032F62, // GitHub深蓝色
      ),
      SyntaxElementType.escape: SyntaxElementStyle(
        color: 0xFFE36209, // GitHub橙色
      ),
      SyntaxElementType.plain: SyntaxElementStyle(
        color: 0xFF24292E, // GitHub黑色
      ),
    },
    backgroundColor: 0xFFFFFFFF, // 白色背景
    defaultTextColor: 0xFF24292E, // GitHub黑色
  );

  /// GitHub Dark 主题
  static const githubDark = SyntaxHighlightTheme(
    name: 'GitHub Dark',
    isDark: true,
    elementStyles: {
      SyntaxElementType.keyword: SyntaxElementStyle(
        color: 0xFFFF7B72, // GitHub Dark红色
        isBold: true,
      ),
      SyntaxElementType.string: SyntaxElementStyle(
        color: 0xFFA5D6FF, // GitHub Dark蓝色
      ),
      SyntaxElementType.comment: SyntaxElementStyle(
        color: 0xFF8B949E, // GitHub Dark灰色
        isItalic: true,
      ),
      SyntaxElementType.number: SyntaxElementStyle(
        color: 0xFF79C0FF, // GitHub Dark蓝色
      ),
      SyntaxElementType.operator: SyntaxElementStyle(
        color: 0xFFFF7B72, // GitHub Dark红色
      ),
      SyntaxElementType.function: SyntaxElementStyle(
        color: 0xFFD2A8FF, // GitHub Dark紫色
        isBold: true,
      ),
      SyntaxElementType.variable: SyntaxElementStyle(
        color: 0xFFF0F6FC, // GitHub Dark白色
      ),
      SyntaxElementType.type: SyntaxElementStyle(
        color: 0xFF79C0FF, // GitHub Dark蓝色
      ),
      SyntaxElementType.punctuation: SyntaxElementStyle(
        color: 0xFFF0F6FC, // GitHub Dark白色
      ),
      SyntaxElementType.annotation: SyntaxElementStyle(
        color: 0xFF8B949E, // GitHub Dark灰色
      ),
      SyntaxElementType.property: SyntaxElementStyle(
        color: 0xFF79C0FF, // GitHub Dark蓝色
      ),
      SyntaxElementType.constant: SyntaxElementStyle(
        color: 0xFF79C0FF, // GitHub Dark蓝色
        isBold: true,
      ),
      SyntaxElementType.parameter: SyntaxElementStyle(
        color: 0xFFFFA657, // GitHub Dark橙色
      ),
      SyntaxElementType.namespace: SyntaxElementStyle(
        color: 0xFFD2A8FF, // GitHub Dark紫色
      ),
      SyntaxElementType.tag: SyntaxElementStyle(
        color: 0xFF7EE787, // GitHub Dark绿色
      ),
      SyntaxElementType.attribute: SyntaxElementStyle(
        color: 0xFFD2A8FF, // GitHub Dark紫色
      ),
      SyntaxElementType.selector: SyntaxElementStyle(
        color: 0xFFD2A8FF, // GitHub Dark紫色
      ),
      SyntaxElementType.regex: SyntaxElementStyle(
        color: 0xFFA5D6FF, // GitHub Dark蓝色
      ),
      SyntaxElementType.escape: SyntaxElementStyle(
        color: 0xFFFFA657, // GitHub Dark橙色
      ),
      SyntaxElementType.plain: SyntaxElementStyle(
        color: 0xFFF0F6FC, // GitHub Dark白色
      ),
    },
    backgroundColor: 0xFF0D1117, // GitHub Dark背景
    defaultTextColor: 0xFFF0F6FC, // GitHub Dark白色
  );

  /// 获取所有预定义主题
  static List<SyntaxHighlightTheme> getAllThemes() {
    return [
      vsCodeLight,
      vsCodeDark,
      githubLight,
      githubDark,
    ];
  }

  /// 根据主题名称获取主题
  static SyntaxHighlightTheme? getThemeByName(String name) {
    final themes = getAllThemes();
    try {
      return themes.firstWhere((theme) => theme.name == name);
    } catch (e) {
      return null;
    }
  }

  /// 根据是否为深色主题获取默认主题
  static SyntaxHighlightTheme getDefaultTheme(bool isDark) {
    return isDark ? vsCodeDark : vsCodeLight;
  }

  /// 将主题颜色转换为Flutter Color对象
  static Color colorFromInt(int colorValue) {
    return Color(colorValue);
  }

  /// 根据语法元素类型和主题获取TextStyle
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