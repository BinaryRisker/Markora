import '../../../types/plugin.dart';
import 'plugin_factory.dart';
import 'plugin_interface.dart';

/// Plugin registry initializer
class PluginRegistryInitializer {
  /// Initialize all built-in plugin factories
  static void initializeBuiltInPlugins() {
    // Register Mermaid plugin factory
    PluginFactory.registerFactory(
      'com.markora.mermaid',
      () => PluginFactory.createPlugin(
        PluginMetadata(
          id: 'com.markora.mermaid',
          name: 'Mermaid Charts',
          version: '1.0.0',
          description: 'Create beautiful diagrams and flowcharts using Mermaid syntax',
          author: 'Markora Team',
          type: PluginType.widget,
          supportedPlatforms: ['windows', 'macos', 'linux', 'web'],
          minVersion: '1.0.0',
        ),
      ),
    );
    
    // Register Pandoc plugin factory
    PluginFactory.registerFactory(
      'com.markora.pandoc',
      () => PluginFactory.createPlugin(
        PluginMetadata(
          id: 'com.markora.pandoc',
          name: 'Pandoc Converter',
          version: '1.0.0',
          description: 'Convert documents between various formats using Pandoc',
          author: 'Markora Team',
          type: PluginType.exporter,
          supportedPlatforms: ['windows', 'macos', 'linux'],
          minVersion: '1.0.0',
        ),
      ),
    );
    
    print('Built-in plugins registered: ${PluginFactory.getRegisteredPluginIds()}');
  }
  
  /// Register external plugin factory
  static void registerExternalPlugin(
    String pluginId,
    PluginMetadata metadata,
    MarkoraPlugin Function() factory,
  ) {
    PluginFactory.registerFactory(pluginId, factory);
    print('External plugin registered: $pluginId');
  }
  
  /// Unregister plugin factory
  static void unregisterPlugin(String pluginId) {
    PluginFactory.unregisterFactory(pluginId);
    print('Plugin unregistered: $pluginId');
  }
  
  /// Get all registered plugin IDs
  static List<String> getRegisteredPlugins() {
    return PluginFactory.getRegisteredPluginIds();
  }
  
  /// Check if plugin is registered
  static bool isPluginRegistered(String pluginId) {
    return PluginFactory.isRegistered(pluginId);
  }
}