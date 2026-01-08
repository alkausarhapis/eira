import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/blocked_apps_viewmodel.dart';

class BlockDurationModal extends StatefulWidget {
  final String packageName;
  final String appName;
  final int timeSpent;

  const BlockDurationModal({
    super.key,
    required this.packageName,
    required this.appName,
    required this.timeSpent,
  });

  @override
  State<BlockDurationModal> createState() => _BlockDurationModalState();
}

class _BlockDurationModalState extends State<BlockDurationModal> {
  int? _selectedMinutes;
  final TextEditingController _customController = TextEditingController();
  bool _isBlocking = false;

  final List<int> presetMinutes = [5, 10, 30, 60, 120, 360];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes menit';
    } else {
      final hours = minutes ~/ 60;
      return '$hours jam';
    }
  }

  Future<void> _confirmBlock() async {
    int minutes = _selectedMinutes ?? 0;

    if (_selectedMinutes == null && _customController.text.isNotEmpty) {
      minutes = int.tryParse(_customController.text) ?? 0;
    }

    if (minutes <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih durasi pemblokiran')));
      return;
    }

    setState(() => _isBlocking = true);

    final viewModel = context.read<BlockedAppsViewModel>();
    // Use the selected minutes as daily usage limit
    final usageLimit = Duration(minutes: minutes);

    final success = await viewModel.blockApp(
      packageName: widget.packageName,
      appName: widget.appName,
      usageLimit: usageLimit,
    );

    if (mounted) {
      setState(() => _isBlocking = false);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.appName} akan diblokir selama 24 jam setelah digunakan $minutes menit',
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memblokir aplikasi. Periksa izin akses.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodyMedium?.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Blokir ${widget.appName}',
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih batas waktu penggunaan, setelah itu aplikasi akan diblokir selama 24 jam.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Preset options
              Text(
                'Batas Waktu Penggunaan',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presetMinutes.map((minutes) {
                  final isSelected = _selectedMinutes == minutes;
                  return ChoiceChip(
                    label: Text(_formatMinutes(minutes)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMinutes = selected ? minutes : null;
                        if (selected) _customController.clear();
                      });
                    },
                    selectedColor: theme.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Custom input
              Text(
                'Atau Masukkan Sendiri (menit)',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 45',
                  suffixText: 'menit',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() => _selectedMinutes = null);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Info box
              Container(
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
                        'Aplikasi akan diblokir selama 24 jam setelah batas waktu tercapai',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBlocking
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white54
                              : theme.primaryColor,
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isBlocking ? null : _confirmBlock,
                      child: _isBlocking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Blokir 24 Jam'),
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
