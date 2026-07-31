class MissionSummary {
  final String targetId;
  final int totalMissionsCount;
  final int totalDurationSeconds;
  final double averageDurationMinutes;
  final int averageFocusScore;
  final double completionRate;
  final int totalProblemsSolved;
  final int totalChecklistCompleted;
  final DateTime? lastMissionDate;

  const MissionSummary({
    required this.targetId,
    this.totalMissionsCount = 0,
    this.totalDurationSeconds = 0,
    this.averageDurationMinutes = 0.0,
    this.averageFocusScore = 100,
    this.completionRate = 0.0,
    this.totalProblemsSolved = 0,
    this.totalChecklistCompleted = 0,
    this.lastMissionDate,
  });

  factory MissionSummary.fromJson(Map<String, dynamic> json) {
    return MissionSummary(
      targetId: json['targetId'] as String,
      totalMissionsCount: json['totalMissionsCount'] as int? ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
      averageDurationMinutes: (json['averageDurationMinutes'] as num?)?.toDouble() ?? 0.0,
      averageFocusScore: json['averageFocusScore'] as int? ?? 100,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      totalProblemsSolved: json['totalProblemsSolved'] as int? ?? 0,
      totalChecklistCompleted: json['totalChecklistCompleted'] as int? ?? 0,
      lastMissionDate: json['lastMissionDate'] == null ? null : DateTime.tryParse(json['lastMissionDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'totalMissionsCount': totalMissionsCount,
      'totalDurationSeconds': totalDurationSeconds,
      'averageDurationMinutes': averageDurationMinutes,
      'averageFocusScore': averageFocusScore,
      'completionRate': completionRate,
      'totalProblemsSolved': totalProblemsSolved,
      'totalChecklistCompleted': totalChecklistCompleted,
      'lastMissionDate': lastMissionDate?.toIso8601String(),
    };
  }
}
