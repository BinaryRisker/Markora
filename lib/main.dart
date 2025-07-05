import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'app.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'types/document.dart';

/// 应用入口函数
void main() async {
  // 确保Flutter组件绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive本地存储
  await Hive.initFlutter();
  
  // 注册Hive适配器
  Hive.registerAdapter(ThemeModeAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  // 注意：Document类还没有Hive适配器，需要后续添加
  // Hive.registerAdapter(DocumentAdapter());

  // 运行应用
  runApp(
    // Riverpod状态管理容器
    const ProviderScope(
      child: MarkoraApp(),
    ),
  );
}

/// Markora应用主类
class MarkoraApp extends ConsumerWidget {
  const MarkoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听设置变化
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      // 应用基本信息
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // 主题配置 - 响应设置变化
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,

      // 应用主页
      home: const AppShell(),
    );
  }
}
