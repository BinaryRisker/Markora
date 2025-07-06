import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/app_settings.dart';

/// Settings repository abstract interface
abstract class SettingsRepository {
  /// Get settings
  Future<AppSettings?> getSettings();

  /// Save settings
  Future<void> saveSettings(AppSettings settings);

  /// Delete settings
  Future<void> deleteSettings();

  /// Check if settings exist
  Future<bool> hasSettings();
}

/// Hive settings repository implementation
class HiveSettingsRepository implements SettingsRepository {
  static const String _boxName = 'settings';
  static const String _settingsKey = 'app_settings';

  Box<AppSettings>? _box;

  /// Get or open settings box
  Future<Box<AppSettings>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    
    try {
      _box = await Hive.openBox<AppSettings>(_boxName);
      return _box!;
    } catch (e) {
      // If opening fails, try to delete and recreate
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<AppSettings>(_boxName);
      return _box!;
    }
  }

  @override
  Future<AppSettings?> getSettings() async {
    try {
      final box = await _getBox();
      return box.get(_settingsKey);
    } catch (e) {
      throw SettingsException('Failed to get settings: $e');
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final box = await _getBox();
      await box.put(_settingsKey, settings);
    } catch (e) {
      throw SettingsException('Failed to save settings: $e');
    }
  }

  @override
  Future<void> deleteSettings() async {
    try {
      final box = await _getBox();
      await box.delete(_settingsKey);
    } catch (e) {
      throw SettingsException('Failed to delete settings: $e');
    }
  }

  @override
  Future<bool> hasSettings() async {
    try {
      final box = await _getBox();
      return box.containsKey(_settingsKey);
    } catch (e) {
      return false;
    }
  }

  /// Close database
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }

  /// Clear all settings
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      throw SettingsException('Failed to clear settings: $e');
    }
  }

  /// Get all keys from settings box
  Future<List<dynamic>> getAllKeys() async {
    try {
      final box = await _getBox();
      return box.keys.toList();
    } catch (e) {
      throw SettingsException('Failed to get settings key list: $e');
    }
  }

  /// Get settings box size
  Future<int> getSettingsCount() async {
    try {
      final box = await _getBox();
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  /// Export settings to Map
  Future<Map<String, dynamic>> exportToMap() async {
    try {
      final settings = await getSettings();
      if (settings != null) {
        return settings.toJson();
      }
      return {};
    } catch (e) {
      throw SettingsException('Failed to export settings: $e');
    }
  }

  /// Import settings from Map
  Future<void> importFromMap(Map<String, dynamic> data) async {
    try {
      final settings = AppSettings.fromJson(data);
      await saveSettings(settings);
    } catch (e) {
      throw SettingsException('Failed to import settings: $e');
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = AppSettings.defaultSettings();
      await saveSettings(defaultSettings);
    } catch (e) {
      throw SettingsException('Failed to reset settings: $e');
    }
  }
}

/// Settings exception class
class SettingsException implements Exception {
  final String message;
  
  const SettingsException(this.message);
  
  @override
  String toString() => 'SettingsException: $message';
}