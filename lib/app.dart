import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'core/constants/app_constants.dart';
import 'types/editor.dart';
import 'types/document.dart';
import 'features/editor/presentation/widgets/markdown_editor.dart';
import 'features/preview/presentation/widgets/markdown_preview.dart';
import 'features/document/presentation/providers/document_providers.dart';
import 'features/document/presentation/widgets/file_dialog.dart';
import 'features/document/presentation/widgets/document_tabs.dart';
import 'features/document/presentation/widgets/save_as_dialog.dart';
import 'features/settings/presentation/widgets/settings_page.dart';
import 'features/export/presentation/widgets/export_dialog.dart';

/// 应用外壳 - 主要界面容器
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // 当前编辑器模式
  EditorMode _currentMode = EditorMode.split;
  
  // 分屏比例（编辑器:预览）
  double _splitRatio = AppConstants.defaultSplitRatio;
  
  // 当前文档内容
  String _currentContent = '''# 欢迎使用 Markora

这是一个功能强大的 Markdown 编辑器，支持：

## 核心功能

- **实时预览** - 所见即所得的编辑体验
- **语法高亮** - 支持多种编程语言
- **数学公式** - 支持 LaTeX 数学公式
- **图表支持** - 集成 Mermaid 图表

## 快速开始

1. 在左侧编辑器中输入 Markdown 内容
2. 右侧会实时显示预览效果
3. 使用工具栏快速插入格式

### 代码示例

```dart
void main() {
  print('Hello, Markora!');
}
```

### 数学公式

行内公式：\$E = mc^2\$

块级公式：
\$\$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}\$\$

### 表格

| 功能 | 状态 | 说明 |
|------|------|------|
| 编辑器 | ✅ | 完成 |
| 预览 | ✅ | 完成 |
| 数学公式 | 🚧 | 开发中 |

> 开始你的 Markdown 创作之旅吧！
''';
  
  // 光标位置
  CursorPosition _cursorPosition = const CursorPosition(line: 0, column: 0, offset: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 工具栏
          _buildToolbar(),
          
          // 文档Tab栏
          const DocumentTabs(),
          
          // 主要内容区域
          Expanded(
            child: _buildContent(),
          ),
          
          // 状态栏
          _buildStatusBar(),
        ],
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      height: AppConstants.toolbarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 文件操作按钮
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.file()),
            tooltip: '新建文档',
            onPressed: () => _handleNewDocument(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.folderOpen()),
            tooltip: '打开文档',
            onPressed: () => _handleOpenDocument(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.floppyDisk()),
            tooltip: '保存文档',
            onPressed: () => _handleSaveDocument(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.copySimple()),
            tooltip: '另存为',
            onPressed: () => _handleSaveAsDocument(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.export()),
            tooltip: '导出文档',
            onPressed: () => _handleExportDocument(),
          ),
          
          const VerticalDivider(),
          
          // 编辑操作按钮
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.arrowUUpLeft()),
            tooltip: '撤销',
            onPressed: () => _handleUndo(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.arrowUUpRight()),
            tooltip: '重做',
            onPressed: () => _handleRedo(),
          ),
          
          const VerticalDivider(),
          
          // 格式化按钮
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.textB()),
            tooltip: '粗体',
            onPressed: () => _handleBold(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.textItalic()),
            tooltip: '斜体',
            onPressed: () => _handleItalic(),
          ),
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.link()),
            tooltip: '插入链接',
            onPressed: () => _handleInsertLink(),
          ),
          
          const Spacer(),
          
          // 视图模式切换
          _buildModeToggle(),
          
          const SizedBox(width: 8),
          
          // 设置按钮
          _buildToolbarButton(
            icon: Icon(PhosphorIcons.gear()),
            tooltip: '设置',
            onPressed: () => _handleSettings(),
          ),
        ],
      ),
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton({
    required Widget icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        iconSize: 20,
      ),
    );
  }

  /// 构建模式切换器
  Widget _buildModeToggle() {
    return ToggleButtons(
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(
        minHeight: 32,
        minWidth: 32,
      ),
      isSelected: [
        _currentMode == EditorMode.source,
        _currentMode == EditorMode.split,
        _currentMode == EditorMode.preview,
      ],
      onPressed: (index) {
        setState(() {
          switch (index) {
            case 0:
              _currentMode = EditorMode.source;
              break;
            case 1:
              _currentMode = EditorMode.split;
              break;
            case 2:
              _currentMode = EditorMode.preview;
              break;
          }
        });
      },
      children: [
        Tooltip(
          message: '源码模式',
          child: Icon(PhosphorIcons.code(), size: 16),
        ),
        Tooltip(
          message: '分屏模式',
          child: Icon(PhosphorIcons.columns(), size: 16),
        ),
        Tooltip(
          message: '预览模式',
          child: Icon(PhosphorIcons.eye(), size: 16),
        ),
      ],
    );
  }

  /// 构建主要内容区域
  Widget _buildContent() {
    switch (_currentMode) {
      case EditorMode.source:
        return _buildEditor();
      case EditorMode.preview:
        return _buildPreview();
      case EditorMode.split:
        return _buildSplitView();
      case EditorMode.live:
        return _buildLiveEditor();
    }
  }

  /// 构建编辑器
  Widget _buildEditor() {
    final activeDocument = ref.watch(activeDocumentProvider);
    final content = activeDocument?.content ?? '';
    
    return MarkdownEditor(
      initialContent: content,
      onChanged: (content) {
        // 移除setState调用，因为内容已经通过Tab系统管理
        // Tab系统会自动处理内容同步
      },
      onCursorPositionChanged: (position) {
        setState(() {
          _cursorPosition = position;
        });
      },
    );
  }

  /// 构建预览器
  Widget _buildPreview() {
    final activeDocument = ref.watch(activeDocumentProvider);
    final content = activeDocument?.content ?? '';
    
    return MarkdownPreview(
      content: content,
    );
  }

  /// 构建分屏视图
  Widget _buildSplitView() {
    return Row(
      children: [
        // 编辑器区域
        Expanded(
          flex: (_splitRatio * 100).round(),
          child: _buildEditor(),
        ),
        
        // 分隔线
        GestureDetector(
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final double newRatio = details.localPosition.dx / box.size.width;
            setState(() {
              _splitRatio = newRatio.clamp(0.2, 0.8);
            });
          },
          child: Container(
            width: 4,
            color: Theme.of(context).dividerColor,
            child: const Center(
              child: Icon(
                Icons.drag_indicator,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        
        // 预览区域
        Expanded(
          flex: ((1 - _splitRatio) * 100).round(),
          child: _buildPreview(),
        ),
      ],
    );
  }

  /// 构建实时编辑器
  Widget _buildLiveEditor() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: const Center(
        child: Text(
          '实时编辑器\n(即将实现)',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    final activeDocument = ref.watch(activeDocumentProvider);
    final tabs = ref.watch(documentTabsProvider);
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    
    return Container(
      height: AppConstants.statusBarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (activeDocument != null) ...[
              Text(
                '${activeDocument.title} | ${activeDocument.content.length} 字符',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              if (tabsNotifier.activeTabIndex >= 0 && 
                  tabsNotifier.activeTabIndex < tabs.length &&
                  tabs[tabsNotifier.activeTabIndex].isModified) ...[
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '已修改',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ] else ...[
              const Text(
                '没有打开的文档',
                style: TextStyle(fontSize: 12),
              ),
            ],
            const Spacer(),
            if (activeDocument != null) ...[
              Text(
                'Ln ${_cursorPosition.line + 1}, Col ${_cursorPosition.column + 1}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 事件处理方法
  void _handleNewDocument() async {
    try {
      final tabsNotifier = ref.read(documentTabsProvider.notifier);
      await tabsNotifier.createNewDocumentTab(
        title: '新文档',
        content: '# 新文档\n\n开始你的创作...',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已创建新文档')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建文档失败: $e')),
        );
      }
    }
  }

  void _handleOpenDocument() async {
    try {
      final selectedDocument = await showOpenFileDialog(context);
      if (selectedDocument != null) {
        // 文档已经在file_dialog中被添加到Tab了，这里只需要显示消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已打开文档: ${selectedDocument.title}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开文档失败: $e')),
        );
      }
    }
  }

  void _handleSaveDocument() async {
    try {
      final tabsNotifier = ref.read(documentTabsProvider.notifier);
      final activeDocument = ref.read(activeDocumentProvider);
      
      // 如果有激活文档，直接保存
      if (activeDocument != null) {
        await tabsNotifier.saveActiveTab();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文档已保存')),
          );
        }
      } else {
        // 如果没有激活文档，显示另存为对话框
        _handleSaveAsDocument();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  /// 处理另存为
  void _handleSaveAsDocument() async {
    try {
      final activeDocument = ref.read(activeDocumentProvider);
      final documentToSave = activeDocument ?? Document(
        id: 'temp_save',
        title: '新文档',
        content: _currentContent,
        type: DocumentType.markdown,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await showDialog<SaveResult>(
        context: context,
        builder: (context) => SaveAsDialog(
          document: documentToSave,
          initialFormat: SaveFormat.markdown,
        ),
      );

      if (result != null) {
        // 根据选择的格式保存文件
        await _saveFileWithFormat(documentToSave, result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('文档已保存为: ${result.fileName}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  /// 根据格式保存文件
  Future<void> _saveFileWithFormat(Document document, SaveResult result) async {
    // 文件已经在SaveAsDialog中保存到磁盘了
    // 这里只需要更新Tab中的文档信息
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    
    // 更新文档标题为文件名（不包含扩展名）
    final fileNameWithoutExt = result.fileName.replaceAll(RegExp(r'\.[^.]*$'), '');
    final updatedDocument = document.copyWith(
      title: fileNameWithoutExt,
      updatedAt: DateTime.now(),
    );
    
    // 保存到Hive数据库
    await ref.read(documentServiceProvider).saveDocument(updatedDocument);
    
    // 如果文档在Tab中，更新Tab
    final activeIndex = tabsNotifier.activeTabIndex;
    if (activeIndex >= 0) {
      final tabs = ref.read(documentTabsProvider);
      if (activeIndex < tabs.length && tabs[activeIndex].document.id == document.id) {
        // 更新当前Tab的文档信息
        tabsNotifier.updateTabContent(activeIndex, updatedDocument.content);
      }
    }
  }

  void _handleExportDocument() {
    // 获取当前文档或创建临时文档
    final currentDoc = ref.read(currentDocumentProvider);
    final documentToExport = currentDoc ?? Document(
      id: 'temp_export',
      title: '未命名文档',
      content: _currentContent,
      type: DocumentType.markdown,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    showExportDialog(context, documentToExport);
  }

  void _handleUndo() {
    // TODO: 实现撤销
  }

  void _handleRedo() {
    // TODO: 实现重做
  }

  void _handleBold() {
    // TODO: 实现粗体格式化
  }

  void _handleItalic() {
    // TODO: 实现斜体格式化
  }

  void _handleInsertLink() {
    // TODO: 实现插入链接
  }

  void _handleSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }
} 