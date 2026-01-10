class InstalledAppModel {
  final String packageName;
  final String appName;
  final int totalTimeMillis;
  List<int>? iconBytes;

  InstalledAppModel({
    required this.packageName,
    required this.appName,
    required this.totalTimeMillis,
    this.iconBytes,
  });

  factory InstalledAppModel.fromMap(Map<dynamic, dynamic> map) {
    return InstalledAppModel(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      totalTimeMillis: (map['totalTimeMillis'] as num).toInt(),
    );
  }

  String get formattedTime {
    if (totalTimeMillis == 0) return '0m';

    final hours = totalTimeMillis ~/ (1000 * 60 * 60);
    final minutes = (totalTimeMillis % (1000 * 60 * 60)) ~/ (1000 * 60);

    if (hours > 0) {
      return '${hours}j ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class BlockedAppModel {
  final String packageName;
  final String appName;
  final int blockedUntil;
  final String? blockReason;
  final int timeSpentSnapshot;
  final bool isBlocked;
  final int blockDurationMillis;

  BlockedAppModel({
    required this.packageName,
    required this.appName,
    required this.blockedUntil,
    this.blockReason,
    required this.timeSpentSnapshot,
    required this.isBlocked,
    required this.blockDurationMillis,
  });

  factory BlockedAppModel.fromMap(Map<dynamic, dynamic> map) {
    return BlockedAppModel(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      blockedUntil: (map['blockedUntil'] as num).toInt(),
      blockReason: map['blockReason'] as String?,
      timeSpentSnapshot: (map['timeSpentSnapshot'] as num).toInt(),
      isBlocked: map['isBlocked'] as bool,
      blockDurationMillis: (map['blockDurationMillis'] as num).toInt(),
    );
  }

  Duration get remainingTime {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = blockedUntil - now;
    return remaining > 0 ? Duration(milliseconds: remaining) : Duration.zero;
  }

  bool get isActive {
    return isBlocked && DateTime.now().millisecondsSinceEpoch < blockedUntil;
  }
}
