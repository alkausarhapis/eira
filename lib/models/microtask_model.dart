class MicroTaskModel {
  final String id;
  final String judulTarget;
  final String deskripsi;
  final List<MicroTaskItem> microtasks;
  final String status;
  final Duration timeTaken;
  final String emoji;
  final bool isValid;

  MicroTaskModel({
    required this.id,
    required this.judulTarget,
    required this.deskripsi,
    required this.microtasks,
    required this.status,
    required this.timeTaken,
    required this.emoji,
    this.isValid = true,
  });

  MicroTaskModel copyWith({
    String? id,
    String? judulTarget,
    String? deskripsi,
    List<MicroTaskItem>? microtasks,
    String? status,
    Duration? timeTaken,
    String? emoji,
    bool? isValid,
  }) {
    return MicroTaskModel(
      id: id ?? this.id,
      judulTarget: judulTarget ?? this.judulTarget,
      deskripsi: deskripsi ?? this.deskripsi,
      microtasks: microtasks ?? this.microtasks,
      status: status ?? this.status,
      timeTaken: timeTaken ?? this.timeTaken,
      emoji: emoji ?? this.emoji,
      isValid: isValid ?? this.isValid,
    );
  }
}

class MicroTaskItem {
  final String task;
  final int restTimeSeconds;
  bool isCompleted;

  MicroTaskItem({
    required this.task,
    required this.restTimeSeconds,
    this.isCompleted = false,
  });

  MicroTaskItem copyWith({
    String? task,
    int? restTimeSeconds,
    bool? isCompleted,
  }) {
    return MicroTaskItem(
      task: task ?? this.task,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
