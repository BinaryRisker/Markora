import 'package:flutter/material.dart';
import '../../../../types/plugin.dart';
import '../plugin_interface.dart';
import '../services/pandoc_service.dart';
import '../services/pandoc_asset_manager.dart';
import '../../presentation/widgets/pandoc_export_dialog.dart';
import '../../presentation/widgets/pandoc_import_dialog.dart';
import '../plugin_context_service.dart';

/// Pandoc导出插件
class PandocExportPlugin extends MarkoraPlugin {
  static const String pluginId = 'pandoc_export_plugin';
  
  bool _isInitialized = false;
  PluginContext? _context;
  final PandocAssetManager _assetManager = PandocAssetManager();
  
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
    debugPrint('PandocExportPlugin: Starting onLoad');
    _context = context;
    
    try {
      // 初始化Pandoc资源管理器
      debugPrint('PandocExportPlugin: Initializing Pandoc assets...');
      final assetInitialized = await _assetManager.initialize();
      debugPrint('PandocExportPlugin: Asset manager initialized: $assetInitialized');
      
      _isInitialized = true;
      // 注册导出菜单项
      debugPrint('PandocExportPlugin: Registering menu items');
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
      debugPrint('PandocExportPlugin: Registering toolbar action');
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'pandoc_export',
          title: 'Export',
          description: 'Export document using Pandoc',
          icon: 'export',
        ),
        () {
          debugPrint('PandocExportPlugin: Toolbar button clicked');
          _showExportDialog();
        },
      );
      
      debugPrint('PandocExportPlugin: onLoad completed successfully');
    } catch (e, stackTrace) {
      debugPrint('PandocExportPlugin: onLoad error: $e');
      debugPrint('PandocExportPlugin: Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  @override
  Future<void> onUnload() async {
    debugPrint('PandocExportPlugin: Starting onUnload');
    _context?.menuRegistry.unregisterMenuItem('export_pandoc');
    _context?.menuRegistry.unregisterMenuItem('import_pandoc');
    _context?.toolbarRegistry.unregisterAction('pandoc_export');
    _isInitialized = false;
    _context = null;
    debugPrint('PandocExportPlugin: onUnload completed');
  }
  
  @override
  Future<void> onActivate() async {
    debugPrint('PandocExportPlugin: onActivate called');
    // 激活插件时的逻辑
  }
  
  @override
  Future<void> onDeactivate() async {
    debugPrint('PandocExportPlugin: onDeactivate called');
    // 停用插件时的逻辑
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    debugPrint('PandocExportPlugin: Configuration changed: $config');
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
    debugPrint('PandocExportPlugin: _showExportDialog called');
    if (_context?.editorController == null) {
      debugPrint('PandocExportPlugin: Editor controller is null');
      return;
    }
    
    // 获取当前编辑器内容
    final content = _context!.editorController.content;
    debugPrint('PandocExportPlugin: Editor content length: ${content.length}');
    
    // 查找当前上下文中的Navigator
    final navigator = _findNavigator();
    if (navigator != null) {
      debugPrint('PandocExportPlugin: Showing export dialog');
      showDialog(
        context: navigator.context,
        builder: (context) => PandocExportDialog(
          markdownContent: content,
        ),
      );
    } else {
      debugPrint('PandocExportPlugin: Navigator not found');
    }
  }
  
  /// 显示导入对话框
  void _showImportDialog() {
    debugPrint('PandocExportPlugin: _showImportDialog called');
    if (_context?.editorController == null) {
      debugPrint('PandocExportPlugin: Editor controller is null');
      return;
    }
    
    // 查找当前上下文中的Navigator
    final navigator = _findNavigator();
    if (navigator != null) {
      debugPrint('PandocExportPlugin: Showing import dialog');
      showDialog(
        context: navigator.context,
        builder: (context) => PandocImportDialog(
          onImportComplete: (markdownContent) {
            debugPrint('PandocExportPlugin: Import completed, content length: ${markdownContent.length}');
            // 将导入的内容设置到编辑器
            _context!.editorController.setContent(markdownContent);
          },
        ),
      );
    } else {
      debugPrint('PandocExportPlugin: Navigator not found');
    }
  }
  
  /// 查找Navigator
  NavigatorState? _findNavigator() {
    try {
      // 尝试从全局导航器获取当前上下文
      final context = NavigatorService.navigatorKey.currentContext;
      if (context != null) {
        return Navigator.of(context);
      }
      
      debugPrint('PandocExportPlugin: Navigator context not found');
      return null;
    } catch (e) {
      debugPrint('PandocExportPlugin: Error finding navigator: $e');
      return null;
    }
  }
}

/// 全局导航器服务
class NavigatorService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
} 