enum MissionType { normal, strict, ultimate }

enum MissionStatus { active, completed }

const Object _unchanged = Object();

class Mission {
  final String id;
  final String targetId;
  final String name;
  final int targetCount;
  final int startSolvedCount;
  final int solvedCount;
  final DateTime startTime;
  final DateTime? endTime;
  final int estimatedDurationMinutes;
  final MissionType type;
  final MissionStatus status;
  final bool isPaused;
  final int accumulatedSeconds;
  final DateTime? lastResumeTime;
  final int interruptionCount;

  Mission({
    required this.id,
    required this.targetId,
    required this.name,
    required this.targetCount,
    required this.startSolvedCount,
    required this.solvedCount,
    required this.startTime,
    this.endTime,
    required this.estimatedDurationMinutes,
    required this.type,
    required this.status,
    this.isPaused = false,
    this.accumulatedSeconds = 0,
    this.lastResumeTime,
    this.interruptionCount = 0,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      name: json['name'] as String,
      targetCount: json['targetCount'] as int,
      startSolvedCount: json['startSolvedCount'] as int,
      solvedCount: json['solvedCount'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null ? null : DateTime.parse(json['endTime'] as String),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
      type: MissionType.values.firstWhere((e) => e.name == json['type'] as String),
      status: MissionStatus.values.firstWhere((e) => e.name == json['status'] as String),
      isPaused: json['isPaused'] as bool? ?? false,
      accumulatedSeconds: json['accumulatedSeconds'] as int? ?? 0,
      lastResumeTime: json['lastResumeTime'] == null ? null : DateTime.parse(json['lastResumeTime'] as String),
      interruptionCount: json['interruptionCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'name': name,
      'targetCount': targetCount,
      'startSolvedCount': startSolvedCount,
      'solvedCount': solvedCount,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'type': type.name,
      'status': status.name,
      'isPaused': isPaused,
      'accumulatedSeconds': accumulatedSeconds,
      'lastResumeTime': lastResumeTime?.toIso8601String(),
      'interruptionCount': interruptionCount,
    };
  }

  Mission copyWith({
    String? name,
    int? solvedCount,
    DateTime? endTime,
    MissionStatus? status,
    bool? isPaused,
    int? accumulatedSeconds,
    Object? lastResumeTime = _unchanged,
    int? interruptionCount,
  }) {
    return Mission(
      id: id,
      targetId: targetId,
      name: name ?? this.name,
      targetCount: targetCount,
      startSolvedCount: startSolvedCount,
      solvedCount: solvedCount ?? this.solvedCount,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      estimatedDurationMinutes: estimatedDurationMinutes,
      type: type,
      status: status ?? this.status,
      isPaused: isPaused ?? this.isPaused,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      lastResumeTime: lastResumeTime == _unchanged ? this.lastResumeTime : lastResumeTime as DateTime?,
      interruptionCount: interruptionCount ?? this.interruptionCount,
    );
  }
}

class MissionStatistics {
  final int totalMissionsStarted;
  final int totalMissionsCompleted;
  final int totalDurationSeconds;

  MissionStatistics({
    required this.totalMissionsStarted,
    required this.totalMissionsCompleted,
    required this.totalDurationSeconds,
  });

  factory MissionStatistics.fromJson(Map<String, dynamic> json) {
    return MissionStatistics(
      totalMissionsStarted: json['totalMissionsStarted'] as int? ?? 0,
      totalMissionsCompleted: json['totalMissionsCompleted'] as int? ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMissionsStarted': totalMissionsStarted,
      'totalMissionsCompleted': totalMissionsCompleted,
      'totalDurationSeconds': totalDurationSeconds,
    };
  }

  MissionStatistics copyWith({
    int? totalMissionsStarted,
    int? totalMissionsCompleted,
    int? totalDurationSeconds,
  }) {
    return MissionStatistics(
      totalMissionsStarted: totalMissionsStarted ?? this.totalMissionsStarted,
      totalMissionsCompleted: totalMissionsCompleted ?? this.totalMissionsCompleted,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
    );
  }
}
