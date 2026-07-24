import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/behavior_summary.dart';
import '../models/daily_history_log.dart';
import '../models/mission_behavior_analysis.dart';
import '../models/planner_entry.dart';

/// Central intelligence service for the Behavior Intelligence Engine.
///
/// Responsibilities:
///   - Compute deterministic [MissionHealthStatus] ratings.
///   - Analyze historical logs & planner entries to detect behavior patterns.
///   - Generate evidence-backed behavior insights and recommendations.
///   - Persist behavior summaries to SharedPreferences.
class BehaviorService {
  static const String _summaryKey = 'behavior_summary_data';

  // ── Persistence ────────────────────────────────────────────────────────────

  static Future<BehaviorSummary> loadSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_summaryKey);
    if (raw == null) return BehaviorSummary.empty();
    try {
      return BehaviorSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return BehaviorSummary.empty();
    }
  }

  static Future<void> saveSummary(BehaviorSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryKey, jsonEncode(summary.toJson()));
  }

  // ── Mission Health Calculation ─────────────────────────────────────────────

  /// Calculates a deterministic [MissionHealthStatus] rating.
  static MissionHealthStatus calculateMissionHealth({
    required double completionPercentage,
    required int postponementsCount,
    required int daysSinceActivity,
    required int recoveriesCount,
  }) {
    if (completionPercentage < 0.35 ||
        postponementsCount >= 5 ||
        daysSinceActivity >= 7) {
      return MissionHealthStatus.critical;
    }
    if (completionPercentage < 0.60 || postponementsCount >= 3) {
      return MissionHealthStatus.warning;
    }
    if (completionPercentage >= 0.80 &&
        postponementsCount <= 1 &&
        daysSinceActivity <= 3) {
      return MissionHealthStatus.excellent;
    }
    return MissionHealthStatus.good;
  }

  // ── Behavior Pattern Analysis ──────────────────────────────────────────────

  /// Analyzes execution history and planner entries to build [BehaviorSummary].
  static BehaviorSummary analyzeBehavior({
    required List<DailyHistoryLog> history,
    required List<PlannerEntry> todayEntries,
    required List<PlannerEntry> tomorrowEntries,
  }) {
    final targetStats = <String, _TargetAccumulator>{};
    final now = DateTime.now();

    // 1. Gather stats from daily history logs
    for (final day in history) {
      final logDate = DateTime.tryParse(day.date) ?? now;
      for (final m in day.missionLogs) {
        if (m.targetId.isEmpty) continue;
        final acc = targetStats.putIfAbsent(
          m.targetId,
          () => _TargetAccumulator(targetId: m.targetId, targetName: m.targetName, categoryId: m.categoryId),
        );

        if (m.status == 'completed') {
          acc.completions++;
          acc.totalDuration += m.durationMinutes;
          acc.totalEstimated += m.estimatedMinutes;
          if (acc.lastCompleted == null || logDate.isAfter(acc.lastCompleted!)) {
            acc.lastCompleted = logDate;
          }
        } else if (m.status == 'postponed') {
          acc.postponements++;
          if (acc.lastPostponed == null || logDate.isAfter(acc.lastPostponed!)) {
            acc.lastPostponed = logDate;
          }
        }
      }
    }

    // 2. Gather stats from today's & tomorrow's planner entries
    for (final entry in [...todayEntries, ...tomorrowEntries]) {
      if (entry.targetId.isEmpty) continue;
      final acc = targetStats.putIfAbsent(
        entry.targetId,
        () => _TargetAccumulator(
            targetId: entry.targetId, targetName: entry.targetName),
      );

      if (entry.isCarryForward) {
        acc.postponements++;
      }
      if (entry.status == PlannerEntryStatus.completed) {
        acc.completions++;
        acc.totalDuration += entry.estimatedDurationMinutes;
        acc.totalEstimated += entry.estimatedDurationMinutes;
        acc.lastCompleted = now;
      }
    }

    // 3. Build MissionBehaviorAnalysis for each target
    final healthMap = <String, MissionBehaviorAnalysis>{};
    final insights = <String>[];
    final recommendations = <String>[];

    targetStats.forEach((targetId, acc) {
      final totalAttempts = acc.completions + acc.postponements;
      final completionPct = totalAttempts > 0 ? (acc.completions / totalAttempts) : 1.0;
      final avgDuration = acc.completions > 0 ? (acc.totalDuration ~/ acc.completions) : 30;
      final avgError = acc.completions > 0 ? ((acc.totalDuration - acc.totalEstimated) ~/ acc.completions) : 0;

      final lastActive = acc.lastCompleted ?? acc.lastPostponed ?? now;
      final daysSinceActive = now.difference(lastActive).inDays;

      final health = calculateMissionHealth(
        completionPercentage: completionPct,
        postponementsCount: acc.postponements,
        daysSinceActivity: daysSinceActive,
        recoveriesCount: acc.recoveries,
      );

      final analysis = MissionBehaviorAnalysis(
        targetId: targetId,
        targetName: acc.targetName,
        categoryId: acc.categoryId,
        completionsCount: acc.completions,
        postponementsCount: acc.postponements,
        recoveriesCount: acc.recoveries,
        avgCompletionTimeMinutes: avgDuration,
        avgEstimationErrorMinutes: avgError,
        lastCompletedDate: acc.lastCompleted,
        lastPostponedDate: acc.lastPostponed,
        completionPercentage: completionPct,
        healthStatus: health,
      );

      healthMap[targetId] = analysis;

      // 4. Generate Behavior Insights based on evidence
      if (acc.postponements >= 3) {
        insights.add('"${acc.targetName}" has been postponed ${acc.postponements} times recently.');
      } else if (acc.completions >= 4 && completionPct >= 0.85) {
        final pct = (completionPct * 100).round();
        insights.add('"${acc.targetName}" is completed $pct% of the time.');
      }

      if (avgError > 15 && acc.completions >= 2) {
        insights.add('"${acc.targetName}" estimates are consistently $avgError min shorter than reality.');
      }

      // 5. Generate Evidence-Based Recommendations
      if (acc.postponements >= 2) {
        recommendations.add('"${acc.targetName}" is frequently postponed. Consider making it tomorrow\'s first mission.');
      } else if (avgError > 20) {
        recommendations.add('Consider increasing the estimated duration for "${acc.targetName}" by $avgError minutes.');
      }
    });

    return BehaviorSummary(
      missionHealthMap: healthMap,
      behaviorInsights: insights,
      recommendations: recommendations,
      lastAnalyzed: now,
    );
  }
}

class _TargetAccumulator {
  final String targetId;
  final String targetName;
  final String categoryId;
  int completions = 0;
  int postponements = 0;
  int recoveries = 0;
  int totalDuration = 0;
  int totalEstimated = 0;
  DateTime? lastCompleted;
  DateTime? lastPostponed;

  _TargetAccumulator({
    required this.targetId,
    required this.targetName,
    this.categoryId = 'general',
  });
}
