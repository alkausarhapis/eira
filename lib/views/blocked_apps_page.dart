import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/blocked_apps_viewmodel.dart';
import '../widgets/app_list_item.dart';
import '../widgets/block_duration_modal.dart';
import '../widgets/permissions_banner.dart';

class BlockedAppsPage extends StatefulWidget {
  const BlockedAppsPage({super.key});

  @override
  State<BlockedAppsPage> createState() => _BlockedAppsPageState();
}

class _BlockedAppsPageState extends State<BlockedAppsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to search controller changes to rebuild UI
    _searchController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<BlockedAppsViewModel>();
      viewModel.checkPermissions();
      viewModel.loadInstalledApps();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBlockDurationModal(
    BuildContext context,
    String packageName,
    String appName,
    int timeSpent,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlockDurationModal(
        packageName: packageName,
        appName: appName,
        timeSpent: timeSpent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<BlockedAppsViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Blokir Aplikasi', style: theme.textTheme.displayMedium),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari aplikasi...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  viewModel.setSearchQuery('');
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => viewModel.setSearchQuery(value),
                  ),
                ],
              ),
            ),

            // Permissions banner
            if (!viewModel.hasAllPermissions) const PermissionsBanner(),

            // App list
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await viewModel.checkPermissions();
                        await viewModel.loadInstalledApps();
                      },
                      child: viewModel.installedApps.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(32),
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.apps,
                                      size: 64,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada aplikasi',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Izinkan akses Usage Stats untuk melihat daftar aplikasi',
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: viewModel.installedApps.length,
                              itemBuilder: (context, index) {
                                final app = viewModel.installedApps[index];
                                final blockedInfo = viewModel.getBlockedAppInfo(
                                  app.packageName,
                                );

                                return AppListItem(
                                  key: ValueKey(app.packageName),
                                  app: app,
                                  blockedInfo: blockedInfo,
                                  onBlockTap: () => _showBlockDurationModal(
                                    context,
                                    app.packageName,
                                    app.appName,
                                    app.totalTimeMillis,
                                  ),
                                  onUnblockTap: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Hentikan Pemblokiran?',
                                        ),
                                        content: Text(
                                          'Apakah Kamu yakin ingin menghentikan pemblokiran ${app.appName}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              'Batal',
                                              style: TextStyle(
                                                color: theme.disabledColor,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Hentikan'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await viewModel.unblockApp(
                                        app.packageName,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
