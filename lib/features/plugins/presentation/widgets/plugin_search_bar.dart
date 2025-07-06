import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plugin_providers.dart';

/// 插件搜索栏组件
class PluginSearchBar extends ConsumerStatefulWidget {
  const PluginSearchBar({super.key});
  
  @override
  ConsumerState<PluginSearchBar> createState() => _PluginSearchBarState();
}

class _PluginSearchBarState extends ConsumerState<PluginSearchBar> {
  late final TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    
    // 监听搜索状态变化
    ref.listenManual(pluginSearchProvider, (previous, next) {
      if (next != _controller.text) {
        _controller.text = next;
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(pluginSearchProvider);
    
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: '搜索插件名称、描述或标签...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
                tooltip: '清除搜索',
              )
            : IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showAdvancedSearch,
                tooltip: '高级搜索',
              ),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        ref.read(pluginSearchProvider.notifier).state = value;
      },
      onSubmitted: (value) {
        // 可以在这里添加搜索历史记录等功能
      },
    );
  }
  
  /// 清除搜索
  void _clearSearch() {
    _controller.clear();
    ref.read(pluginSearchProvider.notifier).state = '';
  }
  
  /// 显示高级搜索对话框
  void _showAdvancedSearch() {
    showDialog(
      context: context,
      builder: (context) => const _AdvancedSearchDialog(),
    );
  }
}

/// 高级搜索对话框
class _AdvancedSearchDialog extends ConsumerStatefulWidget {
  const _AdvancedSearchDialog();
  
  @override
  ConsumerState<_AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends ConsumerState<_AdvancedSearchDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _authorController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _authorController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('高级搜索'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '插件名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '作者',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述关键词',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签 (用逗号分隔)',
                border: OutlineInputBorder(),
                hintText: '例如: markdown, editor, syntax',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '提示: 高级搜索功能即将推出，目前仅支持基础搜索',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _clearAllFields,
          child: const Text('清除'),
        ),
        FilledButton(
          onPressed: _performAdvancedSearch,
          child: const Text('搜索'),
        ),
      ],
    );
  }
  
  /// 清除所有字段
  void _clearAllFields() {
    _nameController.clear();
    _authorController.clear();
    _descriptionController.clear();
    _tagsController.clear();
  }
  
  /// 执行高级搜索
  void _performAdvancedSearch() {
    // 构建搜索查询
    final searchTerms = <String>[];
    
    if (_nameController.text.isNotEmpty) {
      searchTerms.add(_nameController.text);
    }
    if (_authorController.text.isNotEmpty) {
      searchTerms.add(_authorController.text);
    }
    if (_descriptionController.text.isNotEmpty) {
      searchTerms.add(_descriptionController.text);
    }
    if (_tagsController.text.isNotEmpty) {
      searchTerms.addAll(
        _tagsController.text.split(',').map((tag) => tag.trim()),
      );
    }
    
    // 更新搜索查询
    final searchQuery = searchTerms.join(' ');
    ref.read(pluginSearchProvider.notifier).state = searchQuery;
    
    Navigator.of(context).pop();
    
    // 显示搜索结果提示
    if (searchQuery.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('搜索: $searchQuery'),
          action: SnackBarAction(
            label: '清除',
            onPressed: () {
              ref.read(pluginSearchProvider.notifier).state = '';
            },
          ),
        ),
      );
    }
  }
}