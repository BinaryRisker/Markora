/// Icon registry for managing dynamic icon mappings
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Registry for managing dynamic icon mappings from plugins
class IconRegistry {
  static final IconRegistry _instance = IconRegistry._internal();
  factory IconRegistry() => _instance;
  IconRegistry._internal();

  final Map<String, IconData> _iconMappings = {};
  final Map<String, IconData> _defaultIcons = {
    // Core system icons that are always available
    'plugs': PhosphorIconsRegular.plugs,
    'gear': PhosphorIconsRegular.gear,
    'plus': PhosphorIconsRegular.plus,
    'x': PhosphorIconsRegular.x,
  };

  // Cache for resolved phosphor icons
  final Map<String, IconData?> _phosphorIconCache = {};

  /// Register an icon mapping for a plugin
  void registerIcon(String iconName, IconData iconData) {
    _iconMappings[iconName] = iconData;
  }

  /// Unregister an icon mapping
  void unregisterIcon(String iconName) {
    _iconMappings.remove(iconName);
  }

  /// Get icon by name, returns null if not found
  IconData? getIcon(String iconName) {
    // First check plugin-registered icons
    if (_iconMappings.containsKey(iconName)) {
      return _iconMappings[iconName];
    }
    
    // Then check default system icons
    if (_defaultIcons.containsKey(iconName)) {
      return _defaultIcons[iconName];
    }
    
    // Try to resolve from comprehensive Phosphor icons mapping
    return _resolvePhosphorIcon(iconName);
  }

  /// Get icon with fallback to default
  IconData getIconWithFallback(String iconName, {IconData? fallback}) {
    return getIcon(iconName) ?? fallback ?? PhosphorIconsRegular.plugs;
  }

  /// Resolve Phosphor icons using comprehensive mapping
  IconData? _resolvePhosphorIcon(String iconName) {
    // Check cache first
    if (_phosphorIconCache.containsKey(iconName)) {
      return _phosphorIconCache[iconName];
    }

    // Generate name variations
    final variations = _generateIconNameVariations(iconName);
    
    // Try each variation against the comprehensive icon mapping
    for (final variation in variations) {
      final iconData = _getPhosphorIconByName(variation);
      if (iconData != null) {
        _phosphorIconCache[iconName] = iconData;
        return iconData;
      }
    }
    
    // Cache null result to avoid repeated lookups
    _phosphorIconCache[iconName] = null;
    return null;
  }

  /// Generate different naming convention variations for icon names
  List<String> _generateIconNameVariations(String iconName) {
    final variations = <String>[];
    
    // Original name
    variations.add(iconName);
    
    // camelCase conversion
    variations.add(_toCamelCase(iconName));
    
    // Remove hyphens and underscores
    variations.add(iconName.replaceAll(RegExp(r'[-_]'), ''));
    
    // Convert kebab-case to camelCase
    if (iconName.contains('-')) {
      variations.add(_kebabToCamelCase(iconName));
    }
    
    // Convert snake_case to camelCase
    if (iconName.contains('_')) {
      variations.add(_snakeToCamelCase(iconName));
    }
    
    return variations.toSet().toList(); // Remove duplicates
  }

  /// Convert string to camelCase
  String _toCamelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }

  /// Convert kebab-case to camelCase
  String _kebabToCamelCase(String input) {
    return input.split('-').map((part) {
      if (part.isEmpty) return part;
      return part == input.split('-').first 
          ? part.toLowerCase() 
          : part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).join('');
  }

  /// Convert snake_case to camelCase
  String _snakeToCamelCase(String input) {
    return input.split('_').map((part) {
      if (part.isEmpty) return part;
      return part == input.split('_').first 
          ? part.toLowerCase() 
          : part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).join('');
  }

  /// Comprehensive mapping of Phosphor icon names to IconData
  /// This replaces reflection with a comprehensive static mapping
  IconData? _getPhosphorIconByName(String iconName) {
    final iconMap = {
      // Common icons
      'export': PhosphorIconsRegular.export,
      'import': PhosphorIconsRegular.arrowSquareIn,
      'arrowSquareIn': PhosphorIconsRegular.arrowSquareIn,
      'flower': PhosphorIconsRegular.flower,
      'projectDiagram': PhosphorIconsRegular.flower,
      'file': PhosphorIconsRegular.file,
      'folder': PhosphorIconsRegular.folder,
      'code': PhosphorIconsRegular.code,
      'image': PhosphorIconsRegular.image,
      'link': PhosphorIconsRegular.link,
      'download': PhosphorIconsRegular.download,
      'upload': PhosphorIconsRegular.upload,
      
      // Navigation icons
      'arrowLeft': PhosphorIconsRegular.arrowLeft,
      'arrowRight': PhosphorIconsRegular.arrowRight,
      'arrowUp': PhosphorIconsRegular.arrowUp,
      'arrowDown': PhosphorIconsRegular.arrowDown,
      'caretLeft': PhosphorIconsRegular.caretLeft,
      'caretRight': PhosphorIconsRegular.caretRight,
      'caretUp': PhosphorIconsRegular.caretUp,
      'caretDown': PhosphorIconsRegular.caretDown,
      
      // File and document icons
      'fileText': PhosphorIconsRegular.fileText,
      'filePdf': PhosphorIconsRegular.filePdf,
      'fileDoc': PhosphorIconsRegular.fileDoc,
      'fileImage': PhosphorIconsRegular.fileImage,
      'fileCode': PhosphorIconsRegular.fileCode,
      'fileZip': PhosphorIconsRegular.fileZip,
      'folderOpen': PhosphorIconsRegular.folderOpen,
      'folderPlus': PhosphorIconsRegular.folderPlus,
      
      // UI icons
      'eye': PhosphorIconsRegular.eye,
      'eyeSlash': PhosphorIconsRegular.eyeSlash,
      'heart': PhosphorIconsRegular.heart,
      'star': PhosphorIconsRegular.star,
      'bookmark': PhosphorIconsRegular.bookmark,
      'tag': PhosphorIconsRegular.tag,
      'bell': PhosphorIconsRegular.bell,
      'warning': PhosphorIconsRegular.warning,
      'info': PhosphorIconsRegular.info,
      'question': PhosphorIconsRegular.question,
      'check': PhosphorIconsRegular.check,
      'checkCircle': PhosphorIconsRegular.checkCircle,
      'xCircle': PhosphorIconsRegular.xCircle,
      
      // User and social icons
      'user': PhosphorIconsRegular.user,
      'userCircle': PhosphorIconsRegular.userCircle,
      'users': PhosphorIconsRegular.users,
      'userPlus': PhosphorIconsRegular.userPlus,
      'userMinus': PhosphorIconsRegular.userMinus,
      
      // Communication icons
      'chat': PhosphorIconsRegular.chat,
      'chatCircle': PhosphorIconsRegular.chatCircle,
      'envelope': PhosphorIconsRegular.envelope,
      'phone': PhosphorIconsRegular.phone,
      'videoCamera': PhosphorIconsRegular.videoCamera,
      
      // Media icons
      'play': PhosphorIconsRegular.play,
      'pause': PhosphorIconsRegular.pause,
      'stop': PhosphorIconsRegular.stop,
      'skipBack': PhosphorIconsRegular.skipBack,
      'skipForward': PhosphorIconsRegular.skipForward,
      'speakerHigh': PhosphorIconsRegular.speakerHigh,
      'speakerLow': PhosphorIconsRegular.speakerLow,
      'speakerNone': PhosphorIconsRegular.speakerNone,
      
      // Calendar and time icons
      'calendar': PhosphorIconsRegular.calendar,
      'calendarCheck': PhosphorIconsRegular.calendarCheck,
      'calendarPlus': PhosphorIconsRegular.calendarPlus,
      'clock': PhosphorIconsRegular.clock,
      'timer': PhosphorIconsRegular.timer,
      
      // Shopping and commerce icons
      'shoppingCart': PhosphorIconsRegular.shoppingCart,
      'shoppingBag': PhosphorIconsRegular.shoppingBag,
      'creditCard': PhosphorIconsRegular.creditCard,
      'money': PhosphorIconsRegular.money,
      
      // Technology icons
      'desktop': PhosphorIconsRegular.desktop,
      'laptop': PhosphorIconsRegular.laptop,
      'deviceMobile': PhosphorIconsRegular.deviceMobile,
      'deviceTablet': PhosphorIconsRegular.deviceTablet,
      'monitor': PhosphorIconsRegular.monitor,
      'keyboard': PhosphorIconsRegular.keyboard,
      'mouse': PhosphorIconsRegular.mouse,
      
      // Network and connectivity icons
      'wifi': PhosphorIconsRegular.wifiX,
      'wifiHigh': PhosphorIconsRegular.wifiHigh,
      'wifiLow': PhosphorIconsRegular.wifiLow,
      'wifiMedium': PhosphorIconsRegular.wifiMedium,
      'wifiNone': PhosphorIconsRegular.wifiNone,
      'bluetooth': PhosphorIconsRegular.bluetooth,
      'globe': PhosphorIconsRegular.globe,
      
      // Weather icons
      'sun': PhosphorIconsRegular.sun,
      'moon': PhosphorIconsRegular.moon,
      'cloud': PhosphorIconsRegular.cloud,
      'cloudRain': PhosphorIconsRegular.cloudRain,
      'cloudSnow': PhosphorIconsRegular.cloudSnow,
      'lightning': PhosphorIconsRegular.lightning,
      
      // Transportation icons
      'car': PhosphorIconsRegular.car,
      'bicycle': PhosphorIconsRegular.bicycle,
      'airplane': PhosphorIconsRegular.airplane,
      'train': PhosphorIconsRegular.train,
      'bus': PhosphorIconsRegular.bus,
      
      // Tools and settings icons
      'wrench': PhosphorIconsRegular.wrench,
      'screwdriver': PhosphorIconsRegular.screwdriver,
      'hammer': PhosphorIconsRegular.hammer,
      'paintBrush': PhosphorIconsRegular.paintBrush,
      'scissors': PhosphorIconsRegular.scissors,
      
      // Math and science icons
      'calculator': PhosphorIconsRegular.calculator,
      'function': PhosphorIconsRegular.function,
      'equals': PhosphorIconsRegular.equals,
      'percent': PhosphorIconsRegular.percent,
      'infinity': PhosphorIconsRegular.infinity,
      
      // Security icons
      'lock': PhosphorIconsRegular.lock,
      'lockOpen': PhosphorIconsRegular.lockOpen,
      'key': PhosphorIconsRegular.key,
      'shield': PhosphorIconsRegular.shield,
      'shieldCheck': PhosphorIconsRegular.shieldCheck,
      'shieldWarning': PhosphorIconsRegular.shieldWarning,
    };
    
    return iconMap[iconName];
  }

  /// Clear all plugin-registered icons (useful for plugin cleanup)
  void clearPluginIcons() {
    _iconMappings.clear();
  }

  /// Clear phosphor icon cache
  void clearPhosphorIconCache() {
    _phosphorIconCache.clear();
  }

  /// Get all registered icon names
  List<String> getRegisteredIconNames() {
    return [..._defaultIcons.keys, ..._iconMappings.keys];
  }
}