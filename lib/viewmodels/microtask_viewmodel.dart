import 'dart:async';

import 'package:flutter/material.dart';

import '../models/microtask_model.dart';

class MicrotaskViewModel extends ChangeNotifier {
  List<MicroTaskModel> _microtasks = [];
  MicroTaskModel? _activeSession;
  int _currentMicrotaskIndex = 0;
  Duration _elapsedTime = Duration.zero;
  bool _isPaused = false;
  Timer? _timer;
  int? _restTimeRemaining;
  Timer? _restTimer;

  List<MicroTaskModel> get microtasks => _microtasks;
  MicroTaskModel? get activeSession => _activeSession;
  int get currentMicrotaskIndex => _currentMicrotaskIndex;
  Duration get elapsedTime => _elapsedTime;
  bool get isPaused => _isPaused;
  int? get restTimeRemaining => _restTimeRemaining;

  String? get currentTaskText {
    if (_activeSession == null) return null;
    if (_currentMicrotaskIndex >= _activeSession!.microtasks.length) {
      return null;
    }
    return _activeSession!.microtasks[_currentMicrotaskIndex].task;
  }

  bool get hasActiveSession =>
      _activeSession != null && _restTimeRemaining == null;

  void addMicrotask(MicroTaskModel microtask) {
    _microtasks.add(microtask);
    notifyListeners();
  }

  void generateMicrotasks(String prompt) {
    // Mock generation - in real app this would call AI API
    final mockTasks = [
      MicroTaskModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        judulTarget: 'Belajar Flutter',
        deskripsi: 'Target: $prompt',
        emoji: '📱',
        status: 'pending',
        timeTaken: Duration.zero,
        microtasks: [
          MicroTaskItem(
            task: 'Baca dokumentasi Flutter selama 10 menit',
            restTimeSeconds: 30,
          ),
          MicroTaskItem(task: 'Buat widget sederhana', restTimeSeconds: 45),
          MicroTaskItem(task: 'Coba hot reload', restTimeSeconds: 30),
        ],
      ),
    ];

    _microtasks.addAll(mockTasks);
    notifyListeners();
  }

  void startSession(MicroTaskModel microtask) {
    if (_activeSession != null) return;

    final index = _microtasks.indexWhere((m) => m.id == microtask.id);
    if (index != -1) {
      _microtasks[index] = microtask.copyWith(status: 'in-progress');
      _activeSession = _microtasks[index];
      _currentMicrotaskIndex = 0;
      _elapsedTime = Duration.zero;
      _isPaused = false;
      _startTimer();
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

  void _completeSession() {
    if (_activeSession == null) return;

    final index = _microtasks.indexWhere((m) => m.id == _activeSession!.id);
    if (index != -1) {
      _microtasks[index] = _activeSession!.copyWith(
        status: 'done',
        timeTaken: _elapsedTime,
      );
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
