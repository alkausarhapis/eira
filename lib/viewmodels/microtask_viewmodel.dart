import 'dart:async';

import 'package:flutter/material.dart';

import '../models/microtask_model.dart';
import '../services/gemini_service.dart';
import '../services/microtasks_database.dart';

class MicrotaskViewModel extends ChangeNotifier {
  List<MicroTaskModel> _microtasks = [];
  MicroTaskModel? _activeSession;
  int _currentMicrotaskIndex = 0;
  Duration _elapsedTime = Duration.zero;
  bool _isPaused = false;
  Timer? _timer;
  int? _restTimeRemaining;
  Timer? _restTimer;
  bool _isGenerating = false;
  bool _isLoading = true;
  Function(String)? _onMicrotaskCompleted;
  Function(String)? _onMicrotaskDeleted;
  Function()? _onInvalidPrompt;

  final GeminiService _geminiService = GeminiService();
  final MicrotasksDatabase _database = MicrotasksDatabase.instance;

  MicrotaskViewModel() {
    _loadMicrotasks();
  }

  Future<void> _loadMicrotasks() async {
    try {
      _isLoading = true;
      notifyListeners();

      _microtasks = await _database.getAllMicrotasks();

      // Sort: in-progress first, then pending, then done
      _microtasks.sort((a, b) {
        const statusOrder = {'in-progress': 0, 'pending': 1, 'done': 2};
        final aOrder = statusOrder[a.status] ?? 3;
        final bOrder = statusOrder[b.status] ?? 3;
        return aOrder.compareTo(bOrder);
      });

      // Restore active session if there's an in-progress microtask
      final inProgressTask = _microtasks.firstWhere(
        (task) => task.status == 'in-progress',
        orElse: () => _microtasks.first,
      );

      if (inProgressTask.status == 'in-progress') {
        _activeSession = inProgressTask;
        _elapsedTime = inProgressTask.timeTaken;

        // Find the current microtask index
        _currentMicrotaskIndex = inProgressTask.microtasks.indexWhere(
          (item) => !item.isCompleted,
        );

        if (_currentMicrotaskIndex == -1) {
          // All tasks completed, start timer for completion
          _currentMicrotaskIndex = inProgressTask.microtasks.length - 1;
        }

        // Resume timer
        _isPaused = false;
        _startTimer();

        debugPrint('✅ Restored active session: ${inProgressTask.judulTarget}');
        debugPrint(
          '   Current index: $_currentMicrotaskIndex, Elapsed: $_elapsedTime',
        );
      }

      debugPrint('✅ Loaded ${_microtasks.length} microtasks from database');
    } catch (e) {
      debugPrint('❌ Error loading microtasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<MicroTaskModel> get microtasks => _microtasks;
  MicroTaskModel? get activeSession => _activeSession;
  int get currentMicrotaskIndex => _currentMicrotaskIndex;
  Duration get elapsedTime => _elapsedTime;
  bool get isPaused => _isPaused;
  int? get restTimeRemaining => _restTimeRemaining;
  bool get isGenerating => _isGenerating;
  bool get isLoading => _isLoading;

  Future<void> refreshMicrotasks() async {
    await _loadMicrotasks();
  }

  String? get currentTaskText {
    if (_activeSession == null) return null;
    if (_currentMicrotaskIndex >= _activeSession!.microtasks.length) {
      return null;
    }
    return _activeSession!.microtasks[_currentMicrotaskIndex].task;
  }

  bool get hasActiveSession =>
      _activeSession != null && _restTimeRemaining == null;

  void setOnMicrotaskCompleted(Function(String)? callback) {
    _onMicrotaskCompleted = callback;
  }

  void setOnMicrotaskDeleted(Function(String)? callback) {
    _onMicrotaskDeleted = callback;
  }

  void setOnInvalidPrompt(Function()? callback) {
    _onInvalidPrompt = callback;
  }

  void addMicrotask(MicroTaskModel microtask) {
    _microtasks.add(microtask);
    notifyListeners();
  }

  Future<void> addAndSaveMicrotask(MicroTaskModel microtask) async {
    try {
      // Add to memory first
      _microtasks.add(microtask);

      // Re-sort the list
      _microtasks.sort((a, b) {
        const statusOrder = {'in-progress': 0, 'pending': 1, 'done': 2};
        final aOrder = statusOrder[a.status] ?? 3;
        final bOrder = statusOrder[b.status] ?? 3;
        return aOrder.compareTo(bOrder);
      });

      notifyListeners();

      // Save to database
      await _database.insertMicrotask(microtask);
      debugPrint('💾 Saved manually created microtask: ${microtask.id}');
    } catch (e) {
      debugPrint('❌ Error saving microtask: $e');
    }
  }

  Future<void> deleteMicrotask(String id) async {
    try {
      // Get the title before removing
      final microtask = _microtasks.firstWhere((m) => m.id == id);
      final deletedTitle = microtask.judulTarget;

      _microtasks.removeWhere((m) => m.id == id);

      await _database.deleteMicrotask(id);

      debugPrint('🗑️ Deleted microtask: $id');

      // Notify deletion
      _onMicrotaskDeleted?.call(deletedTitle);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error deleting microtask: $e');
    }
  }

  Future<void> updateMicrotaskDetails(
    String id,
    String newTitle,
    String newDescription,
    List<MicroTaskItem> newItems,
  ) async {
    try {
      final index = _microtasks.indexWhere((m) => m.id == id);
      if (index != -1) {
        _microtasks[index] = _microtasks[index].copyWith(
          judulTarget: newTitle,
          deskripsi: newDescription,
          microtasks: newItems,
        );

        await _database.updateMicrotask(_microtasks[index]);
        debugPrint('✏️ Updated microtask: $id');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error updating microtask: $e');
    }
  }

  Future<void> generateMicrotasks(String prompt) async {
    if (_isGenerating) return;

    _isGenerating = true;
    notifyListeners();

    try {
      final microtask = await _geminiService.generateMicrotasks(prompt);

      if (microtask != null) {
        // Check if prompt is valid
        if (!microtask.isValid) {
          debugPrint('⚠️ Invalid prompt detected');
          _onInvalidPrompt?.call();
          _isGenerating = false;
          notifyListeners();
          return;
        }

        // Add to memory first for instant UI update
        _microtasks.add(microtask);

        // Re-sort the list
        _microtasks.sort((a, b) {
          const statusOrder = {'in-progress': 0, 'pending': 1, 'done': 2};
          final aOrder = statusOrder[a.status] ?? 3;
          final bOrder = statusOrder[b.status] ?? 3;
          return aOrder.compareTo(bOrder);
        });

        debugPrint('✅ Added new microtask to list: ${microtask.judulTarget}');

        // Update UI immediately
        _isGenerating = false;
        notifyListeners();

        // Then save to database in background (don't await)
        _database
            .insertMicrotask(microtask)
            .then((_) {
              debugPrint('💾 Saved microtask to database: ${microtask.id}');
            })
            .catchError((e) {
              debugPrint('❌ Error saving to database: $e');
            });

        return; // Exit early to avoid the finally block
      } else {
        debugPrint('❌ Failed to generate microtask');
      }
    } catch (e) {
      debugPrint('❌ Error in generateMicrotasks: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> startSession(MicroTaskModel microtask) async {
    if (_activeSession != null) return;

    final index = _microtasks.indexWhere((m) => m.id == microtask.id);
    if (index != -1) {
      _microtasks[index] = microtask.copyWith(status: 'in-progress');
      _activeSession = _microtasks[index];
      _currentMicrotaskIndex = 0;
      _elapsedTime = Duration.zero;
      _isPaused = false;
      _startTimer();

      // Save status to database
      await _database.updateMicrotask(_microtasks[index]);
      notifyListeners();
    }
  }

  void pauseSession() {
    _isPaused = !_isPaused;
    if (_isPaused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  void completeCurrentMicrotask() {
    if (_activeSession == null) return;

    final currentItem = _activeSession!.microtasks[_currentMicrotaskIndex];
    currentItem.isCompleted = true;

    _timer?.cancel();
    _isPaused = true;

    // Start rest timer
    _restTimeRemaining = currentItem.restTimeSeconds;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeRemaining! > 0) {
        _restTimeRemaining = _restTimeRemaining! - 1;
        notifyListeners();
      } else {
        _restTimer?.cancel();
        _restTimeRemaining = null;
        _moveToNextMicrotask();
      }
    });

    notifyListeners();
  }

  void _moveToNextMicrotask() {
    _currentMicrotaskIndex++;

    if (_currentMicrotaskIndex >= _activeSession!.microtasks.length) {
      _completeSession();
    } else {
      _isPaused = false;
      _startTimer();
      notifyListeners();
    }
  }

  Future<void> _completeSession() async {
    if (_activeSession == null) return;

    final completedTitle = _activeSession!.judulTarget;
    final index = _microtasks.indexWhere((m) => m.id == _activeSession!.id);
    if (index != -1) {
      _microtasks[index] = _activeSession!.copyWith(
        status: 'done',
        timeTaken: _elapsedTime,
      );

      // Save completion to database
      await _database.updateMicrotask(_microtasks[index]);
      debugPrint('💾 Saved completed session to database');
    }

    _timer?.cancel();
    _restTimer?.cancel();
    _activeSession = null;
    _currentMicrotaskIndex = 0;
    _elapsedTime = Duration.zero;
    _isPaused = false;
    _restTimeRemaining = null;

    // Notify completion
    _onMicrotaskCompleted?.call(completedTitle);

    notifyListeners();
  }

  Future<void> abandonSession() async {
    if (_activeSession == null) return;

    final index = _microtasks.indexWhere((m) => m.id == _activeSession!.id);
    if (index != -1) {
      _microtasks[index] = _activeSession!.copyWith(
        status: 'pending',
        timeTaken: Duration.zero,
      );

      // Reset completion status for all tasks
      for (var task in _microtasks[index].microtasks) {
        task.isCompleted = false;
      }

      // Save to database
      await _database.updateMicrotask(_microtasks[index]);
      debugPrint('🚫 Abandoned session: ${_activeSession!.judulTarget}');
    }

    _timer?.cancel();
    _restTimer?.cancel();
    _activeSession = null;
    _currentMicrotaskIndex = 0;
    _elapsedTime = Duration.zero;
    _isPaused = false;
    _restTimeRemaining = null;

    notifyListeners();
  }

  void skipRest() {
    if (_restTimeRemaining == null) return;

    _restTimer?.cancel();
    _restTimeRemaining = null;
    _moveToNextMicrotask();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}
