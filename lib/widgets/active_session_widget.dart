import 'package:flutter/material.dart';

class ActiveSessionWidget extends StatelessWidget {
  final String currentTask;
  final Duration elapsedTime;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onComplete;
  final int? restTimeRemaining;

  const ActiveSessionWidget({
    super.key,
    required this.currentTask,
    required this.elapsedTime,
    required this.isPaused,
    required this.onPause,
    required this.onComplete,
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
              Text(
                'Sesi Saat Ini',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(currentTask, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _formatDuration(elapsedTime),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check),
                      label: const Text('Selesai'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
