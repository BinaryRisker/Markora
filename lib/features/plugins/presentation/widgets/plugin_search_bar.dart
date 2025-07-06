import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plugin_providers.dart';

/// Plugin search bar component
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
    
    // Listen to search state changes
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
        hintText: 'Search plugin name, description or tags...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
                tooltip: 'Clear search',
              )
            : IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showAdvancedSearch,
                tooltip: 'Advanced search',
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
        // Can add search history and other features here
      },
    );
  }
  
  /// Clear search
  void _clearSearch() {
    _controller.clear();
    ref.read(pluginSearchProvider.notifier).state = '';
  }
  
  /// Show advanced search dialog
  void _showAdvancedSearch() {
    showDialog(
      context: context,
      builder: (context) => const _AdvancedSearchDialog(),
    );
  }
}

/// Advanced search dialog
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
      title: const Text('Advanced Search'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Plugin Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description Keywords',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
                hintText: 'e.g: markdown, editor, syntax',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: Advanced search feature coming soon, currently only basic search is supported',
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
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _clearAllFields,
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: _performAdvancedSearch,
          child: const Text('Search'),
        ),
      ],
    );
  }
  
  /// Clear all fields
  void _clearAllFields() {
    _nameController.clear();
    _authorController.clear();
    _descriptionController.clear();
    _tagsController.clear();
  }
  
  /// Execute advanced search
  void _performAdvancedSearch() {
    // Build search query
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
    
    // Update search query
    final searchQuery = searchTerms.join(' ');
    ref.read(pluginSearchProvider.notifier).state = searchQuery;
    
    Navigator.of(context).pop();
    
    // Show search result hint
    if (searchQuery.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search: $searchQuery'),
          action: SnackBarAction(
            label: 'Clear',
            onPressed: () {
              ref.read(pluginSearchProvider.notifier).state = '';
            },
          ),
        ),
      );
    }
  }
}