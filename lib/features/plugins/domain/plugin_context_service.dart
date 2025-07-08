import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'plugin_interface.dart';
import 'plugin_implementations.dart';

/// Global plugin context service
class PluginContextService {
  static PluginContextService? _instance;
  static PluginContextService get instance => _instance ??= PluginContextService._();
  
  PluginContextService._();
  
  late ToolbarRegistryImpl _toolbarRegistry;
  late SyntaxRegistryImpl _syntaxRegistry;
  late MenuRegistryImpl _menuRegistry;
  EditorController? _editorController;
  
  /// Initialize the plugin context service
  void initialize() {
    _toolbarRegistry = ToolbarRegistryImpl();
    _syntaxRegistry = SyntaxRegistryImpl();
    _menuRegistry = MenuRegistryImpl();
  }
  
  /// Set the current editor controller
  void setEditorController(EditorController controller) {
    _editorController = controller;
  }
  
  /// Get the plugin context
  PluginContext get context {
    return PluginContext(
      editorController: _editorController ?? _DummyEditorController(),
      syntaxRegistry: _syntaxRegistry,
      toolbarRegistry: _toolbarRegistry,
      menuRegistry: _menuRegistry,
    );
  }
  
  /// Get toolbar registry
  ToolbarRegistryImpl get toolbarRegistry => _toolbarRegistry;
  
  /// Get syntax registry
  SyntaxRegistryImpl get syntaxRegistry => _syntaxRegistry;
  
  /// Get menu registry
  MenuRegistryImpl get menuRegistry => _menuRegistry;
}

/// Dummy editor controller for fallback
class _DummyEditorController implements EditorController {
  @override
  String get content => '';
  
  @override
  void setContent(String content) {
    debugPrint('DummyEditorController.setContent called (no editor attached)');
  }
  
  @override
  void insertText(String text) {
    debugPrint('DummyEditorController.insertText called: $text (no editor attached)');
  }
  
  @override
  String get selectedText => '';
  
  @override
  void replaceSelection(String text) {
    debugPrint('DummyEditorController.replaceSelection called (no editor attached)');
  }
  
  @override
  int get cursorPosition => 0;
  
  @override
  void setCursorPosition(int position) {
    debugPrint('DummyEditorController.setCursorPosition called (no editor attached)');
  }
}

/// Provider for plugin context service
final pluginContextServiceProvider = Provider<PluginContextService>((ref) {
  return PluginContextService.instance;
}); 