import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/blocked_apps_viewmodel.dart';

class PermissionsBanner extends StatelessWidget {
  const PermissionsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<BlockedAppsViewModel>();
    final permissions = viewModel.permissions;

    final missingPermissions = <MapEntry<String, String>>[];

    if (permissions['overlayGranted'] != true) {
      missingPermissions.add(
        const MapEntry('overlay', 'Tampilkan di atas aplikasi lain'),
      );
    }
    if (permissions['accessibilityGranted'] != true) {
      missingPermissions.add(const MapEntry('accessibility', 'Aksesibilitas'));
    }
    if (permissions['usageStatsGranted'] != true) {
      missingPermissions.add(
        const MapEntry('usageStats', 'Statistik Penggunaan'),
      );
    }

    if (missingPermissions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Izin Diperlukan',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Eira memerlukan izin berikut untuk memblokir aplikasi:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...missingPermissions.map((permission) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(permission.value)),
                  TextButton(
                    onPressed: () {
                      switch (permission.key) {
                        case 'overlay':
                          viewModel.requestOverlayPermission();
                          break;
                        case 'accessibility':
                          viewModel.requestAccessibilityPermission();
                          break;
                        case 'usageStats':
                          viewModel.requestUsageStatsPermission();
                          break;
                      }
                    },
                    child: const Text('Aktifkan'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
