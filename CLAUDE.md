# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Markora is a next-generation cross-platform Markdown editor built with Flutter, targeting Typora-style immersive writing experience with advanced features like LaTeX math formulas, Mermaid charts, and an extensible plugin system.

## Common Development Commands

### Flutter Development
```bash
# Get dependencies
flutter pub get

# Run code generation for Hive models
flutter packages pub run build_runner build

# Run on different platforms
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome --web-port=8080
flutter run -d ios
flutter run -d android

# Enable desktop support (if needed)
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# Analysis and linting
flutter analyze

# Run tests
flutter test
```

### Performance Testing
```bash
# Run performance benchmarks
flutter test test/performance_benchmark_test.dart

# Run math compatibility tests
flutter test test/plugin_math_compatibility_test.dart
```

## Core Architecture

### Clean Architecture Pattern
```
lib/
├── core/                   # Core utilities and shared components
│   ├── constants/         # App constants
│   ├── services/          # Shared services (command_service.dart)
│   ├── themes/           # Theme configuration
│   └── utils/            # Critical performance utilities:
│       ├── markdown_block_parser.dart    # Block-level document parsing
│       ├── markdown_block_cache.dart     # LRU caching system
│       ├── plugin_block_processor.dart   # Plugin integration
│       └── performance_monitor.dart      # Performance tracking
├── features/             # Feature-based modules
│   ├── document/         # Document management
│   ├── editor/          # Markdown editing
│   ├── preview/         # Document preview with optimization
│   ├── plugins/         # Plugin system
│   ├── settings/        # Application settings
│   └── syntax_highlighting/ # Code highlighting
├── types/               # Core type definitions
└── main.dart           # Application entry point
```

### Performance Architecture
Markora implements **Block-level Virtualized Rendering** for large documents:
- **MarkdownBlockParser** (`lib/core/utils/markdown_block_parser.dart`): Splits markdown into independent blocks
- **MarkdownBlockCache** (`lib/core/utils/markdown_block_cache.dart`): LRU cache with intelligent invalidation
- **PluginBlockProcessor** (`lib/core/utils/plugin_block_processor.dart`): Handles plugin syntax within blocks
- **PerformanceMonitor** (`lib/core/utils/performance_monitor.dart`): Real-time performance tracking

## State Management

### Riverpod Pattern
- Uses **Riverpod 2.5.1** for reactive state management
- Providers located in `*/presentation/providers/` directories
- Follow provider naming: `[feature]Provider`, `[feature]NotifierProvider`
- Example: `lib/features/document/presentation/providers/document_providers.dart`

### Key Providers
- `documentProvider`: Document management and file operations
- `settingsProvider`: Application settings and preferences
- `pluginProvider`: Plugin system state

## Plugin System

### Plugin Architecture
- Located in `lib/features/plugins/domain/`
- Plugin interface: `plugin_interface.dart`
- Plugin manager: `plugin_manager.dart`
- Sample plugins in `plugins/` directory

### Plugin Development
- Each plugin has `plugin.json` metadata
- Main implementation in `lib/main.dart`
- Built-in plugins: Mermaid charts, Pandoc export

## Type System

### Core Types (lib/types/)
- `document.dart`: Document entities and models
- `editor.dart`: Editor-specific types
- `plugin.dart`: Plugin system types
- `syntax_highlighting.dart`: Code highlighting types

All types use strong typing - avoid `dynamic` and `Object?`.

## Code Quality Standards

### Development Rules (from .cursor/rules/flutter.mdc)
- **Type Safety**: No `dynamic` or `Object?` usage
- **File Size**: Maximum 200 lines per file
- **Architecture**: Follow Clean Architecture layers
- **Language**: All code and comments in English
- **Icons**: Use `phosphor_flutter` icon library

### Code Organization
- Feature modules follow domain/presentation/infrastructure layers
- Complex types go in `types/` directory
- Shared utilities in `core/utils/`
- UI follows Material Design 3

## Testing Strategy

### Test Files
- `test/markdown_block_parser_test.dart`: Block parsing tests
- `test/performance_benchmark_test.dart`: Performance benchmarks
- `test/plugin_math_compatibility_test.dart`: Plugin compatibility
- `test/widget_test.dart`: Widget tests

### Running Tests
Performance tests include benchmarks for:
- Block parsing speed (target: 7.78M chars/second)
- Cache efficiency (target: 90%+ hit rate)
- Memory usage (constant regardless of document size)

## Tech Stack

### Dependencies
- **Flutter**: 3.32.1 (UI framework)
- **Riverpod**: 2.5.1 (state management)  
- **GoRouter**: 14.3.0 (routing)
- **Hive**: 2.2.3 (local storage)
- **flutter_markdown**: 0.7.4 (markdown rendering)
- **flutter_math_fork**: 0.7.2 (LaTeX formulas)
- **webview_flutter**: 4.10.0 (Mermaid charts)
- **code_text_field**: 1.1.0 (code editor)

### Key Features
- **Math Formulas**: LaTeX rendering via flutter_math_fork
- **Charts**: Mermaid integration via WebView
- **Code Highlighting**: 27+ programming languages
- **Export**: PDF/HTML export capabilities
- **Performance**: Block-level virtualization for large documents

## Development Workflow

### Before Making Changes
1. Run `flutter pub get` to ensure dependencies
2. Check existing code patterns in the relevant feature module
3. Follow the established Clean Architecture layers
4. Maintain consistency with existing UI patterns

### Performance Considerations
- Large document rendering uses block-level virtualization
- Cache-first approach for repeated renders
- Performance monitoring available in debug mode
- Memory-efficient design with constant memory usage

### Plugin Development
- Check `plugins/` directory for examples
- Follow plugin interface in `lib/features/plugins/domain/`
- Plugins support custom syntax, rendering, and UI extensions

## Known Issues & Limitations

### Current Status
- Core functionality complete (85%+ feature completion)
- Plugin system operational with Mermaid and Pandoc support
- Performance optimized for documents up to 10MB+
- Mobile responsive design implemented

### Next Development Priorities
1. Settings module enhancement
2. Export functionality expansion (DOCX, improved PDF)
3. Plugin ecosystem development
4. Cloud sync integration

## Debug Features

### Performance Monitoring (Debug Mode Only)
- Real-time performance metrics
- Cache statistics and efficiency reports
- Block-level rendering analysis
- Memory usage tracking

Access via preview toolbar analytics icons when running in debug mode.