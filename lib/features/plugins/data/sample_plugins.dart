import '../../../types/plugin.dart';

/// Sample plugin data - 插件示例数据框架
/// 所有具体插件实现已移至 plugins/ 目录
class SamplePlugins {
  /// 获取示例插件列表 - 实际插件将从 plugins/ 目录动态加载
  static List<Plugin> getSamplePlugins() {
    // 返回空列表，插件将通过 PluginManager 从 plugins/ 目录动态加载
    return [];
  }
  
  /// 获取示例插件配置 - 实际配置将从插件目录读取
  static Map<String, PluginConfig> getSampleConfigs() {
    // 返回空配置，插件配置将从各插件目录的配置文件读取
    return {};
  }
}