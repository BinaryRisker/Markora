import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/settings_providers.dart';
import '../../domain/entities/app_settings.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
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
            // 外观设置
            _buildSectionHeader(context, '外观设置'),
            _buildThemeSettings(context, ref, settings),
            
            const SizedBox(height: 24),
            
            // 编辑器设置
            _buildSectionHeader(context, '编辑器设置'),
            _buildEditorSettings(context, ref, settings),
            
            const SizedBox(height: 24),
            
            // 行为设置
            _buildSectionHeader(context, '行为设置'),
            _buildBehaviorSettings(context, ref, settings),
            
            const SizedBox(height: 24),
            
            // 关于信息
            _buildSectionHeader(context, '关于'),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  /// 构建节标题
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

  /// 主题设置
  Widget _buildThemeSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.palette),
          title: '主题模式',
          subtitle: _getThemeModeLabel(settings.themeMode),
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
                    const Text('跟随系统'),
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
                    const Text('浅色'),
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
                    const Text('深色'),
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
          title: '编辑器主题',
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

  /// 编辑器设置
  Widget _buildEditorSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.textAa),
          title: '字体大小',
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
          title: '显示行号',
          subtitle: settings.showLineNumbers ? '已启用' : '已禁用',
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
          title: '自动换行',
          subtitle: settings.wordWrap ? '已启用' : '已禁用',
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
          title: '默认视图模式',
          subtitle: _getViewModeLabel(settings.defaultViewMode),
          trailing: DropdownButton<String>(
            value: settings.defaultViewMode,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: 'editor', child: Text('编辑器')),
              const DropdownMenuItem(value: 'split', child: Text('分屏')),
              const DropdownMenuItem(value: 'preview', child: Text('预览')),
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

  /// 行为设置
  Widget _buildBehaviorSettings(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.floppyDisk),
          title: '自动保存',
          subtitle: settings.autoSave ? '已启用' : '已禁用',
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
          title: '自动保存间隔',
          subtitle: '${settings.autoSaveInterval}秒',
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: settings.autoSaveInterval.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '${settings.autoSaveInterval}秒',
              onChanged: settings.autoSave ? (value) {
                ref.read(settingsProvider.notifier).updateAutoSaveInterval(value.toInt());
              } : null,
            ),
          ),
        ),
        
        _buildSettingCard(
          context,
          leading: Icon(PhosphorIconsRegular.eye),
          title: '实时预览',
          subtitle: settings.livePreview ? '已启用' : '已禁用',
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

  /// 关于信息
  Widget _buildAboutSection(BuildContext context) {
    return _buildSettingCard(
      context,
      leading: Icon(PhosphorIconsRegular.info),
      title: 'Markora',
      subtitle: '版本 ${AppConstants.version}',
      trailing: Icon(PhosphorIconsRegular.caretRight),
      onTap: () => _showAboutDialog(context),
    );
  }

  /// 构建设置卡片
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

  /// 获取主题模式标签
  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  /// 获取视图模式标签
  String _getViewModeLabel(String mode) {
    switch (mode) {
      case 'editor':
        return '编辑器';
      case 'split':
        return '分屏';
      case 'preview':
        return '预览';
      default:
        return '分屏';
    }
  }

  /// 显示关于对话框
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
        const Text('一个优雅而强大的跨平台 Markdown 编辑器'),
        const SizedBox(height: 16),
        const Text('基于 Flutter 构建，支持：'),
        const Text('• 实时预览'),
        const Text('• LaTeX 数学公式'),
        const Text('• Mermaid 图表'),
        const Text('• 代码语法高亮'),
        const Text('• 多平台支持'),
      ],
    );
  }
}