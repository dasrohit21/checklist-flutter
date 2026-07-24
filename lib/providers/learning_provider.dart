import 'package:flutter/material.dart';

import '../models/daily_history_log.dart';
import '../models/learning_summary.dart';
import '../services/learning_service.dart';

/// State provider for the Learning Engine.
///
/// Responsibilities:
///   - Expose [dailyHistory], [insights], [statistics], and [summary].
///   - Record daily history snapshots & mission execution logs.
///   - Delegate all calculations & pattern analytics to [LearningService].
class LearningProvider extends ChangeNotifier {
  List<DailyHistoryLog> _dailyHistory = [];
  LearningSummary _summary = LearningSummary.empty();
  bool _isLoading = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<DailyHistoryLog> get dailyHistory => List.unmodifiable(_dailyHistory);
  List<String> get insights => List.unmodifiable(_summary.insights);
  LearningStatistics get statistics => _summary.statistics;
  LearningSummary get summary => _summary;
  bool get isLoading => _isLoading;

  // ── Initialization & Loading ───────────────────────────────────────────────

  /// Loads history logs and computes statistics & insights.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _dailyHistory = await LearningService.loadHistory();
    _summary = LearningService.buildSummary(_dailyHistory);

    _isLoading = false;
    notifyListeners();
  }

  // ── Recording Actions ──────────────────────────────────────────────────────

  /// Records a daily snapshot log and recomputes summary.
  Future<void> recordSnapshot(DailyHistoryLog snapshot) async {
    await LearningService.recordDailySnapshot(snapshot);
    await load();
  }

  /// Records a mission execution instance and recomputes summary.
  Future<void> recordMissionExecution({
    required String dateStr,
    required MissionExecutionLog missionLog,
  }) async {
    await LearningService.recordMissionExecution(
      dateStr: dateStr,
      missionLog: missionLog,
    );
    await load();
  }
}
