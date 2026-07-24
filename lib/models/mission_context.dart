/// Lightweight memory of the last time a target was worked on.
///
/// Keyed by [targetId], this context survives app restarts and drives the
/// "Continue Mission" UX on the Planner screen.
class MissionContext {
  final String targetId;
  final DateTime lastOpenedTime;

  /// Progress as a fraction 0.0–1.0.
  final double progress;

  /// Estimated minutes remaining at the time of the last session.
  final int estimatedRemainingMinutes;

  /// Optional free-text note from the last session.
  final String? lastNote;

  const MissionContext({
    required this.targetId,
    required this.lastOpenedTime,
    required this.progress,
    required this.estimatedRemainingMinutes,
    this.lastNote,
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'targetId': targetId,
        'lastOpenedTime': lastOpenedTime.toIso8601String(),
        'progress': progress,
        'estimatedRemainingMinutes': estimatedRemainingMinutes,
        'lastNote': lastNote,
      };

  factory MissionContext.fromJson(Map<String, dynamic> json) => MissionContext(
        targetId: json['targetId'] as String,
        lastOpenedTime:
            DateTime.parse(json['lastOpenedTime'] as String),
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        estimatedRemainingMinutes:
            json['estimatedRemainingMinutes'] as int? ?? 0,
        lastNote: json['lastNote'] as String?,
      );

  // ── Mutation ───────────────────────────────────────────────────────────────

  MissionContext copyWith({
    DateTime? lastOpenedTime,
    double? progress,
    int? estimatedRemainingMinutes,
    String? lastNote,
  }) {
    return MissionContext(
      targetId: targetId,
      lastOpenedTime: lastOpenedTime ?? this.lastOpenedTime,
      progress: progress ?? this.progress,
      estimatedRemainingMinutes:
          estimatedRemainingMinutes ?? this.estimatedRemainingMinutes,
      lastNote: lastNote ?? this.lastNote,
    );
  }
}
