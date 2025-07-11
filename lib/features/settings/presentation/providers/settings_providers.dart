import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/app_settings.dart';
import '../../infrastructure/repositories/settings_repository.dart';

/// Settings repository Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return HiveSettingsRepository();
});

/// Settings state Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});

/// Settings state manager
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(AppSettings.defaultSettings()) {
    _loadSettings();
  }

  /// Load settings
  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      if (settings != null) {
        state = settings;
      }
    } catch (e) {
      // Use default settings when loading fails
      debugPrint('Failed to load settings: $e');
    }
  }

  /// Save settings
  Future<void> _saveSettings() async {
    try {
      await _repository.saveSettings(state);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  /// Update editor theme
  Future<void> updateEditorTheme(String editorTheme) async {
    state = state.copyWith(editorTheme: editorTheme);
    await _saveSettings();
  }

  /// Update font size
  Future<void> updateFontSize(double fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await _saveSettings();
  }

  /// Update show line numbers
  Future<void> updateShowLineNumbers(bool showLineNumbers) async {
    state = state.copyWith(showLineNumbers: showLineNumbers);
    await _saveSettings();
  }

  /// Update word wrap
  Future<void> updateWordWrap(bool wordWrap) async {
    state = state.copyWith(wordWrap: wordWrap);
    await _saveSettings();
  }

  /// Update default view mode
  Future<void> updateDefaultViewMode(String defaultViewMode) async {
    state = state.copyWith(defaultViewMode: defaultViewMode);
    await _saveSettings();
  }

  /// Update auto save
  Future<void> updateAutoSave(bool autoSave) async {
    state = state.copyWith(autoSave: autoSave);
    await _saveSettings();
  }

  /// Update auto save interval
  Future<void> updateAutoSaveInterval(int autoSaveInterval) async {
    state = state.copyWith(autoSaveInterval: autoSaveInterval);
    await _saveSettings();
  }

  /// Update live preview
  Future<void> updateLivePreview(bool livePreview) async {
    state = state.copyWith(livePreview: livePreview);
    await _saveSettings();
  }

  /// Update language setting
  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  /// Update font family
  Future<void> updateFontFamily(String fontFamily) async {
    state = state.copyWith(fontFamily: fontFamily);
    await _saveSettings();
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    state = AppSettings.defaultSettings();
    await _saveSettings();
  }

  /// Export settings
  Map<String, dynamic> exportSettings() {
    return state.toJson();
  }

  /// Import settings
  Future<void> importSettings(Map<String, dynamic> settingsJson) async {
    try {
      state = AppSettings.fromJson(settingsJson);
      await _saveSettings();
    } catch (e) {
      debugPrint('Failed to import settings: $e');
      throw Exception('Invalid settings format');
    }
  }
}