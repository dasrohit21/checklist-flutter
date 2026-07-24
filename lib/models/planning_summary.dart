/// Workload status for a day's plan.
///
/// Used by [PlanningSummary] and exposed through [PlannerProvider].
/// Future versions (Coach, Recovery Engine) may read this to decide actions.
enum PlannerStatus {
  /// Workload fits comfortably within available time (≤ 85%).
  onTrack,

  /// Workload is close to the available limit (85 % < workload ≤ 100 %).
  nearLimit,

  /// Workload exceeds available time (> 100 %).
  overloaded,
}

/// Immutable snapshot of a day's planning state.
///
/// Computed on-demand by [PlannerProvider]; not stored in SharedPreferences
/// (it is derived from the entry list + available time).
class PlanningSummary {
  /// Total missions scheduled for today (regular + carry-forward).
  final int totalMissions;

  /// Sum of [PlannerEntry.estimatedDurationMinutes] for non-completed entries.
  final int totalMinutes;

  /// Number of entries that were automatically moved from a previous day.
  final int carryForwardCount;

  /// Comparison result of workload vs available time.
  final PlannerStatus status;

  const PlanningSummary({
    required this.totalMissions,
    required this.totalMinutes,
    required this.carryForwardCount,
    required this.status,
  });

  /// Convenience: total workload formatted as "Xh Ym" or "Ym".
  String get formattedDuration {
    if (totalMinutes == 0) return '0m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// True when the plan has more work than available time.
  bool get isOverplanned => status == PlannerStatus.overloaded;
}
