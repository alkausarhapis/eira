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

  String _formatRemainingTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBlocked = widget.blockedInfo?.isActive ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _iconBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _iconBytes!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.apps, color: theme.primaryColor),
                  ),
                )
              : Icon(Icons.apps, color: theme.primaryColor),
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
            if (isBlocked) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Diblokir • ${_formatRemainingTime(widget.blockedInfo!.remainingTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isBlocked
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'unblock') {
                    widget.onUnblockTap();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20),
                        SizedBox(width: 12),
                        Text('Hentikan Pemblokiran'),
                      ],
                    ),
                  ),
                ],
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
