import 'package:flutter/material.dart';

import '../models/microtask_model.dart';

class MicrotaskCard extends StatefulWidget {
  final MicroTaskModel microtask;
  final VoidCallback onStart;
  final bool canStart;
  final Function(String)? onDelete;

  const MicrotaskCard({
    super.key,
    required this.microtask,
    required this.onStart,
    required this.canStart,
    this.onDelete,
  });

  @override
  State<MicrotaskCard> createState() => _MicrotaskCardState();
}

class _MicrotaskCardState extends State<MicrotaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = widget.microtask.microtasks
        .where((item) => item.isCompleted)
        .length;
    final totalCount = widget.microtask.microtasks.length;
    final isInProgress = widget.microtask.status == 'in-progress';

    return Dismissible(
      key: Key(widget.microtask.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Micro-task'),
            content: Text(
              'Yakin ingin menghapus "${widget.microtask.judulTarget}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        widget.onDelete?.call(widget.microtask.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isInProgress
              ? Border.all(color: const Color(0xFF9747FF), width: 2)
              : null,
          boxShadow: isInProgress
              ? [
                  BoxShadow(
                    color: const Color(0xFF9747FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: isInProgress
              ? const Color(0xFF9747FF).withValues(alpha: 0.1)
              : null,
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        widget.microtask.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.microtask.judulTarget,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCount dari $totalCount selesai',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.microtask.deskripsi,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ...widget.microtask.microtasks.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                item.isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 20,
                                color: item.isCompleted
                                    ? theme.primaryColor
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.task,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (widget.microtask.status != 'done') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.canStart ? widget.onStart : null,
                            child: Text(
                              widget.microtask.status == 'in-progress'
                                  ? 'Sedang Berjalan'
                                  : 'Mulai',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
