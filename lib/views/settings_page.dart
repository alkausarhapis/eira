import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/native_block_service.dart';
import '../viewmodels/theme_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final NativeBlockService _nativeService = NativeBlockService();
  Map<String, bool> _permissions = {
    'overlayGranted': false,
    'accessibilityGranted': false,
    'usageStatsGranted': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final permissions = await _nativeService.getPermissionsStatus();
    if (mounted) {
      setState(() {
        _permissions = permissions;
      });
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kebijakan Privasi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Eira berkomitmen untuk melindungi privasi Anda. Kebijakan privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi Anda.\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '1. Pengumpulan Data\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Eira mengumpulkan data berikut untuk menjalankan fungsinya:\n'
                '• Daftar aplikasi yang terinstal di perangkat Anda\n'
                '• Statistik penggunaan aplikasi (waktu penggunaan)\n'
                '• Preferensi pembatasan aplikasi yang Anda atur\n\n',
              ),
              const Text(
                '2. Penggunaan Data\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Data yang dikumpulkan digunakan untuk:\n'
                '• Menampilkan waktu penggunaan aplikasi\n'
                '• Menjalankan fitur pembatasan aplikasi\n'
                '• Menyimpan preferensi pengaturan Anda\n\n',
              ),
              const Text(
                '3. Penyimpanan Data\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Semua data disimpan secara lokal di perangkat Anda. Kami tidak mengirim, menyimpan, atau membagikan data Anda ke server eksternal atau pihak ketiga.\n\n',
              ),
              const Text(
                '4. Izin Aplikasi\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Eira memerlukan izin berikut:\n'
                '• Aksesibilitas: Untuk mendeteksi aplikasi yang sedang aktif\n'
                '• Statistik Penggunaan: Untuk melihat waktu penggunaan aplikasi\n'
                '• Tampilan di Atas Aplikasi Lain: Untuk menampilkan overlay pemblokiran\n\n'
                'Izin ini tidak digunakan untuk mengakses data pribadi atau sensitif Anda.\n\n',
              ),
              const Text(
                '5. Keamanan\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Kami menerapkan langkah-langkah keamanan untuk melindungi data Anda dari akses yang tidak sah. Karena semua data disimpan secara lokal, keamanan data bergantung pada keamanan perangkat Anda.\n\n',
              ),
              const Text(
                '6. Hak Anda\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Anda dapat:\n'
                '• Menghapus data aplikasi kapan saja melalui pengaturan sistem Android\n'
                '• Mencabut izin aplikasi melalui pengaturan sistem Android\n'
                '• Menghapus aplikasi untuk menghapus semua data yang tersimpan\n\n',
              ),
              const Text(
                'Terakhir diperbarui: 9 Januari 2026',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTermsConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Syarat & Ketentuan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dengan menggunakan Eira, Anda menyetujui syarat dan ketentuan berikut:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '1. Penggunaan Aplikasi\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Eira adalah aplikasi produktivitas yang dirancang untuk membantu Anda mengelola waktu penggunaan aplikasi. Anda bertanggung jawab penuh atas cara Anda menggunakan aplikasi ini.\n\n',
              ),
              const Text(
                '2. Izin dan Aksesibilitas\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Eira memerlukan izin Aksesibilitas untuk menjalankan fungsinya. Izin ini hanya digunakan untuk:\n'
                '• Mendeteksi aplikasi yang sedang berjalan\n'
                '• Menampilkan overlay pemblokiran\n'
                '• Melacak waktu penggunaan aplikasi\n\n'
                'Eira TIDAK akan:\n'
                '• Membaca konten layar atau teks yang Anda ketik\n'
                '• Mengakses data pribadi atau sensitif\n'
                '• Mengirim data ke server eksternal\n\n',
              ),
              const Text(
                '3. Kepatuhan Terhadap Aplikasi Perbankan\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Eira dirancang untuk tidak mengganggu aplikasi perbankan dan aplikasi keamanan. Fitur pemblokiran secara otomatis dinonaktifkan saat aplikasi sensitif terdeteksi.\n\n',
              ),
              const Text(
                '4. Batasan Tanggung Jawab\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Eira disediakan "sebagaimana adanya" tanpa jaminan apa pun. Kami tidak bertanggung jawab atas:\n'
                '• Kehilangan data akibat kesalahan penggunaan\n'
                '• Masalah kompatibilitas dengan perangkat tertentu\n'
                '• Gangguan pada aplikasi lain yang tidak disengaja\n\n',
              ),
              const Text(
                '5. Penghentian Layanan\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Anda dapat berhenti menggunakan Eira kapan saja dengan:\n'
                '• Menonaktifkan layanan Aksesibilitas di pengaturan sistem\n'
                '• Menghapus aplikasi dari perangkat Anda\n\n',
              ),
              const Text(
                '6. Perubahan Syarat\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Kami berhak mengubah syarat dan ketentuan ini kapan saja. Perubahan akan diinformasikan melalui pembaruan aplikasi.\n\n',
              ),
              const Text(
                '7. Kontak\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Jika Anda memiliki pertanyaan tentang syarat dan ketentuan ini, silakan hubungi kami melalui pengaturan aplikasi.\n\n',
              ),
              const Text(
                'Terakhir diperbarui: 9 Januari 2026',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

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

              // Permissions Section
              _SettingsSection(
                title: 'Izin Aplikasi',
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
                          color: _permissions['overlayGranted'] == true
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _permissions['overlayGranted'] == true
                              ? Icons.check_circle
                              : Icons.layers,
                          color: _permissions['overlayGranted'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      title: Text(
                        'Tampilkan di Atas Aplikasi Lain',
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        _permissions['overlayGranted'] == true
                            ? 'Diizinkan'
                            : 'Diperlukan untuk fitur blocking',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: _permissions['overlayGranted'] != true
                          ? TextButton(
                              onPressed: () async {
                                await _nativeService.requestOverlayPermission();
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                await _loadPermissions();
                              },
                              child: const Text('Aktifkan'),
                            )
                          : null,
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
                          color: _permissions['accessibilityGranted'] == true
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _permissions['accessibilityGranted'] == true
                              ? Icons.check_circle
                              : Icons.accessibility_new,
                          color: _permissions['accessibilityGranted'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      title: Text(
                        'Aksesibilitas',
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        _permissions['accessibilityGranted'] == true
                            ? 'Diizinkan'
                            : 'Diperlukan untuk mendeteksi aplikasi',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: _permissions['accessibilityGranted'] != true
                          ? TextButton(
                              onPressed: () async {
                                await _nativeService
                                    .requestAccessibilitySettings();
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                await _loadPermissions();
                              },
                              child: const Text('Aktifkan'),
                            )
                          : null,
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
                          color: _permissions['usageStatsGranted'] == true
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _permissions['usageStatsGranted'] == true
                              ? Icons.check_circle
                              : Icons.bar_chart,
                          color: _permissions['usageStatsGranted'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      title: Text(
                        'Statistik Penggunaan',
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        _permissions['usageStatsGranted'] == true
                            ? 'Diizinkan'
                            : 'Diperlukan untuk melihat waktu penggunaan',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: _permissions['usageStatsGranted'] != true
                          ? TextButton(
                              onPressed: () async {
                                await _nativeService
                                    .requestUsageStatsPermission();
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                await _loadPermissions();
                              },
                              child: const Text('Aktifkan'),
                            )
                          : null,
                    ),
                  ),
                ],
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
                      onTap: () => _showPrivacyPolicy(context),
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
                      onTap: () => _showTermsConditions(context),
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
