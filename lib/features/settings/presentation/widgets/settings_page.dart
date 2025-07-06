import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/settings_providers.dart';
import '../../domain/entities/app_settings.dart';

/// Settings page
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsPage),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance settings
            _buildSectionHeader(context, AppLocalizations.of(context)!.appearanceSettings),
            _buildLanguageSettings(context, ref, settings),
            _buildThemeSettings(context, ref, settings),
            
            const SizedBox(height: 24),
            
            // Editor settings
            _buildSectionHeader(context, AppLocalizations.of(context)!.editorSettings),
            _buildEditorSettings(context, ref, settings),
            
            const SizedBox(height: 24),
            
            // Behavior settings
            _buildSectionHeader(context, AppLocalizations.of(context)!.behaviorSettings),
            _buildBehaviorSettings(context, ref, settings),
            
            const SizedBox(height: 24),
            
            // About information
            _buildSectionHeader(context, AppLocalizations.of(context)!.about),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  /// Build section title
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Language settings
  Widget _buildLanguageSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    return _buildSettingCard(
      context,
      leading: Icon(PhosphorIconsRegular.translate),
      title: AppLocalizations.of(context)!.language,
      subtitle: _getLanguageLabel(context, settings.language),
      trailing: DropdownButton<String>(
        value: settings.language.split('-')[0], // Normalize language code
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇺🇸'),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.english),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'zh',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇨🇳'),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.chinese),
              ],
            ),
          ),
        ],
        onChanged: (String? language) {
          if (language != null) {
            ref.read(settingsProvider.notifier).updateLanguage(language);
          }
        },
      ),
    );
  }

  /// Theme settings
  Widget _buildThemeSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.palette),
          title: AppLocalizations.of(context)!.themeMode,
          subtitle: _getThemeModeLabel(context, settings.themeMode),
          trailing: DropdownButton<ThemeMode>(
            value: settings.themeMode,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.deviceMobile, size: 16),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.followSystem),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.sun, size: 16),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.lightMode),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.moon, size: 16),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.darkMode),
                  ],
                ),
              ),
            ],
            onChanged: (ThemeMode? mode) {
              if (mode != null) {
                ref.read(settingsProvider.notifier).updateThemeMode(mode);
              }
            },
          ),
        ),
        
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.paintBrush),
          title: AppLocalizations.of(context)!.editorTheme,
          subtitle: settings.editorTheme,
          trailing: DropdownButton<String>(
            value: settings.editorTheme,
            underline: const SizedBox(),
            items: [
              'VS Code Light',
              'VS Code Dark', 
              'GitHub Light',
              'GitHub Dark',
            ].map((theme) => DropdownMenuItem(
              value: theme,
              child: Text(theme),
            )).toList(),
            onChanged: (String? theme) {
              if (theme != null) {
                ref.read(settingsProvider.notifier).updateEditorTheme(theme);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Editor settings
  Widget _buildEditorSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.textAa),
          title: AppLocalizations.of(context)!.fontSize,
          subtitle: '${settings.fontSize.toInt()}px',
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: settings.fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              label: '${settings.fontSize.toInt()}px',
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updateFontSize(value);
              },
            ),
          ),
        ),
        
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.listNumbers),
          title: AppLocalizations.of(context)!.showLineNumbers,
          subtitle: settings.showLineNumbers ? AppLocalizations.of(context)!.enabled : AppLocalizations.of(context)!.disabled,
          trailing: Switch(
            value: settings.showLineNumbers,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowLineNumbers(value);
            },
          ),
        ),
        
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.textIndent),
          title: AppLocalizations.of(context)!.wordWrap,
          subtitle: settings.wordWrap ? AppLocalizations.of(context)!.enabled : AppLocalizations.of(context)!.disabled,
          trailing: Switch(
            value: settings.wordWrap,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateWordWrap(value);
            },
          ),
        ),
        
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.columns),
          title: AppLocalizations.of(context)!.defaultViewMode,
          subtitle: _getViewModeLabel(context, settings.defaultViewMode),
          trailing: DropdownButton<String>(
            value: settings.defaultViewMode,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(value: 'editor', child: Text(AppLocalizations.of(context)!.editor)),
              DropdownMenuItem(value: 'split', child: Text(AppLocalizations.of(context)!.split)),
              DropdownMenuItem(value: 'preview', child: Text(AppLocalizations.of(context)!.preview)),
            ],
            onChanged: (String? mode) {
              if (mode != null) {
                ref.read(settingsProvider.notifier).updateDefaultViewMode(mode);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Behavior settings
  Widget _buildBehaviorSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.floppyDisk),
          title: AppLocalizations.of(context)!.autoSave,
          subtitle: settings.autoSave ? AppLocalizations.of(context)!.enabled : AppLocalizations.of(context)!.disabled,
          trailing: Switch(
            value: settings.autoSave,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAutoSave(value);
            },
          ),
        ),
        
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.clock),
          title: AppLocalizations.of(context)!.autoSaveInterval,
          subtitle: '${settings.autoSaveInterval}${AppLocalizations.of(context)!.seconds}',
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: settings.autoSaveInterval.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '${settings.autoSaveInterval}${AppLocalizations.of(context)!.seconds}',
              onChanged: settings.autoSave ? (value) {
                ref.read(settingsProvider.notifier).updateAutoSaveInterval(value.toInt());
              } : null,
            ),
          ),
        ),
        
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.eye),
          title: AppLocalizations.of(context)!.livePreview,
          subtitle: settings.livePreview ? AppLocalizations.of(context)!.enabled : AppLocalizations.of(context)!.disabled,
          trailing: Switch(
            value: settings.livePreview,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateLivePreview(value);
            },
          ),
        ),
      ],
    );
  }

  /// About information
  Widget _buildAboutSection(BuildContext context) {
    return _buildSettingCard(
      context,
      leading: Icon(PhosphorIconsRegular.info),
      title: 'Markora',
      subtitle: '${AppLocalizations.of(context)!.version} ${AppConstants.version}',
      trailing: Icon(PhosphorIconsRegular.caretRight),
      onTap: () => _showAboutDialog(context),
    );
  }

  /// Build settings card
  Widget _buildSettingCard(
    BuildContext context, {
    required Widget leading,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Get theme mode label
  String _getThemeModeLabel(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppLocalizations.of(context)!.followSystem;
      case ThemeMode.light:
        return AppLocalizations.of(context)!.lightMode;
      case ThemeMode.dark:
        return AppLocalizations.of(context)!.darkMode;
    }
  }

  /// Get view mode label
  String _getViewModeLabel(BuildContext context, String mode) {
    switch (mode) {
      case 'editor':
        return AppLocalizations.of(context)!.editor;
      case 'split':
        return AppLocalizations.of(context)!.split;
      case 'preview':
        return AppLocalizations.of(context)!.preview;
      default:
        return AppLocalizations.of(context)!.split;
    }
  }

  /// Get language label
  String _getLanguageLabel(BuildContext context, String language) {
    // Normalize language code by taking only the language part
    final languageCode = language.split('-')[0];
    switch (languageCode) {
      case 'en':
        return AppLocalizations.of(context)!.english;
      case 'zh':
        return AppLocalizations.of(context)!.chinese;
      default:
        return AppLocalizations.of(context)!.english;
    }
  }

  /// Show about dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Markora',
      applicationVersion: AppConstants.version,
      applicationIcon: Icon(
        PhosphorIconsRegular.notePencil,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const Text('An elegant and powerful cross-platform Markdown editor'),
        const SizedBox(height: 16),
        const Text('Built with Flutter, supports:'),
        const Text('• Live preview'),
        const Text('• LaTeX math formulas'),
        const Text('• Mermaid charts'),
        const Text('• Code syntax highlighting'),
        const Text('• Multi-platform support'),
      ],
    );
  }
}