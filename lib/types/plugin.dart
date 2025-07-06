import 'package:equatable/equatable.dart';

/// Plugin type enumeration
enum PluginType {
  syntax,       // Syntax plugin
  renderer,     // Renderer plugin
  theme,        // Theme plugin
  export,       // Export plugin
  exporter,     // Exporter plugin (alias)
  import,       // Import plugin
  tool,         // Tool plugin
  widget,       // Widget plugin
  component,    // Component plugin
  integration,  // Integration plugin
  other,        // Other plugin
}

/// Plugin type extension
extension PluginTypeExtension on PluginType {
  String get displayName {
    switch (this) {
      case PluginType.syntax:
        return 'Syntax Plugin';
      case PluginType.renderer:
        return 'Renderer Plugin';
      case PluginType.theme:
        return 'Theme Plugin';
      case PluginType.export:
        return 'Export Plugin';
      case PluginType.exporter:
        return 'Exporter Plugin';
      case PluginType.import:
        return 'Import Plugin';
      case PluginType.tool:
        return 'Tool Plugin';
      case PluginType.component:
        return 'Component Plugin';
      case PluginType.integration:
        return 'Integration Plugin';
      default:
        return 'Other Plugin';
    }
  }
}

/// Plugin status enumeration
enum PluginStatus {
  enabled,   // Enabled
  disabled,  // Disabled
  installed, // Installed but not enabled
  error,     // Error status
  loading,   // Loading
}

/// Plugin status extension
extension PluginStatusExtension on PluginStatus {
  String get displayName {
    switch (this) {
      case PluginStatus.enabled:
        return 'Enabled';
      case PluginStatus.disabled:
        return 'Disabled';
      case PluginStatus.installed:
        return 'Installed';
      case PluginStatus.error:
        return 'Error';
      case PluginStatus.loading:
        return 'Loading';
    }
  }
}

/// Plugin metadata
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

  /// Plugin unique identifier
  final String id;
  
  /// Plugin name
  final String name;
  
  /// Plugin version
  final String version;
  
  /// Plugin description
  final String description;
  
  /// Plugin author
  final String author;
  
  /// Plugin type
  final PluginType type;
  
  /// Minimum supported version
  final String minVersion;
  
  /// Maximum supported version
  final String? maxVersion;
  
  /// Plugin homepage
  final String? homepage;
  
  /// Code repository
  final String? repository;
  
  /// License
  final String license;
  
  /// Tag list
  final List<String> tags;
  
  /// Dependency plugin list
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

/// Plugin instance
class Plugin extends Equatable {
  const Plugin({
    required this.metadata,
    required this.status,
    this.installPath,
    this.installDate,
    this.lastUpdated,
    this.errorMessage,
  });

  /// Plugin metadata
  final PluginMetadata metadata;
  
  /// Plugin status
  final PluginStatus status;
  
  /// Installation path
  final String? installPath;
  
  /// Installation date
  final DateTime? installDate;
  
  /// Last update time
  final DateTime? lastUpdated;
  
  /// Error message
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

/// Plugin configuration
class PluginConfig extends Equatable {
  const PluginConfig({
    required this.pluginId,
    required this.config,
    this.isEnabled = true,
  });

  /// Plugin ID
  final String pluginId;
  
  /// Configuration data
  final Map<String, dynamic> config;
  
  /// Whether enabled
  final bool isEnabled;
  
  /// Settings data (compatibility alias)
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

/// Plugin action definition
class PluginAction extends Equatable {
  const PluginAction({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    this.shortcut,
    this.category,
  });

  /// Action ID
  final String id;
  
  /// Action title
  final String title;
  
  /// Action description
  final String description;
  
  /// Icon
  final String? icon;
  
  /// Shortcut key
  final String? shortcut;
  
  /// Category
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