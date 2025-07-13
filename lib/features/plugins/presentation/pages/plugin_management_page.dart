import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../types/plugin.dart';
import '../providers/plugin_providers.dart';
import '../widgets/plugin_card.dart';
import '../widgets/plugin_compact_header.dart';
import '../../domain/plugin_context_service.dart';
import '../../domain/plugin_package_service.dart';

/// Plugin management page
class PluginManagementPage extends ConsumerStatefulWidget {
  const PluginManagementPage({super.key});
  
  @override
  ConsumerState<PluginManagementPage> createState() => _PluginManagementPageState();
}

class _PluginManagementPageState extends ConsumerState<PluginManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializePluginManager();
  }
  
  /// Initialize plugin manager
  Future<void> _initializePluginManager() async {
    if (_isInitialized) return;
    
    try {
      final manager = ref.read(pluginManagerProvider);
      final contextService = ref.read(pluginContextServiceProvider);
      
      contextService.initialize();
      await manager.initialize(contextService.context);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize plugin manager: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.initializePluginManagerFailed)),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  List<Tab> _buildTabs(BuildContext context) {
    return [
      Tab(text: AppLocalizations.of(context)!.allPlugins, icon: const Icon(Icons.extension)),
      Tab(text: AppLocalizations.of(context)!.enabledPlugins, icon: const Icon(Icons.check_circle)),
      Tab(text: AppLocalizations.of(context)!.pluginStore, icon: const Icon(Icons.store)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pluginManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showInstallPluginDialog,
            tooltip: AppLocalizations.of(context)!.installPlugin,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _buildTabs(context),
        ),
      ),
      body: Column(
        children: [
          const PluginCompactHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllPluginsTab(),
                _buildEnabledPluginsTab(),
                _buildPluginStoreTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAllPluginsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final plugins = ref.watch(sortedPluginsProvider);
        if (plugins.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.noPlugins));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: plugins.length,
          itemBuilder: (context, index) {
            final plugin = plugins[index];
            return PluginCard(plugin: plugin, onTap: () => _showPluginDetails(plugin));
          },
        );
      },
    );
  }
  
  Widget _buildEnabledPluginsTab() {
     return Consumer(
      builder: (context, ref, child) {
        final enabledPlugins = ref.watch(enabledPluginsProvider);
        if (enabledPlugins.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.noEnabledPlugins));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: enabledPlugins.length,
          itemBuilder: (context, index) {
            final plugin = enabledPlugins[index];
            return PluginCard(plugin: plugin, onTap: () => _showPluginDetails(plugin));
          },
        );
      },
    );
  }
  
  Widget _buildPluginStoreTab() {
    return Center(child: Text(AppLocalizations.of(context)!.comingSoon));
  }
  
  void _showInstallPluginDialog() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mxt'],
    );

    if (result != null && result.files.single.path != null) {
      final packagePath = result.files.single.path!;
      final pluginActions = ref.read(pluginActionsProvider);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await pluginActions.installPlugin(packagePath);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? AppLocalizations.of(context)!.pluginInstalled
                : AppLocalizations.of(context)!.installPluginFailed),
          ),
        );
      }
    }
  }
  
  void _showPluginDetails(Plugin plugin) {
    showDialog(
      context: context,
      builder: (context) {
        final actions = ref.watch(pluginActionsProvider);
        return AlertDialog(
          title: Text(plugin.metadata.name),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(plugin.metadata.description),
                const SizedBox(height: 10),
                Text('Version: ${plugin.metadata.version}'),
                Text('Author: ${plugin.metadata.author}'),
                Text('Status: ${plugin.status.name}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (plugin.status != PluginStatus.enabled)
              TextButton(
                child: Text(AppLocalizations.of(context)!.enable),
                onPressed: () async {
                  await actions.enablePlugin(plugin.metadata.id);
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            if (plugin.status == PluginStatus.enabled)
              TextButton(
                child: Text(AppLocalizations.of(context)!.disable),
                onPressed: () async {
                  await actions.disablePlugin(plugin.metadata.id);
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: Text(AppLocalizations.of(context)!.uninstall),
              onPressed: () async {
                await actions.uninstallPlugin(plugin.metadata.id);
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}