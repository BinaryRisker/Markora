import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/document_providers.dart';

/// 文档Tab栏组件
class DocumentTabs extends ConsumerWidget {
  const DocumentTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(documentTabsProvider);
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    
    if (tabs.isEmpty) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: Text(
            'No open documents',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
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
          // Tab列表
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = index == tabsNotifier.activeTabIndex;
                
                return _DocumentTabItem(
                  tab: tab,
                  isActive: isActive,
                  onTap: () => tabsNotifier.setActiveTab(index),
                  onClose: () => tabsNotifier.closeTab(index),
                );
              },
            ),
          ),
          // 新建Tab按钮
          _NewTabButton(),
        ],
      ),
    );
  }
}

/// 单个文档Tab项
class _DocumentTabItem extends StatelessWidget {
  const _DocumentTabItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  final DocumentTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 200,
      ),
      decoration: BoxDecoration(
        color: isActive 
            ? theme.colorScheme.background
            : theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 文档图标
                PhosphorIcon(
                  PhosphorIconsRegular.fileText,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                // 文档标题
                Expanded(
                  child: Text(
                    tab.document.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isActive 
                          ? theme.colorScheme.onBackground
                          : theme.colorScheme.onSurface,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 修改状态指示器
                if (tab.isModified) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                // 关闭按钮
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PhosphorIcon(
                      PhosphorIconsRegular.x,
                      size: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 新建Tab按钮
class _NewTabButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tabsNotifier = ref.read(documentTabsProvider.notifier);
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              await tabsNotifier.createNewDocumentTab(
                title: 'New Document',
      content: '# New Document\n\nStart writing your content...',
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('创建新文档失败: $e'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            }
          },
          child: Center(
            child: PhosphorIcon(
              PhosphorIconsRegular.plus,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}