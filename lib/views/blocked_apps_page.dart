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
                                _searchController.clear();
                                viewModel.setSearchQuery('');
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
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                // Blocked Apps Section
                                if (viewModel.installedApps.any(
                                  (app) =>
                                      viewModel
                                          .getBlockedAppInfo(app.packageName)
                                          ?.isActive ==
                                      true,
                                )) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      8,
                                      0,
                                      12,
                                    ),
                                    child: Text(
                                      'Aplikasi Dibatasi',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.primaryColor,
                                          ),
                                    ),
                                  ),
                                  ...viewModel.installedApps
                                      .where(
                                        (app) =>
                                            viewModel
                                                .getBlockedAppInfo(
                                                  app.packageName,
                                                )
                                                ?.isActive ==
                                            true,
                                      )
                                      .map((app) {
                                        final blockedInfo = viewModel
                                            .getBlockedAppInfo(app.packageName);
                                        return AppListItem(
                                          app: app,
                                          blockedInfo: blockedInfo,
                                          onBlockTap: () =>
                                              _showBlockDurationModal(
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
                                                  'Apakah Anda yakin ingin menghentikan pemblokiran ${app.appName}?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('Batal'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      'Hentikan',
                                                    ),
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
                                      }),
                                  const SizedBox(height: 16),
                                ],

                                // All Apps Section
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    8,
                                    0,
                                    12,
                                  ),
                                  child: Text(
                                    'Semua Aplikasi',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                                ...viewModel.installedApps
                                    .where(
                                      (app) =>
                                          viewModel
                                              .getBlockedAppInfo(app.packageName)
                                              ?.isActive !=
                                          true,
                                    )
                                    .map((app) {
                                  final blockedInfo = viewModel
                                      .getBlockedAppInfo(app.packageName);
                                  return AppListItem(
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
                                            'Apakah Anda yakin ingin menghentikan pemblokiran ${app.appName}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Batal'),
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
                                }),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
