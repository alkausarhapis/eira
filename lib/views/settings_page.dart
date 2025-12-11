import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/theme_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeViewModel = context.watch<ThemeViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Pengaturan', style: theme.textTheme.displayMedium),
              ),

              // Theme Section
              _SettingsSection(
                title: 'Tampilan',
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Mode Gelap',
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        'Gunakan tema gelap untuk kenyamanan mata',
                        style: theme.textTheme.bodyMedium,
                      ),
                      value: themeViewModel.isDarkMode,
                      onChanged: (value) => themeViewModel.toggleTheme(),
                      activeThumbColor: theme.primaryColor,
                    ),
                  ),
                ],
              ),

              // Limits Section
              _SettingsSection(
                title: 'Batasan',
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.timer, color: theme.primaryColor),
                      ),
                      title: Text(
                        'Durasi Istirahat',
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        '30 - 60 detik',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Placeholder for future implementation
                      },
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications,
                          color: theme.primaryColor,
                        ),
                      ),
                      title: Text(
                        'Notifikasi',
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        'Atur pengingat dan pemberitahuan',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Placeholder for future implementation
                      },
                    ),
                  ),
                ],
              ),

              // About Section
              _SettingsSection(
                title: 'Tentang',
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF9747FF),
                                      Color(0xFFB47FFF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Eira',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Versi 1.0.0', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Eira membantu kamu menyelesaikan tugas dengan cara memecahnya menjadi micro-task yang lebih mudah dikerjakan.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.privacy_tip,
                        color: theme.primaryColor,
                      ),
                      title: Text(
                        'Kebijakan Privasi',
                        style: theme.textTheme.bodyLarge,
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Placeholder for future implementation
                      },
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.description,
                        color: theme.primaryColor,
                      ),
                      title: Text(
                        'Syarat & Ketentuan',
                        style: theme.textTheme.bodyLarge,
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Placeholder for future implementation
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
