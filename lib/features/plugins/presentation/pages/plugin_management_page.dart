import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plugin_providers.dart';
import '../widgets/plugin_card.dart';
import '../widgets/plugin_stats_card.dart';
import '../widgets/plugin_search_bar.dart';
import '../widgets/plugin_filters.dart';
import '../../../../types/plugin.dart';
import '../../domain/plugin_interface.dart';

/// 插件管理页面
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
  
  /// 初始化插件管理器
  Future<void> _initializePluginManager() async {
    if (_isInitialized) return;
    
    try {
      final manager = ref.read(pluginManagerProvider);
      // 创建简单的插件上下文
      final context = _createPluginContext();
      
      // 初始化插件管理器
      await manager.initialize(context);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('初始化插件管理器失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化插件管理器失败: $e')),
        );
      }
    }
  }
  
  /// 创建插件上下文
  PluginContext _createPluginContext() {
    return PluginContext(
      editorController: _SimpleEditorController(),
      syntaxRegistry: _SimpleSyntaxRegistry(),
      toolbarRegistry: _SimpleToolbarRegistry(),
      menuRegistry: _SimpleMenuRegistry(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showInstallPluginDialog,
            tooltip: '安装插件',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPlugins,
            tooltip: '刷新',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '所有插件', icon: Icon(Icons.extension)),
            Tab(text: '已启用', icon: Icon(Icons.check_circle)),
            Tab(text: '商店', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 统计信息卡片
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: PluginStatsCard(),
            ),
            
            // 搜索和过滤
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const PluginSearchBar(),
                  const SizedBox(height: 8),
                  const PluginFilters(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 插件列表
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
      ),
    );
  }
  
  /// 构建所有插件标签页
  Widget _buildAllPluginsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final plugins = ref.watch(sortedPluginsProvider);
        
        if (plugins.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.extension_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '暂无插件',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '点击右上角的 + 按钮安装插件',
                  style: TextStyle(color: Colors.grey),
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
  
  /// 构建已启用插件标签页
  Widget _buildEnabledPluginsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final enabledPlugins = ref.watch(enabledPluginsProvider);
        
        if (enabledPlugins.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '暂无已启用的插件',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '在所有插件页面启用插件',
                  style: TextStyle(color: Colors.grey),
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
  
  /// 构建插件商店标签页
  Widget _buildPluginStoreTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '插件商店',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '即将推出...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  /// 显示安装插件对话框
  void _showInstallPluginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('安装插件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('从文件安装'),
              subtitle: const Text('选择插件文件(.zip)'),
              onTap: () {
                Navigator.of(context).pop();
                _installFromFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('从URL安装'),
              subtitle: const Text('输入插件下载链接'),
              onTap: () {
                Navigator.of(context).pop();
                _installFromUrl();
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('从商店安装'),
              subtitle: const Text('浏览插件商店'),
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
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
  
  /// 从文件安装插件
  void _installFromFile() async {
    try {
      // TODO: 实现文件选择器
      // 这里暂时使用模拟路径
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择插件文件')),
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
      //       SnackBar(content: Text(success ? '插件安装成功' : '插件安装失败')),
      //     );
      //   }
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('安装失败: $e')),
        );
      }
    }
  }
  
  /// 从URL安装插件
  void _installFromUrl() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从URL安装插件'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '插件URL',
            hintText: 'https://example.com/plugin.zip',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('安装'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      try {
        // TODO: 实现URL下载逻辑
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在下载插件...')),
        );
        
        // 这里需要实现下载逻辑
        // final downloadPath = await downloadPlugin(result);
        // final actions = ref.read(pluginActionsProvider);
        // final success = await actions.installPlugin(downloadPath);
        // 
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(content: Text(success ? '插件安装成功' : '插件安装失败')),
        //   );
        // }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL安装功能开发中')),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('安装失败: $e')),
          );
        }
      }
    }
  }
  
  /// 刷新插件列表
  void _refreshPlugins() async {
    try {
      final manager = ref.read(pluginManagerProvider);
      
      // 重新扫描插件目录
      await manager.initialize(manager.context ?? _createPluginContext());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('刷新完成')),
        );
      }
    } catch (e) {
      debugPrint('刷新插件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新失败: $e')),
        );
      }
    }
  }
  
  /// 显示插件详情
  void _showPluginDetails(Plugin plugin) {
    showDialog(
      context: context,
      builder: (context) => _PluginDetailsDialog(plugin: plugin),
    );
  }
}

/// 简单的编辑器控制器实现
class _SimpleEditorController implements EditorController {
  String _content = '';
  int _cursorPosition = 0;
  String _selectedText = '';

  @override
  String get content => _content;

  @override
  void setContent(String content) {
    _content = content;
  }

  @override
  void insertText(String text) {
    // 简单实现
  }

  @override
  String get selectedText => _selectedText;

  @override
  void replaceSelection(String text) {
    // 简单实现
  }

  @override
  int get cursorPosition => _cursorPosition;

  @override
  void setCursorPosition(int position) {
    _cursorPosition = position;
  }
}

/// 简单的语法注册器实现
class _SimpleSyntaxRegistry implements SyntaxRegistry {
  @override
  void registerSyntax(String name, RegExp pattern, String replacement) {
    // 简单实现
  }

  @override
  void registerBlockSyntax(String name, RegExp pattern, Widget Function(String content) builder) {
    // 简单实现
  }

  @override
  void registerInlineSyntax(String name, RegExp pattern, Widget Function(String content) builder) {
    // 简单实现
  }
}

/// 简单的工具栏注册器实现
class _SimpleToolbarRegistry implements ToolbarRegistry {
  @override
  void registerAction(PluginAction action, VoidCallback callback) {
    // 简单实现
  }

  @override
  void registerGroup(String groupId, String title, List<PluginAction> actions) {
    // 简单实现
  }

  @override
  void unregisterAction(String actionId) {
    // 简单实现
  }
}

/// 简单的菜单注册器实现
class _SimpleMenuRegistry implements MenuRegistry {
  @override
  void registerMenuItem(String menuId, String title, VoidCallback callback, {String? icon, String? shortcut}) {
    // 简单实现
  }

  @override
  void registerSubMenu(String parentId, String menuId, String title, List<String> items) {
    // 简单实现
  }

  @override
  void unregisterMenuItem(String menuId) {
    // 简单实现
  }
}

/// 插件详情对话框
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
            _buildInfoRow('版本', plugin.metadata.version),
            _buildInfoRow('作者', plugin.metadata.author),
            _buildInfoRow('类型', plugin.metadata.type.displayName),
            _buildInfoRow('状态', plugin.status.displayName),
            if (plugin.metadata.homepage != null)
              _buildInfoRow('主页', plugin.metadata.homepage!),
            const SizedBox(height: 16),
            Text(
              '描述',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(plugin.metadata.description),
            if (plugin.metadata.tags.isNotEmpty) ...
            [
              const SizedBox(height: 16),
              Text(
                '标签',
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
                    content: Text(success ? '插件已禁用' : '禁用插件失败'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('禁用'),
          )
        else if (plugin.status == PluginStatus.installed || plugin.status == PluginStatus.disabled)
          TextButton(
            onPressed: () async {
              final success = await actions.enablePlugin(plugin.metadata.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '插件已启用' : '启用插件失败'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('启用'),
          ),
        TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('确认卸载'),
                content: Text('确定要卸载插件 "${plugin.metadata.name}" 吗？此操作不可撤销。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('卸载'),
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
                    content: Text(success ? '插件已卸载' : '卸载插件失败'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('卸载'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
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