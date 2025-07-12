import 'package:flutter/material.dart';
import '../../../types/plugin.dart';
import 'plugin_interface.dart';

/// External Pandoc Plugin Proxy
/// This class serves as a proxy to load and manage external Pandoc plugins
class ExternalPandocPluginProxy extends MarkoraPlugin {
  ExternalPandocPluginProxy(this._metadata, this._pluginPath);
  
  final PluginMetadata _metadata;
  final String _pluginPath;
  bool _isInitialized = false;
  PluginContext? _context;
  
  @override
  PluginMetadata get metadata => _metadata;
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<void> onLoad(PluginContext context) async {
    _context = context;
    
    try {
      // Here we would normally load the external plugin
      // For now, we'll create a simple proxy that provides export functionality
      
      // Register export toolbar action
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'pandoc_export',
          title: 'Export',
          description: 'Export document using Pandoc',
          icon: 'export',
        ),
        () => _showExportDialog(context),
      );
      
      // Register import toolbar action
      context.toolbarRegistry.registerAction(
        const PluginAction(
          id: 'pandoc_import',
          title: 'Import',
          description: 'Import document using Pandoc',
          icon: 'import',
        ),
        () => _showImportDialog(context),
      );
      
      _isInitialized = true;
      debugPrint('External Pandoc plugin proxy loaded successfully');
    } catch (e) {
      debugPrint('Failed to load external Pandoc plugin: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> onUnload() async {
    if (_context != null) {
      _context!.toolbarRegistry.unregisterAction('pandoc_export');
      _context!.toolbarRegistry.unregisterAction('pandoc_import');
    }
    _isInitialized = false;
  }
  
  @override
  Future<void> onActivate() async {
    // Plugin activated
  }
  
  @override
  Future<void> onDeactivate() async {
    // Plugin deactivated
  }
  
  @override
  void onConfigChanged(Map<String, dynamic> config) {
    // Configuration changed
  }
  
  @override
  Widget? getConfigWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pandoc Plugin Configuration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Plugin Path: $_pluginPath',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This is an external Pandoc plugin loaded from the plugins directory.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  @override
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'pluginPath': _pluginPath,
      'type': 'external',
    };
  }
  
  void _showExportDialog(PluginContext context) {
    // Show a placeholder dialog for now
    showDialog(
      context: context.context,
      builder: (context) => AlertDialog(
        title: const Text('Pandoc Export'),
        content: const Text('External Pandoc plugin export functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showImportDialog(PluginContext context) {
    // Show a placeholder dialog for now
    showDialog(
      context: context.context,
      builder: (context) => AlertDialog(
        title: const Text('Pandoc Import'),
        content: const Text('External Pandoc plugin import functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 