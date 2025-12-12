import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/native_block_service.dart';
import '../viewmodels/microtask_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../widgets/active_session_widget.dart';
import '../widgets/logo_widget.dart';
import '../widgets/microtask_card.dart';
import '../widgets/primary_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _promptController = TextEditingController();
  final NativeBlockService _nativeService = NativeBlockService();
  bool _isGenerating = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateMicrotasks(BuildContext context) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isGenerating = true);

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      context.read<MicrotaskViewModel>().generateMicrotasks(prompt);
      _promptController.clear();
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _showFocusModeDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Fokus'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dengan mengaktifkan Fokus Mode:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('• Layar penuh akan ditutup dengan overlay hitam'),
            SizedBox(height: 8),
            Text('• Semua notifikasi dan distraksi akan tersembunyi'),
            SizedBox(height: 8),
            Text(
              '• Kamu hanya bisa keluar dengan menekan tombol "Hentikan Fokus"',
            ),
            SizedBox(height: 8),
            Text('• Timer akan mencatat durasi fokusmu'),
            SizedBox(height: 16),
            Text(
              'Apakah kamu siap untuk fokus?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Paham, Mulai Fokus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Start native focus mode overlay
      await _nativeService.startFocusMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeViewModel = context.watch<ThemeViewModel>();
    final microtaskViewModel = context.watch<MicrotaskViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with logo and theme toggle
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LogoWidget(),
                  IconButton(
                    onPressed: () => themeViewModel.toggleTheme(),
                    icon: Icon(
                      themeViewModel.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    tooltip: themeViewModel.isDarkMode
                        ? 'Mode Terang'
                        : 'Mode Malam',
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prompt Section
                    Text(
                      'Apa yang ingin kamu selesaikan?',
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _promptController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'Contoh: Belajar Flutter untuk membuat aplikasi mobile',
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Generate Micro-tasks',
                      icon: Icons.auto_awesome,
                      onPressed: () => _generateMicrotasks(context),
                      isLoading: _isGenerating,
                    ),
                    const SizedBox(height: 32),

                    // Active Session
                    if (microtaskViewModel.activeSession != null) ...[
                      ActiveSessionWidget(
                        currentTask: microtaskViewModel.currentTaskText ?? '',
                        elapsedTime: microtaskViewModel.elapsedTime,
                        isPaused: microtaskViewModel.isPaused,
                        restTimeRemaining: microtaskViewModel.restTimeRemaining,
                        onPause: () => microtaskViewModel.pauseSession(),
                        onComplete: () =>
                            microtaskViewModel.completeCurrentMicrotask(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Microtask List
                    if (microtaskViewModel.microtasks.isNotEmpty) ...[
                      Text(
                        'Daftar Micro-task',
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 16),
                      ...microtaskViewModel.microtasks.map((microtask) {
                        return MicrotaskCard(
                          microtask: microtask,
                          canStart:
                              !microtaskViewModel.hasActiveSession &&
                              microtask.status == 'pending',
                          onStart: () =>
                              microtaskViewModel.startSession(microtask),
                        );
                      }),
                    ] else ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 64,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada micro-task',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mulai dengan menuliskan apa yang ingin kamu selesaikan',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFocusModeDialog,
        backgroundColor: const Color(0xFF9747FF),
        elevation: 4,
        child: const Icon(Icons.do_disturb_on_outlined),
      ),
    );
  }
}
