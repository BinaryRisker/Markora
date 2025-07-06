import '../../../types/plugin.dart';

/// 示例插件数据
class SamplePlugins {
  static List<Plugin> getSamplePlugins() {
    return [
      // 语法插件
      Plugin(
        metadata: PluginMetadata(
          id: 'syntax-highlight-plus',
          name: '语法高亮增强',
          version: '1.2.0',
          description: '为 Markdown 编辑器提供更丰富的语法高亮支持，包括多种编程语言和主题。',
          author: 'Markora Team',
          type: PluginType.syntax,
          tags: ['语法高亮', '编程语言', '主题'],
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
      
      // 主题插件
      Plugin(
        metadata: PluginMetadata(
          id: 'dark-theme-pro',
          name: '专业暗色主题',
          version: '2.1.3',
          description: '精心设计的暗色主题，提供舒适的夜间编辑体验，支持多种配色方案。',
          author: 'ThemeStudio',
          type: PluginType.theme,
          tags: ['暗色主题', '夜间模式', '护眼'],
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
      
      // 工具插件
      Plugin(
        metadata: PluginMetadata(
          id: 'table-editor',
          name: '表格编辑器',
          version: '1.5.2',
          description: '可视化表格编辑工具，支持拖拽调整、快速插入和格式化表格。',
          author: 'TableTools Inc.',
          type: PluginType.tool,
          tags: ['表格', '编辑器', '可视化'],
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
      
      // 导出插件
      Plugin(
        metadata: PluginMetadata(
          id: 'pdf-exporter',
          name: 'PDF 导出器',
          version: '3.0.1',
          description: '高质量 PDF 导出功能，支持自定义样式、页眉页脚和水印。',
          author: 'ExportMaster',
          type: PluginType.export,
          tags: ['PDF', '导出', '打印'],
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
      
      // 渲染器插件
      Plugin(
        metadata: PluginMetadata(
          id: 'math-renderer',
          name: '数学公式渲染器',
          version: '2.3.0',
          description: '支持 LaTeX 数学公式的实时渲染，包括行内公式和块级公式。',
          author: 'MathWorks',
          type: PluginType.renderer,
          tags: ['数学', 'LaTeX', '公式'],
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
      
      // 导入插件
      Plugin(
        metadata: PluginMetadata(
          id: 'docx-importer',
          name: 'Word 文档导入器',
          version: '1.8.5',
          description: '将 Microsoft Word 文档转换为 Markdown 格式，保持原有格式和结构。',
          author: 'ConvertPro',
          type: PluginType.import,
          tags: ['Word', 'DOCX', '导入', '转换'],
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
      
      // 组件插件
      Plugin(
        metadata: PluginMetadata(
          id: 'mermaid-diagrams',
          name: 'Mermaid 图表',
          version: '4.2.1',
          description: '支持 Mermaid 语法的流程图、时序图、甘特图等多种图表类型。',
          author: 'DiagramStudio',
          type: PluginType.widget,
          tags: ['图表', 'Mermaid', '流程图', '时序图'],
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
      
      // 错误状态插件
      Plugin(
        metadata: PluginMetadata(
          id: 'broken-plugin',
          name: '损坏的插件',
          version: '0.1.0',
          description: '这是一个用于测试错误状态的示例插件。',
          author: 'Test Author',
          type: PluginType.other,
          tags: ['测试', '错误'],
          license: 'MIT',
          minVersion: '1.0.0',
          maxVersion: '2.0.0',
        ),
        status: PluginStatus.error,
        installPath: '/plugins/broken-plugin',
        installDate: DateTime.now().subtract(const Duration(days: 3)),
        errorMessage: '插件初始化失败：缺少必要的依赖项',
      ),
      
      // 加载中状态插件
      Plugin(
        metadata: PluginMetadata(
          id: 'loading-plugin',
          name: '正在加载的插件',
          version: '1.0.0',
          description: '这是一个用于测试加载状态的示例插件。',
          author: 'Test Author',
          type: PluginType.tool,
          tags: ['测试', '加载'],
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
  
  /// 获取插件配置示例
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