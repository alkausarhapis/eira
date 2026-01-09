import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/native_block_service.dart';
import '../viewmodels/microtask_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../widgets/active_session_widget.dart';
import '../widgets/logo_widget.dart';
import '../widgets/microtask_card.dart';
import '../widgets/primary_button.dart';
import 'create_microtask_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocusNode = FocusNode();
  final NativeBlockService _nativeService = NativeBlockService();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Set completion callback after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<MicrotaskViewModel>();
      viewModel.setOnMicrotaskCompleted((title) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Micro-task "$title" diselesaikan!')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });

      viewModel.setOnMicrotaskDeleted((title) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Micro-task "$title" telah dihapus')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });

      viewModel.setOnInvalidPrompt(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tugas ini tidak dapat diproses karena alasan keamanan.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocusNode.dispose();
    super.dispose();
  }

  Future<void> _generateMicrotasks(BuildContext context) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isGenerating = true);

    if (mounted) {
      await context.read<MicrotaskViewModel>().generateMicrotasks(prompt);
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
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with logo and theme toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const LogoWidget(),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context
                              .read<MicrotaskViewModel>()
                              .refreshMicrotasks(),
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                        ),
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
                  ],
                ),
                const SizedBox(height: 16),

                // Prompt Section
                Text(
                  'Apa yang ingin kamu selesaikan?',
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: 16),
                AnimatedTextField(
                  focusNode: _promptFocusNode,
                  animationType: Animationtype.typer,
                  controller: _promptController,
                  maxLines: 4,
                  hintTextStyle: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  hintTexts: const [
                    'Belajar Flutter untuk membuat...',
                    'Menyelesaikan tugas kuliah minggu ini...',
                    'Buat proyek side hustle baru...',
                    'Belajar algoritma dan struktur data...',
                    'Membaca buku non-fiksi 30 halaman...',
                    'Membersihkan dan mengorganisir kamar...',
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Generate Micro-tasks',
                  icon: Icons.auto_awesome,
                  onPressed: () => _generateMicrotasks(context),
                  isLoading: _isGenerating,
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateMicrotaskPage(),
                        ),
                      );
                    },
                    child: const Text('atau buat micro-task manual'),
                  ),
                ),
                const SizedBox(height: 16),

                if (microtaskViewModel.activeSession != null) ...[
                  ActiveSessionWidget(
                    currentTask: microtaskViewModel.currentTaskText ?? '',
                    sessionTitle: microtaskViewModel.activeSession!.judulTarget,
                    sessionEmoji: microtaskViewModel.activeSession!.emoji,
                    elapsedTime: microtaskViewModel.elapsedTime,
                    isPaused: microtaskViewModel.isPaused,
                    restTimeRemaining: microtaskViewModel.restTimeRemaining,
                    onPause: () => microtaskViewModel.pauseSession(),
                    onComplete: () =>
                        microtaskViewModel.completeCurrentMicrotask(),
                    onAbandon: () => microtaskViewModel.abandonSession(),
                    onSkipRest: () => microtaskViewModel.skipRest(),
                  ),
                  const SizedBox(height: 32),
                ],

                if (microtaskViewModel.microtasks.isNotEmpty) ...[
                  // Active and Pending Tasks Section
                  if (microtaskViewModel.microtasks.any(
                    (m) => m.status != 'done',
                  )) ...[
                    Text(
                      'Daftar Micro-task',
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 16),
                    ...microtaskViewModel.microtasks
                        .where((microtask) => microtask.status != 'done')
                        .map((microtask) {
                          return MicrotaskCard(
                            microtask: microtask,
                            canStart:
                                !microtaskViewModel.hasActiveSession &&
                                microtask.status == 'pending',
                            onStart: () =>
                                microtaskViewModel.startSession(microtask),
                            onDelete: (id) =>
                                microtaskViewModel.deleteMicrotask(id),
                          );
                        }),
                    const SizedBox(height: 32),
                  ],

                  // Finished Tasks Section
                  if (microtaskViewModel.microtasks.any(
                    (m) => m.status == 'done',
                  )) ...[
                    Text(
                      'Micro-task Selesai',
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 16),
                    ...microtaskViewModel.microtasks
                        .where((microtask) => microtask.status == 'done')
                        .map((microtask) {
                          return MicrotaskCard(
                            microtask: microtask,
                            canStart: false,
                            onStart: () {},
                            onDelete: (id) =>
                                microtaskViewModel.deleteMicrotask(id),
                          );
                        }),
                  ],
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
