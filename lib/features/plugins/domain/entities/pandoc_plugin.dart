import 'package:flutter/material.dart';
import '../../../../types/plugin.dart';
import '../plugin_interface.dart';
import '../services/pandoc_service.dart';
import '../../presentation/widgets/pandoc_export_dialog.dart';
import '../../presentation/widgets/pandoc_import_dialog.dart';

/// Pandoc导出插件
class PandocExportPlugin extends MarkoraPlugin {
  static const String pluginId = 'pandoc_export_plugin';
  
  bool _isInitialized = false;
  PluginContext? _context;
  
  @override
  PluginMetadata get metadata => const PluginMetadata(
    id: pluginId,
    name: 'Pandoc Export',
    version: '1.0.0',
    description: 'Universal document converter using Pandoc',
    author: 'Markora Team',
    type: PluginType.export,
    minVersion: '1.0.0',
    license: 'MIT',
    tags: ['export', 'import', 'pandoc', 'converter'],
    dependencies: [],
  );
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    _context = context;
    _isInitialized = true;
    
    // 注册导出菜单项
    context.menuRegistry.registerMenuItem(
      'export_pandoc',
      'Export with Pandoc',
      () => _showExportDialog(),
      icon: 'export',
    );
    
    // 注册导入菜单项
    context.menuRegistry.registerMenuItem(
      'import_pandoc',
      'Import with Pandoc',
      () => _showImportDialog(),
      icon: 'import',
    );
    
    // 注册工具栏按钮
    context.toolbarRegistry.registerAction(
      PluginAction(
        id: 'pandoc_export',
        title: 'Export',
        description: 'Export document using Pandoc',
        icon: 'export',
      ),
      () => _showExportDialog(),
    );
  }
  
  @override
  Future<void> onUnload() async {
    _context?.menuRegistry.unregisterMenuItem('export_pandoc');
    _context?.menuRegistry.unregisterMenuItem('import_pandoc');
    _context?.toolbarRegistry.unregisterAction('pandoc_export');
    _isInitialized = false;
    _context = null;
  }
  
  @override
  Future<void> onActivate() async {
    // 激活插件时的逻辑
  }
  
  @override
  Future<void> onDeactivate() async {
    // 停用插件时的逻辑
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    // 配置更改时的逻辑
  }
  
  @override
  Widget? getConfigWidget() {
    return null; // 暂无配置界面
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'platform_supported': PandocService.isPlatformSupported(),
    };
  }
  
  /// 显示导出对话框
  void _showExportDialog() {
    if (_context?.editorController == null) return;
    
    // 获取当前编辑器内容
    final content = _context!.editorController.content;
    
    // 查找当前上下文中的Navigator
    final navigator = _findNavigator();
    if (navigator != null) {
      showDialog(
        context: navigator.context,
        builder: (context) => PandocExportDialog(
          markdownContent: content,
        ),
      );
    }
  }
  
  /// 显示导入对话框
  void _showImportDialog() {
    if (_context?.editorController == null) return;
    
    // 查找当前上下文中的Navigator
    final navigator = _findNavigator();
    if (navigator != null) {
      showDialog(
        context: navigator.context,
        builder: (context) => PandocImportDialog(
          onImportComplete: (markdownContent) {
            // 将导入的内容设置到编辑器
            _context!.editorController.setContent(markdownContent);
          },
        ),
      );
    }
  }
  
  /// 查找Navigator (临时解决方案)
  NavigatorState? _findNavigator() {
    // 这里需要根据实际的应用结构来获取Navigator
    // 这是一个简化的实现
    return null; // 待实现
  }
} 