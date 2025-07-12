import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'app.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/document/infrastructure/repositories/hive_document_repository.dart';
import 'features/document/presentation/providers/document_providers.dart';
import 'features/plugins/domain/plugin_manager.dart';
import 'features/plugins/domain/plugin_context_service.dart';

import 'types/document.dart';

// Import the plugin implementations
import 'plugins/mermaid_plugin/main.dart';
import 'plugins/pandoc_plugin/main.dart';
import 'core/utils/plugin_registry.dart';


// Global document repository instance
late HiveDocumentRepository globalDocumentRepository;

/// Application entry function
void main() async {
  // Ensure Flutter widget binding initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Register all built-in plugins
  PluginRegistry.register('mermaid_plugin', () => MermaidPlugin());
  PluginRegistry.register('pandoc_plugin', () => PandocPlugin());

  // Initialize Hive local storage
  if (kIsWeb) {
    // For web, just initialize Hive without path
    Hive.init('hive_db');
  } else {
    // For mobile/desktop, use Flutter-specific initialization
    await Hive.initFlutter();
  }
  
  // Clean up possible conflicting data
  await _cleanupHiveData();
  
  // Register Hive adapters
  Hive.registerAdapter(ThemeModeAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(DocumentTypeAdapter());
  Hive.registerAdapter(DocumentAdapter());

  // Initialize document repository and create sample data
  globalDocumentRepository = HiveDocumentRepository();
  await globalDocumentRepository.init();
  await _createSampleDocuments(globalDocumentRepository);

  // Plugin manager will be initialized in app.dart

  // Run application
  runApp(
    // Riverpod state management container
    ProviderScope(
      overrides: [
        // Use initialized repository instance
        documentRepositoryProvider.overrideWithValue(globalDocumentRepository),
      ],
      child: const MarkoraApp(),
    ),
  );
}

/// Clean up Hive data (prevent TypeId conflicts)
Future<void> _cleanupHiveData() async {
  try {
    // Delete potentially conflicting boxes
    if (await Hive.boxExists('documents')) {
      await Hive.deleteBoxFromDisk('documents');
    }
  } catch (e) {
    // Ignore cleanup errors
    print('Hive data cleanup error: $e');
  }
}

// Plugin manager initialization moved to app.dart to avoid conflicts



/// Create sample documents
Future<void> _createSampleDocuments(HiveDocumentRepository repo) async {
  final existingDocs = await repo.getAllDocuments();
  
  // Don't create sample documents if documents already exist
  if (existingDocs.isNotEmpty) return;

  // Create sample documents - content will be generated dynamically in the app
  // using the current language setting
  await repo.createDocument(
    title: 'Welcome Document', // This will be replaced by localized content in app.dart
    content: '''# Welcome Document

This document will be replaced with localized content when the app starts.''',
  );

  await repo.createDocument(
    title: 'Quick Start Guide',
    content: '''# Markora Quick Start Guide

## Basic Operations

### File Operations
- **New Document**: Ctrl+N
- **Open Document**: Ctrl+O
- **Save Document**: Ctrl+S
- **Save As**: Ctrl+Shift+S

### Edit Operations
- **Undo**: Ctrl+Z
- **Redo**: Ctrl+Y
- **Copy**: Ctrl+C
- **Paste**: Ctrl+V

### Formatting
- **Bold**: **text** or Ctrl+B
- **Italic**: *text* or Ctrl+I
- **Code**: `code` or Ctrl+`

## Advanced Features

### Mermaid Charts

```mermaid
graph TD
    A[Start] --> B{Understand?}
    B -->|Yes| C[Continue Learning]
    B -->|No| D[Re-read]
    D --> B
    C --> E[Complete]
```

### Math Formulas

Quadratic formula:
\$\$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}\$\$

Enjoy using Markora!''',
  );

  await repo.createDocument(
    title: 'My Notes',
    content: '''# My Study Notes

## Today's Tasks
- [ ] Learn Flutter development
- [ ] Complete project documentation
- [x] Test Markora editor

## Important Concepts

### Widget
Everything in Flutter is a Widget, including:
- StatelessWidget: Stateless component
- StatefulWidget: Stateful component

### State Management
Recommend using Riverpod for state management.

## Code Snippets

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello World'),
    );
  }
}
```

## Summary
Learned a lot of new knowledge today!''',
  );
}

/// Markora application main class
class MarkoraApp extends ConsumerWidget {
  const MarkoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to settings changes
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      // Application basic information
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Global navigator key for plugin dialogs
      navigatorKey: GlobalKey<NavigatorState>(),

      // Internationalization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('zh', ''), // Chinese
      ],
      locale: Locale(settings.language.split('-')[0]),

      // Theme configuration - respond to settings changes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,

      // Application home page
      home: Builder(builder: (context) => const AppShell()),
    );
  }
}
