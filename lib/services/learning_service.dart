import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_history_log.dart';
import '../models/learning_summary.dart';

/// Pure business logic service for the Learning Engine.
///
/// Responsibilities:
///   - Persist & load daily history logs.
///   - Compute learning statistics (completion rates, planning accuracy, best working period, category averages, streaks).
///   - Generate fact-backed insights from actual historical logs.
class LearningService {
  static const String _historyKey = 'learning_history_logs';

  // ── Persistence ────────────────────────────────────────────────────────────

  static Future<List<DailyHistoryLog>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(DailyHistoryLog.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistory(List<DailyHistoryLog> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // ── Recording Methods ──────────────────────────────────────────────────────

  /// Records or updates a daily snapshot log.
  static Future<void> recordDailySnapshot(DailyHistoryLog snapshot) async {
    final history = await loadHistory();
    final idx = history.indexWhere((h) => h.date == snapshot.date);
    if (idx != -1) {
      history[idx] = snapshot;
    } else {
      history.add(snapshot);
    }
    await saveHistory(history);
  }

  /// Records a single mission execution into the log for [dateStr].
  static Future<void> recordMissionExecution({
    required String dateStr,
    required MissionExecutionLog missionLog,
  }) async {
    final history = await loadHistory();
    final idx = history.indexWhere((h) => h.date == dateStr);

    if (idx != -1) {
      final existing = history[idx];
      final updatedLogs = List<MissionExecutionLog>.from(existing.missionLogs)
        ..removeWhere((m) => m.missionId == missionLog.missionId)
        ..add(missionLog);

      final completedCount = updatedLogs
          .where((m) => m.status == 'completed')
          .length;
      final completedWorkload = updatedLogs
          .where((m) => m.status == 'completed')
          .fold<int>(0, (sum, m) => sum + m.durationMinutes);

      history[idx] = DailyHistoryLog(
        date: existing.date,
        plannedMissionsCount: existing.plannedMissionsCount,
        completedMissionsCount: completedCount,
        carryForwardCount: existing.carryForwardCount,
        totalEstimatedWorkloadMinutes: existing.totalEstimatedWorkloadMinutes,
        totalCompletedWorkloadMinutes: completedWorkload,
        actualCompletionTimeMinutes: completedWorkload,
        availableWorkingTimeMinutes: existing.availableWorkingTimeMinutes,
        missionLogs: updatedLogs,
        recoveryAccepted: existing.recoveryAccepted,
        recoveryDismissed: existing.recoveryDismissed,
      );
    } else {
      history.add(DailyHistoryLog(
        date: dateStr,
        plannedMissionsCount: 1,
        completedMissionsCount: missionLog.status == 'completed' ? 1 : 0,
        carryForwardCount: 0,
        totalEstimatedWorkloadMinutes: missionLog.estimatedMinutes,
        totalCompletedWorkloadMinutes:
            missionLog.status == 'completed' ? missionLog.durationMinutes : 0,
        actualCompletionTimeMinutes:
            missionLog.status == 'completed' ? missionLog.durationMinutes : 0,
        availableWorkingTimeMinutes: 360,
        missionLogs: [missionLog],
      ));
    }
    await saveHistory(history);
  }

  // ── Statistics Calculation ─────────────────────────────────────────────────

  /// Computes aggregated learning pattern statistics from historical logs.
  static LearningStatistics calculateStatistics(List<DailyHistoryLog> history) {
    if (history.isEmpty) return LearningStatistics.empty();

    // 1. Average Daily Completion Rate
    int validDays = 0;
    double totalRateSum = 0.0;
    for (final day in history) {
      if (day.plannedMissionsCount > 0) {
        validDays++;
        totalRateSum += (day.completedMissionsCount / day.plannedMissionsCount);
      }
    }
    final avgRate = validDays > 0 ? (totalRateSum / validDays) : 0.0;

    // 2. Average Planning Accuracy (actual - estimated)
    int diffSum = 0;
    int accuracyDays = 0;
    for (final day in history) {
      if (day.completedMissionsCount > 0) {
        diffSum += (day.actualCompletionTimeMinutes - day.totalEstimatedWorkloadMinutes);
        accuracyDays++;
      }
    }
    final avgAccuracy = accuracyDays > 0 ? (diffSum ~/ accuracyDays) : 0;

    // 3. Best Working Period
    final periodCounts = <String, int>{
      'morning': 0,
      'afternoon': 0,
      'evening': 0,
      'night': 0,
    };

    final catDurationSum = <String, int>{};
    final catDurationCount = <String, int>{};
    final catFreq = <String, Map<String, int>>{};

    int recoveryAccepted = 0;
    int recoveryDismissed = 0;

    for (final day in history) {
      if (day.recoveryAccepted) recoveryAccepted++;
      if (day.recoveryDismissed) recoveryDismissed++;

      for (final log in day.missionLogs) {
        // Time of day count
        if (log.status == 'completed') {
          final bucket = log.timeOfDayBucket.toLowerCase();
          periodCounts[bucket] = (periodCounts[bucket] ?? 0) + 1;
        }

        // Category durations
        final cat = log.categoryId.isNotEmpty ? log.categoryId : 'General';
        catDurationSum[cat] = (catDurationSum[cat] ?? 0) + log.durationMinutes;
        catDurationCount[cat] = (catDurationCount[cat] ?? 0) + 1;

        // Category frequency
        final freqMap = catFreq.putIfAbsent(cat, () => {'completed': 0, 'postponed': 0, 'abandoned': 0});
        final st = log.status.toLowerCase();
        if (freqMap.containsKey(st)) {
          freqMap[st] = freqMap[st]! + 1;
        }
      }
    }

    // Determine best working period
    String bestPeriodKey = 'morning';
    int maxPeriodCount = -1;
    periodCounts.forEach((period, count) {
      if (count > maxPeriodCount) {
        maxPeriodCount = count;
        bestPeriodKey = period;
      }
    });

    final bestWorkingPeriod = switch (bestPeriodKey) {
      'morning' => 'Morning',
      'afternoon' => 'Afternoon',
      'evening' => 'Evening',
      'night' => 'Night',
      _ => 'Morning',
    };

    // Category duration averages
    final avgCatDuration = <String, int>{};
    catDurationSum.forEach((cat, sum) {
      final count = catDurationCount[cat] ?? 1;
      avgCatDuration[cat] = count > 0 ? (sum ~/ count) : 0;
    });

    // 6. Longest Streak
    int currentRun = 0;
    int maxStreak = 0;
    for (final day in history) {
      if (day.completedMissionsCount > 0) {
        currentRun++;
        if (currentRun > maxStreak) maxStreak = currentRun;
      } else {
        currentRun = 0;
      }
    }

    return LearningStatistics(
      avgCompletionRate: avgRate,
      avgPlanningAccuracyMinutes: avgAccuracy,
      bestWorkingPeriod: bestWorkingPeriod,
      avgCategoryDurationMinutes: avgCatDuration,
      categoryFrequency: catFreq,
      longestStreakDays: maxStreak,
      longestPostponementDays: const {},
      totalRecoveryAccepted: recoveryAccepted,
      totalRecoveryDismissed: recoveryDismissed,
    );
  }

  // ── Insights Generation ────────────────────────────────────────────────────

  /// Generates fact-backed, deterministic insight strings from history logs.
  static List<String> generateInsights(
    List<DailyHistoryLog> history,
    LearningStatistics stats,
  ) {
    final insights = <String>[];

    if (history.isEmpty) {
      insights.add('Complete a few missions to start generating insights.');
      return insights;
    }

    // Insight 1: Best working period
    if (history.any((h) => h.completedMissionsCount > 0)) {
      insights.add(
        'You complete most missions during the ${stats.bestWorkingPeriod.toLowerCase()}.',
      );
    }

    // Insight 2: Planning accuracy
    if (stats.avgPlanningAccuracyMinutes != 0) {
      final diff = stats.avgPlanningAccuracyMinutes.abs();
      if (stats.avgPlanningAccuracyMinutes > 0) {
        insights.add(
          'Your actual execution time is usually ~${diff}m longer than estimated.',
        );
      } else {
        insights.add(
          'You complete missions ~${diff}m faster than estimated.',
        );
      }
    }

    // Insight 3: Category duration averages
    if (stats.avgCategoryDurationMinutes.isNotEmpty) {
      final entry = stats.avgCategoryDurationMinutes.entries.first;
      insights.add('${entry.key} sessions average ${entry.value} minutes.');
    }

    // Insight 4: Completion rate insight
    if (stats.avgCompletionRate > 0) {
      final pct = (stats.avgCompletionRate * 100).round();
      insights.add('Your average daily completion rate is $pct%.');
    }

    // Insight 5: Workload threshold pattern
    final lightDays = history.where((h) =>
        h.totalEstimatedWorkloadMinutes > 0 &&
        h.totalEstimatedWorkloadMinutes <= 360 &&
        h.completedMissionsCount > 0);
    if (lightDays.length >= 2) {
      insights.add(
        'You complete more missions on days planned with less than 6 hours.',
      );
    }

    return insights;
  }

  /// Builds a complete [LearningSummary].
  static LearningSummary buildSummary(List<DailyHistoryLog> history) {
    final stats = calculateStatistics(history);
    final insights = generateInsights(history, stats);
    return LearningSummary(
      statistics: stats,
      insights: insights,
    );
  }
}
