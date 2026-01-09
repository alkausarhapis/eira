import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_block_model.dart';
import '../viewmodels/blocked_apps_viewmodel.dart';

class AppListItem extends StatefulWidget {
  final InstalledAppModel app;
  final BlockedAppModel? blockedInfo;
  final VoidCallback onBlockTap;
  final VoidCallback onUnblockTap;

  const AppListItem({
    super.key,
    required this.app,
    this.blockedInfo,
    required this.onBlockTap,
    required this.onUnblockTap,
  });

  @override
  State<AppListItem> createState() => _AppListItemState();
}

class _AppListItemState extends State<AppListItem> {
  Uint8List? _iconBytes;
  bool _isLoadingIcon = false;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    if (_isLoadingIcon) return;

    setState(() => _isLoadingIcon = true);

    final viewModel = context.read<BlockedAppsViewModel>();
    await viewModel.loadAppIcon(widget.app.packageName);

    if (mounted) {
      setState(() {
        _iconBytes = viewModel.getAppIcon(widget.app.packageName);
        _isLoadingIcon = false;
      });
    }
  }

  String _formatDuration(int millis) {
    final hours = millis ~/ (1000 * 60 * 60);
    final minutes = (millis % (1000 * 60 * 60)) ~/ (1000 * 60);

    if (hours > 0) {
      return '${hours}j ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _showUnblockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pemblokiran?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pemblokiran untuk ${widget.app.appName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onUnblockTap();
            },
            child: const Text('Hapus Pemblokiran'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBlocked = widget.blockedInfo?.isActive ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 48,
          height: 48,
          child: _iconBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColorFiltered(
                    colorFilter: isBlocked
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child: Image.memory(
                      _iconBytes!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.apps,
                        color: isBlocked ? Colors.grey : theme.primaryColor,
                      ),
                    ),
                  ),
                )
              : Icon(
                  Icons.apps,
                  color: isBlocked ? Colors.grey : theme.primaryColor,
                ),
        ),
        title: Text(
          widget.app.appName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(widget.app.formattedTime, style: theme.textTheme.bodyMedium),
          ],
        ),
        trailing: isBlocked
            ? SizedBox(
                width: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.hourglass_disabled,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                        onPressed: widget.onUnblockTap,
                        tooltip: 'Hapus pembatasan',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(widget.blockedInfo!.blockDurationMillis),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              )
            : IconButton(
                icon: Icon(Icons.hourglass_empty, color: theme.primaryColor),
                onPressed: widget.onBlockTap,
                tooltip: 'Blokir aplikasi',
              ),
      ),
    );
  }
}
