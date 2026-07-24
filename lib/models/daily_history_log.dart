/// Log of a single mission execution instance recorded by the Learning Engine.
class MissionExecutionLog {
  final String missionId;
  final String targetId;
  final String targetName;
  final String categoryId;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int estimatedMinutes;
  final int interruptions;
  final String status; // 'completed', 'postponed', 'abandoned'
  final String timeOfDayBucket; // 'morning', 'afternoon', 'evening', 'night'

  const MissionExecutionLog({
    required this.missionId,
    required this.targetId,
    required this.targetName,
    this.categoryId = 'general',
    this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.estimatedMinutes,
    this.interruptions = 0,
    this.status = 'completed',
    this.timeOfDayBucket = 'morning',
  });

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'targetId': targetId,
        'targetName': targetName,
        'categoryId': categoryId,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'estimatedMinutes': estimatedMinutes,
        'interruptions': interruptions,
        'status': status,
        'timeOfDayBucket': timeOfDayBucket,
      };

  factory MissionExecutionLog.fromJson(Map<String, dynamic> json) =>
      MissionExecutionLog(
        missionId: json['missionId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        targetName: json['targetName'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? 'general',
        startTime: json['startTime'] == null
            ? null
            : DateTime.tryParse(json['startTime'] as String),
        endTime: json['endTime'] == null
            ? null
            : DateTime.tryParse(json['endTime'] as String),
        durationMinutes: json['durationMinutes'] as int? ?? 0,
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
        interruptions: json['interruptions'] as int? ?? 0,
        status: json['status'] as String? ?? 'completed',
        timeOfDayBucket: json['timeOfDayBucket'] as String? ?? 'morning',
      );
}

/// Daily snapshot recorded by the Learning Engine.
class DailyHistoryLog {
  final String date; // "yyyy-MM-dd"
  final int plannedMissionsCount;
  final int completedMissionsCount;
  final int carryForwardCount;
  final int totalEstimatedWorkloadMinutes;
  final int totalCompletedWorkloadMinutes;
  final int actualCompletionTimeMinutes;
  final int availableWorkingTimeMinutes;
  final List<MissionExecutionLog> missionLogs;
  final bool recoveryAccepted;
  final bool recoveryDismissed;

  const DailyHistoryLog({
    required this.date,
    required this.plannedMissionsCount,
    required this.completedMissionsCount,
    required this.carryForwardCount,
    required this.totalEstimatedWorkloadMinutes,
    required this.totalCompletedWorkloadMinutes,
    required this.actualCompletionTimeMinutes,
    required this.availableWorkingTimeMinutes,
    this.missionLogs = const [],
    this.recoveryAccepted = false,
    this.recoveryDismissed = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'plannedMissionsCount': plannedMissionsCount,
        'completedMissionsCount': completedMissionsCount,
        'carryForwardCount': carryForwardCount,
        'totalEstimatedWorkloadMinutes': totalEstimatedWorkloadMinutes,
        'totalCompletedWorkloadMinutes': totalCompletedWorkloadMinutes,
        'actualCompletionTimeMinutes': actualCompletionTimeMinutes,
        'availableWorkingTimeMinutes': availableWorkingTimeMinutes,
        'missionLogs': missionLogs.map((m) => m.toJson()).toList(),
        'recoveryAccepted': recoveryAccepted,
        'recoveryDismissed': recoveryDismissed,
      };

  factory DailyHistoryLog.fromJson(Map<String, dynamic> json) => DailyHistoryLog(
        date: json['date'] as String,
        plannedMissionsCount: json['plannedMissionsCount'] as int? ?? 0,
        completedMissionsCount: json['completedMissionsCount'] as int? ?? 0,
        carryForwardCount: json['carryForwardCount'] as int? ?? 0,
        totalEstimatedWorkloadMinutes:
            json['totalEstimatedWorkloadMinutes'] as int? ?? 0,
        totalCompletedWorkloadMinutes:
            json['totalCompletedWorkloadMinutes'] as int? ?? 0,
        actualCompletionTimeMinutes:
            json['actualCompletionTimeMinutes'] as int? ?? 0,
        availableWorkingTimeMinutes:
            json['availableWorkingTimeMinutes'] as int? ?? 360,
        missionLogs: (json['missionLogs'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(MissionExecutionLog.fromJson)
            .toList(),
        recoveryAccepted: json['recoveryAccepted'] as bool? ?? false,
        recoveryDismissed: json['recoveryDismissed'] as bool? ?? false,
      );
}
