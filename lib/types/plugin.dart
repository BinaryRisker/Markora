import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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
  
  String getLocalizedDisplayName(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case PluginType.syntax:
        return localizations.syntaxPlugin;
      case PluginType.renderer:
        return localizations.rendererPlugin;
      case PluginType.theme:
        return localizations.themePlugin;
      case PluginType.export:
        return localizations.exportPlugin;
      case PluginType.exporter:
        return localizations.exporterPlugin;
      case PluginType.import:
        return localizations.importPlugin;
      case PluginType.tool:
        return localizations.toolPlugin;
      case PluginType.widget:
        return localizations.widgetPlugin;
      case PluginType.component:
        return localizations.componentPlugin;
      case PluginType.integration:
        return localizations.integrationPlugin;
      default:
        return localizations.otherPlugin;
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
  
  String getLocalizedDisplayName(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case PluginStatus.enabled:
        return localizations.enabledStatus;
      case PluginStatus.disabled:
        return localizations.disabledStatus;
      case PluginStatus.installed:
        return localizations.installedStatus;
      case PluginStatus.error:
        return localizations.errorStatus;
      case PluginStatus.loading:
        return localizations.loadingStatus;
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

/// Plugin sort method
enum PluginSortBy {
  name,
  author,
  type,
  status,
  installDate,
  lastUpdated,
}

/// Plugin sort method extension
extension PluginSortByExtension on PluginSortBy {
  String getLocalizedDisplayName(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (this) {
      case PluginSortBy.name:
        return localizations.pluginName;
      case PluginSortBy.author:
        return localizations.author;
      case PluginSortBy.type:
        return localizations.pluginType;
      case PluginSortBy.status:
        return localizations.status;
      case PluginSortBy.installDate:
        return localizations.installDate;
      case PluginSortBy.lastUpdated:
        return localizations.lastUpdated;
    }
  }
}

/// Plugin statistics (alias for PluginStats)
typedef PluginStatistics = PluginStats;

/// Plugin statistics class
class PluginStats {
  const PluginStats({
    required this.total,
    required this.enabled,
    required this.disabled,
    required this.installed,
    required this.error,
    required this.pluginsByType,
  });
  
  final int total;
  final int enabled;
  final int disabled;
  final int installed;
  final int error;
  final Map<PluginType, int> pluginsByType;
  
  int get inactive => disabled + installed;
}