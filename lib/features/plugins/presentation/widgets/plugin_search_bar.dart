import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
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
        hintText: AppLocalizations.of(context)!.searchPluginHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
                tooltip: AppLocalizations.of(context)!.clearSearch,
              )
            : IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showAdvancedSearch,
                tooltip: AppLocalizations.of(context)!.advancedSearch,
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
      title: Text(AppLocalizations.of(context)!.advancedSearch),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.pluginName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.author,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.descriptionKeywords,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.tagsCommaSeparated,
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.tagsHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.advancedSearchTip,
              style: const TextStyle(
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _clearAllFields,
          child: Text(AppLocalizations.of(context)!.clear),
        ),
        FilledButton(
          onPressed: _performAdvancedSearch,
          child: Text(AppLocalizations.of(context)!.search),
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