import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Event type for chronological mission lifecycle history.
enum MissionTimelineEventType {
  created,
  started,
  paused,
  resumed,
  recoveryApplied,
  completed,
  archived,
  stepUpdated,
}

extension MissionTimelineEventTypeExt on MissionTimelineEventType {
  String get displayName => switch (this) {
        MissionTimelineEventType.created => 'Mission Created',
        MissionTimelineEventType.started => 'Mission Started',
        MissionTimelineEventType.paused => 'Mission Paused',
        MissionTimelineEventType.resumed => 'Mission Resumed',
        MissionTimelineEventType.recoveryApplied => 'Recovery Plan Applied',
        MissionTimelineEventType.completed => 'Mission Completed',
        MissionTimelineEventType.archived => 'Mission Archived',
        MissionTimelineEventType.stepUpdated => 'Step Updated',
      };

  IconData get icon => switch (this) {
        MissionTimelineEventType.created => Icons.add_circle_outline_rounded,
        MissionTimelineEventType.started => Icons.play_arrow_rounded,
        MissionTimelineEventType.paused => Icons.pause_rounded,
        MissionTimelineEventType.resumed => Icons.play_arrow_rounded,
        MissionTimelineEventType.recoveryApplied => Icons.build_circle_rounded,
        MissionTimelineEventType.completed => Icons.check_circle_rounded,
        MissionTimelineEventType.archived => Icons.archive_rounded,
        MissionTimelineEventType.stepUpdated => Icons.checklist_rounded,
      };

  Color get color => switch (this) {
        MissionTimelineEventType.created => AppTheme.accent,
        MissionTimelineEventType.started => AppTheme.success,
        MissionTimelineEventType.paused => AppTheme.warning,
        MissionTimelineEventType.resumed => AppTheme.accent,
        MissionTimelineEventType.recoveryApplied => AppTheme.feature,
        MissionTimelineEventType.completed => AppTheme.success,
        MissionTimelineEventType.archived => AppTheme.textMuted,
        MissionTimelineEventType.stepUpdated => AppTheme.accent,
      };
}

/// A single read-only chronological timeline entry recorded for a mission.
class MissionTimelineEvent {
  final String id;
  final String targetId;
  final MissionTimelineEventType type;
  final DateTime timestamp;
  final String description;

  const MissionTimelineEvent({
    required this.id,
    required this.targetId,
    required this.type,
    required this.timestamp,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetId': targetId,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
      };

  factory MissionTimelineEvent.fromJson(Map<String, dynamic> json) =>
      MissionTimelineEvent(
        id: json['id'] as String,
        targetId: json['targetId'] as String? ?? '',
        type: MissionTimelineEventType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MissionTimelineEventType.created,
        ),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        description: json['description'] as String? ?? '',
      );
}
