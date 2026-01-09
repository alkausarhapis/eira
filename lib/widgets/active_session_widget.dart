import 'package:flutter/material.dart';

class ActiveSessionWidget extends StatelessWidget {
  final String currentTask;
  final String sessionTitle;
  final String sessionEmoji;
  final Duration elapsedTime;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onComplete;
  final VoidCallback? onAbandon;
  final VoidCallback? onSkipRest;
  final int? restTimeRemaining;

  const ActiveSessionWidget({
    super.key,
    required this.currentTask,
    required this.sessionTitle,
    required this.sessionEmoji,
    required this.elapsedTime,
    required this.isPaused,
    required this.onPause,
    required this.onComplete,
    this.onAbandon,
    this.onSkipRest,
    this.restTimeRemaining,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours : $minutes : $seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (restTimeRemaining != null) {
      return SizedBox(
        width: double.infinity,
        child: Card(
          color: theme.primaryColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Istirahat Sejenak',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$restTimeRemaining detik',
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ambil waktu untuk istirahat sejenak sebelum melanjutkan tugas berikutnya.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (onSkipRest != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Lewati Istirahat?'),
                          content: const Text(
                            'Apakah kamu yakin ingin melewati waktu istirahat dan langsung melanjutkan ke task berikutnya?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Lewati'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        onSkipRest!();
                      }
                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Lewati Istirahat'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Card(
        color: theme.primaryColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session header with emoji and title
              Row(
                children: [
                  Text(sessionEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SESI AKTIF',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sessionTitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Current task with highlight
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Sekarang',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentTask,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Timer
              Center(
                child: Column(
                  children: [
                    Text(
                      'Waktu Berjalan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(elapsedTime),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (onAbandon != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Batalkan Sesi?'),
                              content: const Text(
                                'Apakah kamu yakin ingin membatalkan sesi ini? Semua progress akan hilang dan task akan kembali ke status awal.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Batalkan Sesi'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            onAbandon!();
                          }
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Batalkan'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPause,
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(isPaused ? 'Lanjutkan' : 'Jeda'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.primaryColor),
                        foregroundColor: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check),
                label: const Text('Selesai'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
