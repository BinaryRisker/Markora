import '../../../types/plugin.dart';

/// Sample plugin data
class SamplePlugins {
  static List<Plugin> getSamplePlugins() {
    return [
      // Syntax plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'syntax-highlight-plus',
          name: 'Enhanced Syntax Highlighting',
          version: '1.2.0',
          description: 'Provides richer syntax highlighting support for Markdown editor, including multiple programming languages and themes.',
          author: 'Markora Team',
          type: PluginType.syntax,
          tags: ['Syntax Highlighting', 'Programming Languages', 'Themes'],
          homepage: 'https://github.com/markora/syntax-highlight-plus',
          repository: 'https://github.com/markora/syntax-highlight-plus',
          license: 'MIT',
          minVersion: '1.0.0',
          maxVersion: '2.0.0',
        ),
        status: PluginStatus.enabled,
        installPath: '/plugins/syntax-highlight-plus',
        installDate: DateTime.now().subtract(const Duration(days: 30)),
        lastUpdated: DateTime.now().subtract(const Duration(days: 25)),
      ),
      
      // Theme plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'dark-theme-pro',
          name: 'Professional Dark Theme',
          version: '2.1.3',
          description: 'Carefully designed dark theme providing comfortable night editing experience with multiple color schemes.',
          author: 'ThemeStudio',
          type: PluginType.theme,
          tags: ['Dark Theme', 'Night Mode', 'Eye Protection'],
          homepage: 'https://themestudio.com/dark-theme-pro',
          repository: 'https://github.com/themestudio/dark-theme-pro',
          license: 'Apache-2.0',
          minVersion: '1.0.0',
          maxVersion: '3.0.0',
        ),
        status: PluginStatus.enabled,
        installPath: '/plugins/dark-theme-pro',
        installDate: DateTime.now().subtract(const Duration(days: 15)),
        lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
      ),
      
      // Tool plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'table-editor',
          name: 'Table Editor',
          version: '1.5.2',
          description: 'Visual table editing tool supporting drag-and-drop adjustment, quick insertion and table formatting.',
          author: 'TableTools Inc.',
          type: PluginType.tool,
          tags: ['Table', 'Editor', 'Visual'],
          homepage: 'https://tabletools.com/editor',
          repository: 'https://github.com/tabletools/table-editor',
          license: 'MIT',
          minVersion: '1.0.0',
          maxVersion: '2.0.0',
        ),
        status: PluginStatus.installed,
        installPath: '/plugins/table-editor',
        installDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
      
      // Export plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'pdf-exporter',
          name: 'PDF Exporter',
          version: '3.0.1',
          description: 'High-quality PDF export functionality supporting custom styles, headers, footers and watermarks.',
          author: 'ExportMaster',
          type: PluginType.export,
          tags: ['PDF', 'Export', 'Print'],
          homepage: 'https://exportmaster.com/pdf',
          repository: 'https://github.com/exportmaster/pdf-exporter',
          license: 'Commercial',
          minVersion: '1.0.0',
          maxVersion: '4.0.0',
        ),
        status: PluginStatus.disabled,
        installPath: '/plugins/pdf-exporter',
        installDate: DateTime.now().subtract(const Duration(days: 120)),
        lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
      ),
      
      // Renderer plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'math-renderer',
          name: 'Math Formula Renderer',
          version: '2.3.0',
          description: 'Supports real-time rendering of LaTeX mathematical formulas, including inline and block formulas.',
          author: 'MathWorks',
          type: PluginType.renderer,
          tags: ['Math', 'LaTeX', 'Formula'],
          homepage: 'https://mathworks.com/renderer',
          repository: 'https://github.com/mathworks/math-renderer',
          license: 'BSD-3-Clause',
          minVersion: '1.0.0',
          maxVersion: '3.0.0',
        ),
        status: PluginStatus.enabled,
        installPath: '/plugins/math-renderer',
        installDate: DateTime.now().subtract(const Duration(days: 45)),
        lastUpdated: DateTime.now().subtract(const Duration(days: 40)),
      ),
      
      // Import plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'docx-importer',
          name: 'Word Document Importer',
          version: '1.8.5',
          description: 'Converts Microsoft Word documents to Markdown format while preserving original formatting and structure.',
          author: 'ConvertPro',
          type: PluginType.import,
          tags: ['Word', 'DOCX', 'Import', 'Convert'],
          homepage: 'https://convertpro.com/docx',
          repository: 'https://github.com/convertpro/docx-importer',
          license: 'GPL-3.0',
          minVersion: '1.0.0',
          maxVersion: '2.0.0',
        ),
        status: PluginStatus.installed,
        installPath: '/plugins/docx-importer',
        installDate: DateTime.now().subtract(const Duration(days: 12)),
      ),
      
      // Widget plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'mermaid-diagrams',
          name: 'Mermaid Diagrams',
          version: '4.2.1',
          description: 'Supports various diagram types including flowcharts, sequence diagrams, and Gantt charts using Mermaid syntax.',
          author: 'DiagramStudio',
          type: PluginType.widget,
          tags: ['Diagrams', 'Mermaid', 'Flowchart', 'Sequence'],
          homepage: 'https://diagramstudio.com/mermaid',
          repository: 'https://github.com/diagramstudio/mermaid-diagrams',
          license: 'MIT',
          minVersion: '1.0.0',
          maxVersion: '5.0.0',
        ),
        status: PluginStatus.enabled,
        installPath: '/plugins/mermaid-diagrams',
        installDate: DateTime.now().subtract(const Duration(days: 60)),
        lastUpdated: DateTime.now().subtract(const Duration(days: 55)),
      ),
      
      // Error status plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'broken-plugin',
          name: 'Broken Plugin',
          version: '0.1.0',
          description: 'This is a sample plugin for testing error status.',
          author: 'Test Author',
          type: PluginType.other,
          tags: ['Test', 'Error'],
          license: 'MIT',
          minVersion: '1.0.0',
          maxVersion: '2.0.0',
        ),
        status: PluginStatus.error,
        installPath: '/plugins/broken-plugin',
        installDate: DateTime.now().subtract(const Duration(days: 3)),
        errorMessage: 'Plugin initialization failed: missing required dependencies',
      ),
      
      // Loading status plugin
      Plugin(
        metadata: PluginMetadata(
          id: 'loading-plugin',
          name: 'Loading Plugin',
          version: '1.0.0',
          description: 'This is a sample plugin for testing loading status.',
          author: 'Test Author',
          type: PluginType.tool,
          tags: ['Test', 'Loading'],
          license: 'MIT',
          minVersion: '1.0.0',
          maxVersion: '2.0.0',
        ),
        status: PluginStatus.loading,
        installPath: '/plugins/loading-plugin',
        installDate: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }
  
  /// Get sample plugin configurations
  static Map<String, PluginConfig> getSampleConfigs() {
    return {
      'syntax-highlight-plus': PluginConfig(
        pluginId: 'syntax-highlight-plus',
        config: {
          'theme': 'monokai',
          'lineNumbers': true,
          'wordWrap': false,
          'fontSize': 14,
          'fontFamily': 'Fira Code',
        },
        isEnabled: true,
      ),
      'dark-theme-pro': PluginConfig(
        pluginId: 'dark-theme-pro',
        config: {
          'variant': 'deep-dark',
          'accentColor': '#007ACC',
          'borderRadius': 8,
          'animations': true,
        },
        isEnabled: true,
      ),
      'table-editor': PluginConfig(
        pluginId: 'table-editor',
        config: {
          'autoFormat': true,
          'showGridLines': true,
          'defaultColumns': 3,
          'defaultRows': 3,
        },
        isEnabled: false,
      ),
    };
  }
}