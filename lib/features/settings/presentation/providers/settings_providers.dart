import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/app_settings.dart';
import '../../infrastructure/repositories/settings_repository.dart';

/// 设置仓库Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return HiveSettingsRepository();
});

/// 设置状态Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});

/// 设置状态管理器
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(AppSettings.defaultSettings()) {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      if (settings != null) {
        state = settings;
      }
    } catch (e) {
      // 加载失败时使用默认设置
      debugPrint('加载设置失败: $e');
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      await _repository.saveSettings(state);
    } catch (e) {
      debugPrint('保存设置失败: $e');
    }
  }

  /// 更新主题模式
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  /// 更新编辑器主题
  Future<void> updateEditorTheme(String editorTheme) async {
    state = state.copyWith(editorTheme: editorTheme);
    await _saveSettings();
  }

  /// 更新字体大小
  Future<void> updateFontSize(double fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await _saveSettings();
  }

  /// 更新显示行号
  Future<void> updateShowLineNumbers(bool showLineNumbers) async {
    state = state.copyWith(showLineNumbers: showLineNumbers);
    await _saveSettings();
  }

  /// 更新自动换行
  Future<void> updateWordWrap(bool wordWrap) async {
    state = state.copyWith(wordWrap: wordWrap);
    await _saveSettings();
  }

  /// 更新默认视图模式
  Future<void> updateDefaultViewMode(String defaultViewMode) async {
    state = state.copyWith(defaultViewMode: defaultViewMode);
    await _saveSettings();
  }

  /// 更新自动保存
  Future<void> updateAutoSave(bool autoSave) async {
    state = state.copyWith(autoSave: autoSave);
    await _saveSettings();
  }

  /// 更新自动保存间隔
  Future<void> updateAutoSaveInterval(int autoSaveInterval) async {
    state = state.copyWith(autoSaveInterval: autoSaveInterval);
    await _saveSettings();
  }

  /// 更新实时预览
  Future<void> updateLivePreview(bool livePreview) async {
    state = state.copyWith(livePreview: livePreview);
    await _saveSettings();
  }

  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    state = AppSettings.defaultSettings();
    await _saveSettings();
  }

  /// 导出设置
  Map<String, dynamic> exportSettings() {
    return state.toJson();
  }

  /// 导入设置
  Future<void> importSettings(Map<String, dynamic> settingsJson) async {
    try {
      state = AppSettings.fromJson(settingsJson);
      await _saveSettings();
    } catch (e) {
      debugPrint('导入设置失败: $e');
      throw Exception('设置格式无效');
    }
  }
} 