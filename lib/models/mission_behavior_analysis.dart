import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Health score rating for a mission.
enum MissionHealthStatus {
  /// Completion >= 80%, low postponements, recent activity.
  excellent,

  /// Completion >= 60%, moderate postponements.
  good,

  /// Completion >= 35%, or 3+ postponements.
  warning,

  /// Completion < 35%, or 5+ postponements / long inactivity.
  critical,
}

extension MissionHealthStatusExt on MissionHealthStatus {
  String get displayName => switch (this) {
        MissionHealthStatus.excellent => 'Excellent',
        MissionHealthStatus.good => 'Good',
        MissionHealthStatus.warning => 'Warning',
        MissionHealthStatus.critical => 'Critical',
      };

  Color get color => switch (this) {
        MissionHealthStatus.excellent => AppTheme.success,
        MissionHealthStatus.good => AppTheme.accent,
        MissionHealthStatus.warning => AppTheme.warning,
        MissionHealthStatus.critical => AppTheme.danger,
      };

  IconData get icon => switch (this) {
        MissionHealthStatus.excellent => Icons.verified_rounded,
        MissionHealthStatus.good => Icons.thumb_up_alt_rounded,
        MissionHealthStatus.warning => Icons.warning_amber_rounded,
        MissionHealthStatus.critical => Icons.error_outline_rounded,
      };
}

/// Behavior analysis metrics recorded for a specific mission target.
class MissionBehaviorAnalysis {
  final String targetId;
  final String targetName;
  final String categoryId;
  final int completionsCount;
  final int postponementsCount;
  final int recoveriesCount;
  final int avgCompletionTimeMinutes;
  final int avgEstimationErrorMinutes; // actual - estimated
  final DateTime? lastCompletedDate;
  final DateTime? lastPostponedDate;
  final double completionPercentage;
  final MissionHealthStatus healthStatus;

  const MissionBehaviorAnalysis({
    required this.targetId,
    required this.targetName,
    this.categoryId = 'general',
    required this.completionsCount,
    required this.postponementsCount,
    required this.recoveriesCount,
    required this.avgCompletionTimeMinutes,
    required this.avgEstimationErrorMinutes,
    this.lastCompletedDate,
    this.lastPostponedDate,
    required this.completionPercentage,
    required this.healthStatus,
  });

  Map<String, dynamic> toJson() => {
        'targetId': targetId,
        'targetName': targetName,
        'categoryId': categoryId,
        'completionsCount': completionsCount,
        'postponementsCount': postponementsCount,
        'recoveriesCount': recoveriesCount,
        'avgCompletionTimeMinutes': avgCompletionTimeMinutes,
        'avgEstimationErrorMinutes': avgEstimationErrorMinutes,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
        'lastPostponedDate': lastPostponedDate?.toIso8601String(),
        'completionPercentage': completionPercentage,
        'healthStatus': healthStatus.name,
      };

  factory MissionBehaviorAnalysis.fromJson(Map<String, dynamic> json) =>
      MissionBehaviorAnalysis(
        targetId: json['targetId'] as String? ?? '',
        targetName: json['targetName'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? 'general',
        completionsCount: json['completionsCount'] as int? ?? 0,
        postponementsCount: json['postponementsCount'] as int? ?? 0,
        recoveriesCount: json['recoveriesCount'] as int? ?? 0,
        avgCompletionTimeMinutes:
            json['avgCompletionTimeMinutes'] as int? ?? 0,
        avgEstimationErrorMinutes:
            json['avgEstimationErrorMinutes'] as int? ?? 0,
        lastCompletedDate: json['lastCompletedDate'] == null
            ? null
            : DateTime.tryParse(json['lastCompletedDate'] as String),
        lastPostponedDate: json['lastPostponedDate'] == null
            ? null
            : DateTime.tryParse(json['lastPostponedDate'] as String),
        completionPercentage:
            (json['completionPercentage'] as num? ?? 0.0).toDouble(),
        healthStatus: MissionHealthStatus.values.firstWhere(
          (e) => e.name == json['healthStatus'],
          orElse: () => MissionHealthStatus.good,
        ),
      );
}
