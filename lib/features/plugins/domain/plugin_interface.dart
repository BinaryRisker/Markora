import 'package:flutter/widgets.dart';
import '../../../types/plugin.dart';

/// 编辑器控制器接口
abstract class EditorController {
  /// 获取当前文档内容
  String get content;
  
  /// 设置文档内容
  void setContent(String content);
  
  /// 在光标位置插入文本
  void insertText(String text);
  
  /// 获取选中的文本
  String get selectedText;
  
  /// 替换选中的文本
  void replaceSelection(String text);
  
  /// 获取光标位置
  int get cursorPosition;
  
  /// 设置光标位置
  void setCursorPosition(int position);
}

/// 语法注册器接口
abstract class SyntaxRegistry {
  /// 注册自定义语法规则
  void registerSyntax(String name, RegExp pattern, String replacement);
  
  /// 注册块级语法
  void registerBlockSyntax(String name, RegExp pattern, Widget Function(String content) builder);
  
  /// 注册行内语法
  void registerInlineSyntax(String name, RegExp pattern, Widget Function(String content) builder);
}

/// 工具栏注册器接口
abstract class ToolbarRegistry {
  /// 注册工具栏按钮
  void registerAction(PluginAction action, VoidCallback callback);
  
  /// 注册工具栏分组
  void registerGroup(String groupId, String title, List<PluginAction> actions);
  
  /// 移除工具栏按钮
  void unregisterAction(String actionId);
}

/// 菜单注册器接口
abstract class MenuRegistry {
  /// 注册菜单项
  void registerMenuItem(String menuId, String title, VoidCallback callback, {String? icon, String? shortcut});
  
  /// 注册子菜单
  void registerSubMenu(String parentId, String menuId, String title, List<String> items);
  
  /// 移除菜单项
  void unregisterMenuItem(String menuId);
}

/// 插件上下文
class PluginContext {
  const PluginContext({
    required this.editorController,
    required this.syntaxRegistry,
    required this.toolbarRegistry,
    required this.menuRegistry,
  });
  
  final EditorController editorController;
  final SyntaxRegistry syntaxRegistry;
  final ToolbarRegistry toolbarRegistry;
  final MenuRegistry menuRegistry;
}

/// Markora插件基类
abstract class MarkoraPlugin {
  /// 插件元数据
  PluginMetadata get metadata;
  
  /// 插件是否已初始化
  bool get isInitialized;
  
  /// 插件初始化
  Future<void> onLoad(PluginContext context);
  
  /// 插件卸载
  Future<void> onUnload();
  
  /// 插件激活
  Future<void> onActivate();
  
  /// 插件停用
  Future<void> onDeactivate();
  
  /// 处理配置变更
  void onConfigChanged(Map<String, dynamic> config);
  
  /// 获取插件配置界面
  Widget? getConfigWidget();
  
  /// 获取插件状态信息
  Map<String, dynamic> getStatus();
}

/// 插件生命周期事件
enum PluginLifecycleEvent {
  loading,
  loaded,
  activating,
  activated,
  deactivating,
  deactivated,
  unloading,
  unloaded,
  error,
}

/// 插件事件监听器
abstract class PluginEventListener {
  /// 插件生命周期事件
  void onPluginLifecycleEvent(String pluginId, PluginLifecycleEvent event, {String? error});
  
  /// 插件配置变更事件
  void onPluginConfigChanged(String pluginId, Map<String, dynamic> config);
  
  /// 插件状态变更事件
  void onPluginStatusChanged(String pluginId, PluginStatus oldStatus, PluginStatus newStatus);
}