import '../models/mission_behavior_analysis.dart';
import '../models/mission_history_item.dart';
import '../models/mission_workspace_data.dart';
import '../models/target_item.dart';

/// Aggregated statistical summary calculated specifically for a single mission workspace.
class MissionWorkspaceStats {
  final int avgCompletionTimeMinutes;
  final int avgEstimationErrorMinutes;
  final int totalSessions;
  final double completionPercentage;
  final int recoveryCount;
  final int postponementCount;
  final int longestPauseMinutes;

  const MissionWorkspaceStats({
    required this.avgCompletionTimeMinutes,
    required this.avgEstimationErrorMinutes,
    required this.totalSessions,
    required this.completionPercentage,
    required this.recoveryCount,
    required this.postponementCount,
    required this.longestPauseMinutes,
  });
}

/// Independent service for computing per-mission statistics.
///
/// Reuses data from [BehaviorService] and [AppState.missionHistory]
/// without duplicating underlying calculations.
class MissionStatisticsService {
  static MissionWorkspaceStats computeStats({
    required TargetItem target,
    required List<MissionHistoryItem> missionHistory,
    required MissionBehaviorAnalysis? behaviorAnalysis,
    required MissionWorkspaceData workspaceData,
  }) {
    final relatedHistory =
        missionHistory.where((m) => m.name == target.title || m.id == target.id).toList();

    final sessionsFromHistory = relatedHistory.length;
    final totalSessions =
        sessionsFromHistory > workspaceData.totalSessions
            ? sessionsFromHistory
            : workspaceData.totalSessions;

    final completionPct = target.targetCount == 0
        ? 0.0
        : (target.solvedCount / target.targetCount).clamp(0.0, 1.0);

    final avgTime = behaviorAnalysis?.avgCompletionTimeMinutes ??
        (relatedHistory.isNotEmpty
            ? (relatedHistory.fold(0, (s, m) => s + m.durationSeconds ~/ 60) ~/
                relatedHistory.length)
            : 0);

    final avgError = behaviorAnalysis?.avgEstimationErrorMinutes ?? 0;
    final recoveryCount = behaviorAnalysis?.recoveriesCount ?? workspaceData.recoveryCount;
    final postponementCount =
        behaviorAnalysis?.postponementsCount ?? workspaceData.postponementCount;
    final longestPauseMinutes = workspaceData.longestPauseSeconds ~/ 60;

    return MissionWorkspaceStats(
      avgCompletionTimeMinutes: avgTime,
      avgEstimationErrorMinutes: avgError,
      totalSessions: totalSessions,
      completionPercentage: completionPct,
      recoveryCount: recoveryCount,
      postponementCount: postponementCount,
      longestPauseMinutes: longestPauseMinutes,
    );
  }
}
