import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Defines a command contributed by a plugin.
class CommandContribution extends Equatable {
  const CommandContribution({required this.command, required this.title});

  final String command;
  final String title;

  factory CommandContribution.fromJson(Map<String, dynamic> json) {
    return CommandContribution(
      command: json['command'] as String,
      title: json['title'] as String,
    );
  }

  @override
  List<Object?> get props => [command, title];
}

/// Defines a toolbar item contributed by a plugin.
class ToolbarContribution extends Equatable {
  const ToolbarContribution({
    required this.command,
    required this.title,
    this.description,
    this.icon,
    this.phosphorIcon,
    this.group,
  });

  final String command;
  final String title;
  final String? description;
  final String? icon;
  final String? phosphorIcon;
  final String? group;

  factory ToolbarContribution.fromJson(Map<String, dynamic> json) {
    return ToolbarContribution(
      command: json['command'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      phosphorIcon: json['phosphorIcon'] as String?,
      group: json['group'] as String?,
    );
  }

  @override
  List<Object?> get props => [command, title, description, icon, phosphorIcon, group];
}

/// Defines all contributions made by a plugin.
class PluginContributions extends Equatable {
  const PluginContributions({
    this.commands = const [],
    this.toolbar = const [],
    this.menus = const {},
  });

  final List<CommandContribution> commands;
  final List<ToolbarContribution> toolbar;
  final Map<String, List<ToolbarContribution>> menus; // Reusing ToolbarContribution for menu items

  factory PluginContributions.fromJson(Map<String, dynamic> json) {
    return PluginContributions(
      commands: (json['commands'] as List<dynamic>? ?? [])
          .map((c) => CommandContribution.fromJson(c as Map<String, dynamic>))
          .toList(),
      toolbar: (json['toolbar'] as List<dynamic>? ?? [])
          .map((t) => ToolbarContribution.fromJson(t as Map<String, dynamic>))
          .toList(),
      menus: (json['menus'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((v) => ToolbarContribution.fromJson(v as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [commands, toolbar, menus];
}

// -- START: New EntryPoint class --
class EntryPoint extends Equatable {
  const EntryPoint({required this.type, this.platforms = const {}});

  final String type;
  final Map<String, String> platforms;

  factory EntryPoint.fromJson(Map<String, dynamic> json) {
    // The 'path' property is a shortcut for a single-platform executable
    if (json.containsKey('path')) {
      return EntryPoint(
        type: json['type'] as String? ?? 'executable',
        platforms: {'default': json['path'] as String},
      );
    }
    
    return EntryPoint(
      type: json['type'] as String,
      platforms: (json..remove('type'))
          .map((key, value) => MapEntry(key, value as String)),
    );
  }

  @override
  List<Object?> get props => [type, platforms];
}
// -- END: New EntryPoint class --

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
      case PluginType.widget:
        return 'Widget Plugin';
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
  unsupported, // Unsupported on current platform
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
      case PluginStatus.unsupported:
        return 'Unsupported';
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
      case PluginStatus.unsupported:
        return localizations.unsupportedStatus;
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
    this.supportedPlatforms = const [],
    this.contributes, // Add contributes field
    this.entryPoint, // Add entryPoint
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

  /// Supported platforms
  final List<String> supportedPlatforms;

  /// Plugin contributions
  final PluginContributions? contributes;

  /// Plugin entry point
  final EntryPoint? entryPoint;

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
        supportedPlatforms,
        contributes, // Add to props
        entryPoint, // Add to props
      ];

  /// Create PluginMetadata from JSON
  factory PluginMetadata.fromJson(Map<String, dynamic> json) {
    return PluginMetadata(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unnamed Plugin',
      version: json['version'] as String? ?? '0.0.0',
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'Unknown Author',
      type: _parsePluginType(json['type'] as String? ?? json['pluginType'] as String? ?? 'other'),
      minVersion: json['minVersion'] as String? ?? json['minAppVersion'] as String? ?? '1.0.0',
      maxVersion: json['maxVersion'] as String?,
      homepage: json['homepage'] as String?,
      repository: json['repository'] as String?,
      license: json['license'] as String? ?? 'MIT',
      tags: List<String>.from(json['tags'] as List? ?? []),
      dependencies: List<String>.from(json['dependencies'] as List? ?? []),
      supportedPlatforms: List<String>.from(json['supportedPlatforms'] as List? ?? json['platforms'] as List? ?? []),
      contributes: json['contributes'] != null
          ? PluginContributions.fromJson(json['contributes'] as Map<String, dynamic>)
          : null,
      entryPoint: json['entryPoint'] != null
          ? EntryPoint.fromJson(json['entryPoint'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert PluginMetadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      'type': type.name,
      'minVersion': minVersion,
      'maxVersion': maxVersion,
      'homepage': homepage,
      'repository': repository,
      'license': license,
      'tags': tags,
      'dependencies': dependencies,
      'supportedPlatforms': supportedPlatforms,
    };
  }

  /// Parse plugin type from string
  static PluginType _parsePluginType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'syntax':
        return PluginType.syntax;
      case 'renderer':
        return PluginType.renderer;
      case 'theme':
        return PluginType.theme;
      case 'export':
      case 'exporter':
        return PluginType.exporter;
      case 'import':
        return PluginType.import;
      case 'tool':
        return PluginType.tool;
      case 'widget':
        return PluginType.widget;
      case 'component':
        return PluginType.component;
      case 'integration':
        return PluginType.integration;
      default:
        return PluginType.other;
    }
  }
}

/// Plugin instance
class Plugin extends Equatable {
  const Plugin({
    required this.metadata,
    required this.status,
    this.installPath,
    required this.installDate,
    required this.lastUpdated,
    this.isDevelopment = false,
    this.errorMessage,
  });

  /// Plugin metadata
  final PluginMetadata metadata;
  
  /// Plugin status
  final PluginStatus status;
  
  /// Installation path
  final String? installPath;
  
  /// Installation date
  final DateTime installDate;
  
  /// Last update time
  final DateTime lastUpdated;
  
  /// Error message
  final String? errorMessage;

  /// Whether this plugin is a development plugin
  final bool isDevelopment;

  Plugin copyWith({
    PluginMetadata? metadata,
    PluginStatus? status,
    String? installPath,
    DateTime? installDate,
    DateTime? lastUpdated,
    String? errorMessage,
    bool? isDevelopment,
  }) {
    return Plugin(
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      installPath: installPath ?? this.installPath,
      installDate: installDate ?? this.installDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage ?? this.errorMessage,
      isDevelopment: isDevelopment ?? this.isDevelopment,
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
        isDevelopment,
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

/// Represents a customizable action provided by a plugin (e.g., a toolbar button)
class PluginAction {
  const PluginAction({
    required this.id,
    required this.title,
    this.description = '',
    this.icon,
    this.group,
  });

  /// Unique identifier for the action, typically linked to a command
  final String id;

  /// The text to display for the action
  final String title;

  /// A longer description, often used for tooltips
  final String description;

  /// The icon for the action, as a Widget.
  final Widget? icon;

  /// The group this action belongs to, for placement in specific toolbars
  final String? group;
}

/// Abstract definition of a registry for toolbar actions.

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

/// Plugin package information for .mxt files
class PluginPackage {
  const PluginPackage({
    required this.metadata,
    required this.packagePath,
    required this.extractedPath,
    required this.installDate,
    this.packageSize,
    this.checksum,
  });

  /// Plugin metadata
  final PluginMetadata metadata;
  
  /// Package file path (.mxt file)
  final String packagePath;
  
  /// Extracted plugin path
  final String extractedPath;
  
  /// Installation date
  final DateTime installDate;
  
  /// Package size in bytes
  final int? packageSize;
  
  /// Package checksum for integrity verification
  final String? checksum;

  PluginPackage copyWith({
    PluginMetadata? metadata,
    String? packagePath,
    String? extractedPath,
    DateTime? installDate,
    int? packageSize,
    String? checksum,
  }) {
    return PluginPackage(
      metadata: metadata ?? this.metadata,
      packagePath: packagePath ?? this.packagePath,
      extractedPath: extractedPath ?? this.extractedPath,
      installDate: installDate ?? this.installDate,
      packageSize: packageSize ?? this.packageSize,
      checksum: checksum ?? this.checksum,
    );
  }
}

/// Plugin package manifest for .mxt files
class PluginPackageManifest {
  const PluginPackageManifest({
    required this.metadata,
    required this.files,
    required this.packageVersion,
    this.dependencies = const [],
    this.assets = const [],
    this.permissions = const [],
  });

  /// Plugin metadata
  final PluginMetadata metadata;
  
  /// List of files in the package
  final List<String> files;
  
  /// Package format version
  final String packageVersion;
  
  /// Package dependencies
  final List<String> dependencies;
  
  /// Asset files
  final List<String> assets;
  
  /// Required permissions
  final List<String> permissions;

  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'id': metadata.id,
        'name': metadata.name,
        'version': metadata.version,
        'description': metadata.description,
        'author': metadata.author,
        'homepage': metadata.homepage,
        'repository': metadata.repository,
        'license': metadata.license,
        'type': metadata.type.name,
        'tags': metadata.tags,
        'minVersion': metadata.minVersion,
        'maxVersion': metadata.maxVersion,
        'dependencies': metadata.dependencies,
      },
      'files': files,
      'packageVersion': packageVersion,
      'dependencies': dependencies,
      'assets': assets,
      'permissions': permissions,
    };
  }

  factory PluginPackageManifest.fromJson(Map<String, dynamic> json) {
    final metadataJson = json['metadata'] as Map<String, dynamic>;
    return PluginPackageManifest(
      metadata: PluginMetadata(
        id: metadataJson['id'] as String,
        name: metadataJson['name'] as String,
        version: metadataJson['version'] as String,
        description: metadataJson['description'] as String,
        author: metadataJson['author'] as String,
        homepage: metadataJson['homepage'] as String?,
        repository: metadataJson['repository'] as String?,
        license: metadataJson['license'] as String,
        type: PluginType.values.firstWhere(
          (e) => e.name == metadataJson['type'],
          orElse: () => PluginType.tool,
        ),
        tags: (metadataJson['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        minVersion: metadataJson['minVersion'] as String,
        maxVersion: metadataJson['maxVersion'] as String?,
        dependencies: (metadataJson['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      ),
      files: (json['files'] as List<dynamic>).cast<String>(),
      packageVersion: json['packageVersion'] as String,
      dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      assets: (json['assets'] as List<dynamic>?)?.cast<String>() ?? [],
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}