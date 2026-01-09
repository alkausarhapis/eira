import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/microtask_model.dart';
import '../viewmodels/microtask_viewmodel.dart';
import '../widgets/primary_button.dart';

class EditMicrotaskPage extends StatefulWidget {
  final MicroTaskModel microtask;

  const EditMicrotaskPage({super.key, required this.microtask});

  @override
  State<EditMicrotaskPage> createState() => _EditMicrotaskPageState();
}

class _EditMicrotaskPageState extends State<EditMicrotaskPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late List<TextEditingController> _taskControllers;
  late List<TextEditingController> _restTimeControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.microtask.judulTarget,
    );
    _descController = TextEditingController(text: widget.microtask.deskripsi);
    _taskControllers = widget.microtask.microtasks
        .map((item) => TextEditingController(text: item.task))
        .toList();
    _restTimeControllers = widget.microtask.microtasks
        .map(
          (item) =>
              TextEditingController(text: item.restTimeSeconds.toString()),
        )
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    for (var controller in _restTimeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addNewTask() {
    setState(() {
      _taskControllers.add(TextEditingController());
      _restTimeControllers.add(TextEditingController(text: '60'));
    });
  }

  void _removeTask(int index) {
    if (_taskControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada satu task'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _taskControllers[index].dispose();
      _restTimeControllers[index].dispose();
      _taskControllers.removeAt(index);
      _restTimeControllers.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deskripsi tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (int i = 0; i < _taskControllers.length; i++) {
      if (_taskControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task ${i + 1} tidak boleh kosong'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final newItems = List.generate(_taskControllers.length, (index) {
      final isCompleted = index < widget.microtask.microtasks.length
          ? widget.microtask.microtasks[index].isCompleted
          : false;
      return MicroTaskItem(
        task: _taskControllers[index].text.trim(),
        restTimeSeconds: int.tryParse(_restTimeControllers[index].text) ?? 60,
        isCompleted: isCompleted,
      );
    });

    await context.read<MicrotaskViewModel>().updateMicrotaskDetails(
      widget.microtask.id,
      _titleController.text.trim(),
      _descController.text.trim(),
      newItems,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Micro-task berhasil diperbarui'),
            ],
          ),
          backgroundColor: Color(0xFF9747FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Micro-task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji display
                    Center(
                      child: Text(
                        widget.microtask.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    Text(
                      'Judul Target',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan judul target',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 24),

                    // Description field
                    Text(
                      'Deskripsi',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan deskripsi singkat',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Tasks section header
                    Text(
                      'Daftar Task',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tasks list
                    ...List.generate(_taskControllers.length, (index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Task ${index + 1}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeTask(index),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    iconSize: 20,
                                    tooltip: 'Hapus task',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Deskripsi Task',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _taskControllers[index],
                                decoration: const InputDecoration(
                                  hintText: 'Apa yang harus dilakukan?',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Waktu Istirahat Setelah Task',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _restTimeControllers[index],
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: 60',
                                  prefixIcon: Icon(Icons.timer_outlined),
                                  suffixText: 'detik',
                                  helperText:
                                      'Waktu istirahat setelah menyelesaikan task ini',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Add new task button
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addNewTask,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Task Baru'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        side: BorderSide(color: theme.primaryColor),
                        foregroundColor: theme.primaryColor,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: PrimaryButton(
                  text: 'Simpan Perubahan',
                  icon: Icons.save,
                  onPressed: _saveChanges,
                  isLoading: _isSaving,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
