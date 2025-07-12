import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'plugin_interface.dart';
import 'plugin_implementations.dart';

/// Global plugin context service
class PluginContextService {
  static PluginContextService? _instance;
  static PluginContextService get instance => _instance ??= PluginContextService._();
  
  PluginContextService._();
  
  ToolbarRegistryImpl? _toolbarRegistry;
  SyntaxRegistryImpl? _syntaxRegistry;
  MenuRegistryImpl? _menuRegistry;
  EditorController? _editorController;
  BuildContext? _context;
  bool _isInitialized = false;
  
  /// Initialize the plugin context service
  void initialize() {
    if (_isInitialized) return;
    
    _toolbarRegistry = ToolbarRegistryImpl();
    _syntaxRegistry = SyntaxRegistryImpl();
    _menuRegistry = MenuRegistryImpl();
    _isInitialized = true;
    debugPrint('PluginContextService initialized successfully');
  }
  
  /// Ensure initialization before accessing registries
  void _ensureInitialized() {
    if (!_isInitialized) {
      initialize();
    }
  }
  
  /// Set the current editor controller
  void setEditorController(EditorController controller) {
    _editorController = controller;
    debugPrint('Plugin context service: Editor controller set to ${controller.runtimeType}');
  }
  
  /// Set the current build context
  void setBuildContext(BuildContext context) {
    _context = context;
    debugPrint('Plugin context service: Build context set');
  }
  
  /// Get the plugin context
  PluginContext get context {
    _ensureInitialized();
    final controller = _editorController ?? _DummyEditorController();
    debugPrint('Plugin context requested: using ${controller.runtimeType}');
    return PluginContext(
      editorController: controller,
      syntaxRegistry: _syntaxRegistry!,
      toolbarRegistry: _toolbarRegistry!,
      menuRegistry: _menuRegistry!,
      context: _context,
    );
  }
  
  /// Get current document name (simplified approach)
  String getCurrentDocumentName() {
    // This is a simplified implementation
    // In a real implementation, you'd access the document provider
    return 'document'; // Default name for now
  }
  
  /// Get toolbar registry
  ToolbarRegistryImpl get toolbarRegistry {
    _ensureInitialized();
    return _toolbarRegistry!;
  }
  
  /// Get syntax registry
  SyntaxRegistryImpl get syntaxRegistry {
    _ensureInitialized();
    return _syntaxRegistry!;
  }
  
  /// Get menu registry
  MenuRegistryImpl get menuRegistry {
    _ensureInitialized();
    return _menuRegistry!;
  }
}

/// Dummy editor controller for fallback
class _DummyEditorController implements EditorController {
  @override
  String get content => '';
  
  @override
  String getCurrentContent() => '';
  
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