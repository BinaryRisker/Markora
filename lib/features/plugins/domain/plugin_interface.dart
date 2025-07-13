import 'package:flutter/widgets.dart';
import '../../../types/plugin.dart';

/// Editor controller interface
abstract class EditorController {
  /// Get current document content
  String get content;
  
  /// Get current document content (method version for plugin compatibility)
  String getCurrentContent();
  
  /// Set document content
  void setContent(String content);
  
  /// Insert text at cursor position
  void insertText(String text);
  
  /// Get selected text
  String get selectedText;
  
  /// Replace selected text
  void replaceSelection(String text);
  
  /// Get cursor position
  int get cursorPosition;
  
  /// Set cursor position
  void setCursorPosition(int position);
}

/// Syntax registry interface
abstract class SyntaxRegistry {
  /// Register custom syntax rules
  void registerSyntax(String name, RegExp pattern, String replacement);
  
  /// Register block syntax
  void registerBlockSyntax(String name, RegExp pattern, Widget Function(String content) builder);
  
  /// Register inline syntax
  void registerInlineSyntax(String name, RegExp pattern, Widget Function(String content) builder);
  
  /// Remove syntax rule
  void removeSyntax(String name);
}

/// Toolbar registry interface
abstract class ToolbarRegistry {
  /// Register toolbar button
  void registerAction(PluginAction action, VoidCallback callback);
  
  /// Register toolbar group
  void registerGroup(String groupId, String title, List<PluginAction> actions);
  
  /// Remove toolbar button
  void unregisterAction(String actionId);

  /// Add a listener for when the registry changes.
  void addChangeListener(VoidCallback listener);

  /// Remove a previously registered listener.
  void removeChangeListener(VoidCallback listener);
}

/// Menu registry interface
abstract class MenuRegistry {
  /// Register menu item
  void registerMenuItem(String menuId, String title, VoidCallback callback, {String? icon, String? shortcut});
  
  /// Register submenu
  void registerSubMenu(String parentId, String menuId, String title, List<String> items);
  
  /// Remove menu item
  void unregisterMenuItem(String menuId);
}

/// Plugin context
class PluginContext {
  const PluginContext({
    required this.editorController,
    required this.syntaxRegistry,
    required this.toolbarRegistry,
    required this.menuRegistry,
    this.context,
  });
  
  final EditorController editorController;
  final SyntaxRegistry syntaxRegistry;
  final ToolbarRegistry toolbarRegistry;
  final MenuRegistry menuRegistry;
  final BuildContext? context;
}

/// Markora plugin base class
abstract class MarkoraPlugin {
  /// Plugin metadata
  PluginMetadata get metadata;
  
  /// Whether plugin is initialized
  bool get isInitialized;
  
  /// Plugin initialization
  Future<void> onLoad(PluginContext context);
  
  /// Plugin unload
  Future<void> onUnload();
  
  /// Plugin activation
  Future<void> onActivate();
  
  /// Plugin deactivation
  Future<void> onDeactivate();
  
  /// Handle configuration changes
  void onConfigChanged(Map<String, dynamic> config);
  
  /// Get plugin configuration interface
  Widget? getConfigWidget();
  
  /// Get plugin status information
  Map<String, dynamic> getStatus();
}

/// Plugin lifecycle events
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

/// Plugin event listener
abstract class PluginEventListener {
  /// Plugin lifecycle events
  void onPluginLifecycleEvent(String pluginId, PluginLifecycleEvent event, {String? error});
  
  /// Plugin configuration change events
  void onPluginConfigChanged(String pluginId, Map<String, dynamic> config);
  
  /// Plugin status change events
  void onPluginStatusChanged(String pluginId, PluginStatus oldStatus, PluginStatus newStatus);
}

/// Base plugin implementation
abstract class BasePlugin implements MarkoraPlugin {
  late PluginContext _context;
  bool _isInitialized = false;
  
  @override
  bool get isInitialized => _isInitialized;
  
  /// Plugin metadata - must be implemented by subclasses
  @override
  PluginMetadata get metadata;
  
  /// Get plugin context
  PluginContext get context => _context;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    _context = context;
    _isInitialized = true;
  }
  
  @override
  Future<void> onUnload() async {
    _isInitialized = false;
  }
  
  @override
  Future<void> onActivate() async {
    // Default implementation - can be overridden
  }
  
  @override
  Future<void> onDeactivate() async {
    // Default implementation - can be overridden
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    // Default implementation - can be overridden
  }
  
  @override
  Widget? getConfigWidget() {
    // Default implementation - can be overridden
    return null;
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'pluginId': metadata.id,
      'version': metadata.version,
    };
  }
}