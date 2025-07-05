import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/app_settings.dart';

/// 设置仓库抽象接口
abstract class SettingsRepository {
  /// 获取设置
  Future<AppSettings?> getSettings();

  /// 保存设置
  Future<void> saveSettings(AppSettings settings);

  /// 删除设置
  Future<void> deleteSettings();

  /// 检查设置是否存在
  Future<bool> hasSettings();
}

/// Hive设置仓库实现
class HiveSettingsRepository implements SettingsRepository {
  static const String _boxName = 'settings';
  static const String _settingsKey = 'app_settings';

  Box<AppSettings>? _box;

  /// 获取或打开设置盒子
  Future<Box<AppSettings>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    
    try {
      _box = await Hive.openBox<AppSettings>(_boxName);
      return _box!;
    } catch (e) {
      // 如果打开失败，尝试删除并重新创建
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
      throw SettingsException('获取设置失败: $e');
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final box = await _getBox();
      await box.put(_settingsKey, settings);
    } catch (e) {
      throw SettingsException('保存设置失败: $e');
    }
  }

  @override
  Future<void> deleteSettings() async {
    try {
      final box = await _getBox();
      await box.delete(_settingsKey);
    } catch (e) {
      throw SettingsException('删除设置失败: $e');
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

  /// 关闭数据库
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }

  /// 清空所有设置
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      throw SettingsException('清空设置失败: $e');
    }
  }

  /// 获取设置盒子的所有键
  Future<List<dynamic>> getAllKeys() async {
    try {
      final box = await _getBox();
      return box.keys.toList();
    } catch (e) {
      throw SettingsException('获取设置键列表失败: $e');
    }
  }

  /// 获取设置盒子的大小
  Future<int> getSettingsCount() async {
    try {
      final box = await _getBox();
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  /// 备份设置到Map
  Future<Map<String, dynamic>> exportToMap() async {
    try {
      final settings = await getSettings();
      if (settings != null) {
        return settings.toJson();
      }
      return {};
    } catch (e) {
      throw SettingsException('导出设置失败: $e');
    }
  }

  /// 从Map恢复设置
  Future<void> importFromMap(Map<String, dynamic> data) async {
    try {
      final settings = AppSettings.fromJson(data);
      await saveSettings(settings);
    } catch (e) {
      throw SettingsException('导入设置失败: $e');
    }
  }

  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = AppSettings.defaultSettings();
      await saveSettings(defaultSettings);
    } catch (e) {
      throw SettingsException('重置设置失败: $e');
    }
  }
}

/// 设置异常类
class SettingsException implements Exception {
  final String message;
  
  const SettingsException(this.message);
  
  @override
  String toString() => 'SettingsException: $message';
} 