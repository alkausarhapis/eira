import 'package:flutter/material.dart';

class BlockedAppsPage extends StatelessWidget {
  const BlockedAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dummy data for placeholder
    final dummyApps = [
      {'name': 'Instagram', 'icon': Icons.photo_camera, 'blocked': true},
      {'name': 'TikTok', 'icon': Icons.video_library, 'blocked': true},
      {'name': 'Twitter', 'icon': Icons.chat_bubble, 'blocked': false},
      {'name': 'YouTube', 'icon': Icons.play_circle_outline, 'blocked': true},
      {'name': 'Facebook', 'icon': Icons.facebook, 'blocked': false},
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Blokir Aplikasi', style: theme.textTheme.displayMedium),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: dummyApps.length,
                itemBuilder: (context, index) {
                  final app = dummyApps[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          app['icon'] as IconData,
                          color: theme.primaryColor,
                        ),
                      ),
                      title: Text(
                        app['name'] as String,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        app['blocked'] as bool
                            ? 'Terblokir'
                            : 'Tidak Terblokir',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Switch(
                        value: app['blocked'] as bool,
                        onChanged: (value) {
                          // Placeholder - will integrate with native code later
                        },
                        activeColor: theme.primaryColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fitur blokir aplikasi akan terintegrasi dengan layanan aksesibilitas native',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
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
