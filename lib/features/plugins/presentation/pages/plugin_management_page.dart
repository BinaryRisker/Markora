import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/plugin_providers.dart';
import '../widgets/plugin_card.dart';
import '../widgets/plugin_compact_header.dart';
import '../../../../types/plugin.dart';
import '../../domain/plugin_interface.dart';
import '../../domain/plugin_context_service.dart';

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
  String? _currentLanguage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializePluginManager();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if language has changed
    final newLanguage = Localizations.localeOf(context).languageCode;
    if (_currentLanguage != null && _currentLanguage != newLanguage) {
      // Language changed, force rebuild by calling setState
      if (mounted) {
        setState(() {
          // This will trigger a rebuild of the widget tree
        });
      }
    }
    _currentLanguage = newLanguage;
  }
  
  /// Initialize plugin manager
  Future<void> _initializePluginManager() async {
    if (_isInitialized) return;
    
    try {
      final manager = ref.read(pluginManagerProvider);
      final contextService = ref.read(pluginContextServiceProvider);
      
      // Initialize plugin context service
      contextService.initialize();
      
      // Initialize plugin manager with real context
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
  
  /// Build tabs for TabBar
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPlugins,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _buildTabs(context),
        ),
      ),
      body: Column(
        children: [
          // Compact header with search, filters, and stats
          const PluginCompactHeader(),
          
          // Plugin list
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
  
  /// Build all plugins tab
  Widget _buildAllPluginsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final plugins = ref.watch(sortedPluginsProvider);
        
        if (plugins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.extension_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noPlugins,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.clickToInstallPlugins,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: plugins.length,
          itemBuilder: (context, index) {
            final plugin = plugins[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PluginCard(
                plugin: plugin,
                onTap: () => _showPluginDetails(plugin),
              ),
            );
          },
        );
      },
    );
  }
  
  /// Build enabled plugins tab
  Widget _buildEnabledPluginsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final enabledPlugins = ref.watch(enabledPluginsProvider);
        
        if (enabledPlugins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noEnabledPlugins,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.enablePluginsInAllTab,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: enabledPlugins.length,
          itemBuilder: (context, index) {
            final plugin = enabledPlugins[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PluginCard(
                plugin: plugin,
                onTap: () => _showPluginDetails(plugin),
              ),
            );
          },
        );
      },
    );
  }
  
  /// Build plugin store tab
  Widget _buildPluginStoreTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.pluginStore,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.comingSoon,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  /// Show install plugin dialog
  void _showInstallPluginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.installPlugin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text(AppLocalizations.of(context)!.installFromFile),
              subtitle: Text(AppLocalizations.of(context)!.selectPluginFile),
              onTap: () {
                Navigator.of(context).pop();
                _installFromFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(AppLocalizations.of(context)!.installFromUrl),
              subtitle: Text(AppLocalizations.of(context)!.enterPluginUrl),
              onTap: () {
                Navigator.of(context).pop();
                _installFromUrl();
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: Text(AppLocalizations.of(context)!.installFromStore),
              subtitle: Text(AppLocalizations.of(context)!.browsePluginStore),
              onTap: () {
                Navigator.of(context).pop();
                _tabController.animateTo(2);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }
  
  /// Install plugin from file
  void _installFromFile() async {
    try {
      // TODO: Implement file picker
      // Use mock path for now
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectPluginFile)),
      );
      
      // final result = await FilePicker.platform.pickFiles(
      //   type: FileType.custom,
      //   allowedExtensions: ['zip'],
      // );
      // 
      // if (result != null && result.files.single.path != null) {
      //   final actions = ref.read(pluginActionsProvider);
      //   final success = await actions.installPlugin(result.files.single.path!);
      //   
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text(success ? 'Plugin installed successfully' : 'Plugin installation failed')),
      //     );
      //   }
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.installFailed}: $e')),
        );
      }
    }
  }
  
  /// Install plugin from URL
  void _installFromUrl() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.installFromUrl),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.pluginUrl,
            hintText: 'https://example.com/plugin.zip',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(AppLocalizations.of(context)!.install),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      try {
        // TODO: Implement URL download logic
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.downloadingPlugin)),
        );
        
        // Download logic needs to be implemented here
        // final downloadPath = await downloadPlugin(result);
        // final actions = ref.read(pluginActionsProvider);
        // final success = await actions.installPlugin(downloadPath);
        // 
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(content: Text(success ? 'Plugin installed successfully' : 'Plugin installation failed')),
        //   );
        // }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.urlInstallInDevelopment)),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.installFailed}: $e')),
          );
        }
      }
    }
  }
  
  /// Refresh plugin list
  void _refreshPlugins() async {
    try {
      final manager = ref.read(pluginManagerProvider);
      final contextService = ref.read(pluginContextServiceProvider);
      
      // Rescan plugin directory
      await manager.initialize(manager.context ?? contextService.context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.refreshComplete)),
        );
      }
    } catch (e) {
      debugPrint('Refresh plugins failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.refreshFailed}: $e')),
        );
      }
    }
  }
  
  /// Show plugin details
  void _showPluginDetails(Plugin plugin) {
    showDialog(
      context: context,
      builder: (context) => _PluginDetailsDialog(plugin: plugin),
    );
  }
}

// Simple implementations removed - using real plugin context service now

/// Plugin details dialog
class _PluginDetailsDialog extends ConsumerWidget {
  const _PluginDetailsDialog({required this.plugin});
  
  final Plugin plugin;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(pluginActionsProvider);
    
    return AlertDialog(
      title: Text(plugin.metadata.name),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(AppLocalizations.of(context)!.version, plugin.metadata.version),
            _buildInfoRow(AppLocalizations.of(context)!.author, plugin.metadata.author),
            _buildInfoRow(AppLocalizations.of(context)!.type, plugin.metadata.type.getLocalizedDisplayName(context)),
        _buildInfoRow(AppLocalizations.of(context)!.status, plugin.status.getLocalizedDisplayName(context)),
            if (plugin.metadata.homepage != null)
              _buildInfoRow(AppLocalizations.of(context)!.homepage, plugin.metadata.homepage!),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.description,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(plugin.metadata.description),
            if (plugin.metadata.tags.isNotEmpty) ...
            [
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.tags,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: plugin.metadata.tags.map((tag) => Chip(
                  label: Text(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (plugin.status == PluginStatus.enabled)
          TextButton(
            onPressed: () async {
              final success = await actions.disablePlugin(plugin.metadata.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? AppLocalizations.of(context)!.pluginDisabled : AppLocalizations.of(context)!.disablePluginFailed),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.disable),
          )
        else if (plugin.status == PluginStatus.installed || plugin.status == PluginStatus.disabled)
          TextButton(
            onPressed: () async {
              final success = await actions.enablePlugin(plugin.metadata.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? AppLocalizations.of(context)!.pluginEnabled : AppLocalizations.of(context)!.enablePluginFailed),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.enable),
          ),
        TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.confirmUninstall),
                content: Text(AppLocalizations.of(context)!.uninstallConfirmation(plugin.metadata.name)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text(AppLocalizations.of(context)!.uninstall),
                  ),
                ],
              ),
            );
            
            if (confirmed == true && context.mounted) {
              final success = await actions.uninstallPlugin(plugin.metadata.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? AppLocalizations.of(context)!.pluginUninstalled : AppLocalizations.of(context)!.uninstallPluginFailed),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            }
          },
          child: Text(AppLocalizations.of(context)!.uninstall),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}