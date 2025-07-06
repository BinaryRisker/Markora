import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../types/plugin.dart';
import 'plugin_interface.dart';

/// 编辑器控制器实现
class EditorControllerImpl implements EditorController {
  EditorControllerImpl(this._textController);
  
  final TextEditingController _textController;
  
  @override
  String get content => _textController.text;
  
  @override
  void setContent(String content) {
    _textController.text = content;
  }
  
  @override
  void insertText(String text) {
    final selection = _textController.selection;
    final newText = _textController.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
  }
  
  @override
  String get selectedText {
    final selection = _textController.selection;
    if (selection.isCollapsed) return '';
    return _textController.text.substring(selection.start, selection.end);
  }
  
  @override
  void replaceSelection(String text) {
    final selection = _textController.selection;
    final newText = _textController.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
  }
  
  @override
  int get cursorPosition => _textController.selection.start;
  
  @override
  void setCursorPosition(int position) {
    _textController.selection = TextSelection.collapsed(offset: position);
  }
}

/// 语法注册器实现
class SyntaxRegistryImpl implements SyntaxRegistry {
  final Map<String, SyntaxRule> _syntaxRules = {};
  final Map<String, BlockSyntaxRule> _blockSyntaxRules = {};
  final Map<String, InlineSyntaxRule> _inlineSyntaxRules = {};
  
  @override
  void registerSyntax(String name, RegExp pattern, String replacement) {
    _syntaxRules[name] = SyntaxRule(
      name: name,
      pattern: pattern,
      replacement: replacement,
    );
  }
  
  @override
  void registerBlockSyntax(String name, RegExp pattern, Widget Function(String content) builder) {
    _blockSyntaxRules[name] = BlockSyntaxRule(
      name: name,
      pattern: pattern,
      builder: builder,
    );
  }
  
  @override
  void registerInlineSyntax(String name, RegExp pattern, Widget Function(String content) builder) {
    _inlineSyntaxRules[name] = InlineSyntaxRule(
      name: name,
      pattern: pattern,
      builder: builder,
    );
  }
  
  /// 获取所有语法规则
  Map<String, SyntaxRule> get syntaxRules => Map.unmodifiable(_syntaxRules);
  
  /// 获取所有块级语法规则
  Map<String, BlockSyntaxRule> get blockSyntaxRules => Map.unmodifiable(_blockSyntaxRules);
  
  /// 获取所有行内语法规则
  Map<String, InlineSyntaxRule> get inlineSyntaxRules => Map.unmodifiable(_inlineSyntaxRules);
  
  /// 移除语法规则
  void removeSyntax(String name) {
    _syntaxRules.remove(name);
    _blockSyntaxRules.remove(name);
    _inlineSyntaxRules.remove(name);
  }
}

/// 工具栏注册器实现
class ToolbarRegistryImpl implements ToolbarRegistry {
  final Map<String, ToolbarActionItem> _actions = {};
  final Map<String, ToolbarGroup> _groups = {};
  final List<VoidCallback> _changeListeners = [];
  
  @override
  void registerAction(PluginAction action, VoidCallback callback) {
    _actions[action.id] = ToolbarActionItem(
      action: action,
      callback: callback,
    );
    _notifyListeners();
  }
  
  @override
  void registerGroup(String groupId, String title, List<PluginAction> actions) {
    _groups[groupId] = ToolbarGroup(
      id: groupId,
      title: title,
      actions: actions,
    );
    _notifyListeners();
  }
  
  @override
  void unregisterAction(String actionId) {
    _actions.remove(actionId);
    _notifyListeners();
  }
  
  /// 获取所有工具栏动作
  Map<String, ToolbarActionItem> get actions => Map.unmodifiable(_actions);
  
  /// 获取所有工具栏分组
  Map<String, ToolbarGroup> get groups => Map.unmodifiable(_groups);
  
  /// 添加变更监听器
  void addChangeListener(VoidCallback listener) {
    _changeListeners.add(listener);
  }
  
  /// 移除变更监听器
  void removeChangeListener(VoidCallback listener) {
    _changeListeners.remove(listener);
  }
  
  /// 通知监听器
  void _notifyListeners() {
    for (final listener in _changeListeners) {
      listener();
    }
  }
}

/// 菜单注册器实现
class MenuRegistryImpl implements MenuRegistry {
  final Map<String, MenuItem> _menuItems = {};
  final Map<String, SubMenu> _subMenus = {};
  final List<VoidCallback> _changeListeners = [];
  
  @override
  void registerMenuItem(String menuId, String title, VoidCallback callback, {String? icon, String? shortcut}) {
    _menuItems[menuId] = MenuItem(
      id: menuId,
      title: title,
      callback: callback,
      icon: icon,
      shortcut: shortcut,
    );
    _notifyListeners();
  }
  
  @override
  void registerSubMenu(String parentId, String menuId, String title, List<String> items) {
    _subMenus[menuId] = SubMenu(
      id: menuId,
      parentId: parentId,
      title: title,
      items: items,
    );
    _notifyListeners();
  }
  
  @override
  void unregisterMenuItem(String menuId) {
    _menuItems.remove(menuId);
    _subMenus.remove(menuId);
    _notifyListeners();
  }
  
  /// 获取所有菜单项
  Map<String, MenuItem> get menuItems => Map.unmodifiable(_menuItems);
  
  /// 获取所有子菜单
  Map<String, SubMenu> get subMenus => Map.unmodifiable(_subMenus);
  
  /// 添加变更监听器
  void addChangeListener(VoidCallback listener) {
    _changeListeners.add(listener);
  }
  
  /// 移除变更监听器
  void removeChangeListener(VoidCallback listener) {
    _changeListeners.remove(listener);
  }
  
  /// 通知监听器
  void _notifyListeners() {
    for (final listener in _changeListeners) {
      listener();
    }
  }
}

/// 语法规则
class SyntaxRule {
  const SyntaxRule({
    required this.name,
    required this.pattern,
    required this.replacement,
  });
  
  final String name;
  final RegExp pattern;
  final String replacement;
}

/// 块级语法规则
class BlockSyntaxRule {
  const BlockSyntaxRule({
    required this.name,
    required this.pattern,
    required this.builder,
  });
  
  final String name;
  final RegExp pattern;
  final Widget Function(String content) builder;
}

/// 行内语法规则
class InlineSyntaxRule {
  const InlineSyntaxRule({
    required this.name,
    required this.pattern,
    required this.builder,
  });
  
  final String name;
  final RegExp pattern;
  final Widget Function(String content) builder;
}

/// 工具栏动作项
class ToolbarActionItem {
  const ToolbarActionItem({
    required this.action,
    required this.callback,
  });
  
  final PluginAction action;
  final VoidCallback callback;
}

/// 工具栏分组
class ToolbarGroup {
  const ToolbarGroup({
    required this.id,
    required this.title,
    required this.actions,
  });
  
  final String id;
  final String title;
  final List<PluginAction> actions;
}

/// 菜单项
class MenuItem {
  const MenuItem({
    required this.id,
    required this.title,
    required this.callback,
    this.icon,
    this.shortcut,
  });
  
  final String id;
  final String title;
  final VoidCallback callback;
  final String? icon;
  final String? shortcut;
}

/// 子菜单
class SubMenu {
  const SubMenu({
    required this.id,
    required this.parentId,
    required this.title,
    required this.items,
  });
  
  final String id;
  final String parentId;
  final String title;
  final List<String> items;
}