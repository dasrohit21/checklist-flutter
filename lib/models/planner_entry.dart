/// Status of a single entry in the daily planner.
enum PlannerEntryStatus { pending, inProgress, completed }

/// A mission slot in the daily planner.
///
/// Each entry references a [targetId] (the TargetItem being planned) and
/// optionally a live [missionId] once the mission is actually started.
class PlannerEntry {
  final String id;
  final String targetId;
  final String targetName;

  /// ISO date string — "yyyy-MM-dd"
  final String scheduledDate;

  final int estimatedDurationMinutes;
  final PlannerEntryStatus status;

  /// True when this entry was automatically moved from a previous day.
  final bool isCarryForward;

  const PlannerEntry({
    required this.id,
    required this.targetId,
    required this.targetName,
    required this.scheduledDate,
    required this.estimatedDurationMinutes,
    this.status = PlannerEntryStatus.pending,
    this.isCarryForward = false,
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetId': targetId,
        'targetName': targetName,
        'scheduledDate': scheduledDate,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'status': status.name,
        'isCarryForward': isCarryForward,
      };

  factory PlannerEntry.fromJson(Map<String, dynamic> json) => PlannerEntry(
        id: json['id'] as String,
        targetId: json['targetId'] as String,
        targetName: json['targetName'] as String? ?? '',
        scheduledDate: json['scheduledDate'] as String,
        estimatedDurationMinutes: json['estimatedDurationMinutes'] as int? ?? 60,
        status: PlannerEntryStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PlannerEntryStatus.pending,
        ),
        isCarryForward: json['isCarryForward'] as bool? ?? false,
      );

  // ── Mutation ───────────────────────────────────────────────────────────────

  PlannerEntry copyWith({
    String? targetName,
    String? scheduledDate,
    int? estimatedDurationMinutes,
    PlannerEntryStatus? status,
    bool? isCarryForward,
  }) {
    return PlannerEntry(
      id: id,
      targetId: targetId,
      targetName: targetName ?? this.targetName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      status: status ?? this.status,
      isCarryForward: isCarryForward ?? this.isCarryForward,
    );
  }
}
