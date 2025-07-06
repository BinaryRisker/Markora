import 'package:equatable/equatable.dart';

/// 插件类型枚举
enum PluginType {
  syntax,       // 语法插件
  renderer,     // 渲染器插件
  theme,        // 主题插件
  export,       // 导出插件
  exporter,     // 导出器插件（别名）
  import,       // 导入插件
  tool,         // 工具插件
  widget,       // 组件插件
  integration,  // 集成插件
  other,        // 其他插件
}

/// 插件类型扩展
extension PluginTypeExtension on PluginType {
  String get displayName {
    switch (this) {
      case PluginType.syntax:
        return '语法插件';
      case PluginType.renderer:
        return '渲染器插件';
      case PluginType.theme:
        return '主题插件';
      case PluginType.export:
        return '导出插件';
      case PluginType.exporter:
        return '导出器插件';
      case PluginType.import:
        return '导入插件';
      case PluginType.tool:
        return '工具插件';
      case PluginType.widget:
        return '组件插件';
      case PluginType.integration:
        return '集成插件';
      case PluginType.other:
        return '其他插件';
    }
  }
}

/// 插件状态枚举
enum PluginStatus {
  enabled,   // 已启用
  disabled,  // 已禁用
  installed, // 已安装但未启用
  error,     // 错误状态
  loading,   // 加载中
}

/// 插件状态扩展
extension PluginStatusExtension on PluginStatus {
  String get displayName {
    switch (this) {
      case PluginStatus.enabled:
        return '已启用';
      case PluginStatus.disabled:
        return '已禁用';
      case PluginStatus.installed:
        return '已安装';
      case PluginStatus.error:
        return '错误';
      case PluginStatus.loading:
        return '加载中';
    }
  }
}

/// 插件元数据
class PluginMetadata extends Equatable {
  const PluginMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.type,
    required this.minVersion,
    this.maxVersion,
    this.homepage,
    this.repository,
    this.license = 'MIT',
    this.tags = const [],
    this.dependencies = const [],
  });

  /// 插件唯一标识
  final String id;
  
  /// 插件名称
  final String name;
  
  /// 插件版本
  final String version;
  
  /// 插件描述
  final String description;
  
  /// 插件作者
  final String author;
  
  /// 插件类型
  final PluginType type;
  
  /// 最小支持版本
  final String minVersion;
  
  /// 最大支持版本
  final String? maxVersion;
  
  /// 插件主页
  final String? homepage;
  
  /// 代码仓库
  final String? repository;
  
  /// 许可证
  final String license;
  
  /// 标签列表
  final List<String> tags;
  
  /// 依赖插件列表
  final List<String> dependencies;

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        description,
        author,
        type,
        minVersion,
        maxVersion,
        homepage,
        repository,
        license,
        tags,
        dependencies,
      ];
}

/// 插件实例
class Plugin extends Equatable {
  const Plugin({
    required this.metadata,
    required this.status,
    this.installPath,
    this.installDate,
    this.lastUpdated,
    this.errorMessage,
  });

  /// 插件元数据
  final PluginMetadata metadata;
  
  /// 插件状态
  final PluginStatus status;
  
  /// 安装路径
  final String? installPath;
  
  /// 安装日期
  final DateTime? installDate;
  
  /// 最后更新时间
  final DateTime? lastUpdated;
  
  /// 错误信息
  final String? errorMessage;

  Plugin copyWith({
    PluginMetadata? metadata,
    PluginStatus? status,
    String? installPath,
    DateTime? installDate,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return Plugin(
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      installPath: installPath ?? this.installPath,
      installDate: installDate ?? this.installDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        metadata,
        status,
        installPath,
        installDate,
        lastUpdated,
        errorMessage,
      ];
}

/// 插件配置
class PluginConfig extends Equatable {
  const PluginConfig({
    required this.pluginId,
    required this.config,
    this.isEnabled = true,
  });

  /// 插件ID
  final String pluginId;
  
  /// 配置数据
  final Map<String, dynamic> config;
  
  /// 是否启用
  final bool isEnabled;
  
  /// 设置数据（兼容性别名）
  Map<String, dynamic> get settings => config;

  PluginConfig copyWith({
    String? pluginId,
    Map<String, dynamic>? config,
    bool? isEnabled,
  }) {
    return PluginConfig(
      pluginId: pluginId ?? this.pluginId,
      config: config ?? this.config,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object> get props => [pluginId, config, isEnabled];
}

/// 插件动作定义
class PluginAction extends Equatable {
  const PluginAction({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    this.shortcut,
    this.category,
  });

  /// 动作ID
  final String id;
  
  /// 动作标题
  final String title;
  
  /// 动作描述
  final String description;
  
  /// 图标
  final String? icon;
  
  /// 快捷键
  final String? shortcut;
  
  /// 分类
  final String? category;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        icon,
        shortcut,
        category,
      ];
}