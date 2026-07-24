import 'package:flutter/material.dart';

import '../models/behavior_summary.dart';
import '../models/daily_history_log.dart';
import '../models/mission_behavior_analysis.dart';
import '../models/planner_entry.dart';
import '../services/behavior_service.dart';

/// State provider for the Behavior Intelligence Engine.
///
/// Responsibilities:
///   - Expose [missionHealthMap], [behaviorInsights], [recommendations], and [summary].
///   - Trigger behavior pattern evaluation via [BehaviorService].
///   - Persist & restore behavior data.
class BehaviorProvider extends ChangeNotifier {
  BehaviorSummary _summary = BehaviorSummary.empty();
  bool _isLoading = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  Map<String, MissionBehaviorAnalysis> get missionHealthMap =>
      Map.unmodifiable(_summary.missionHealthMap);
  List<String> get behaviorInsights =>
      List.unmodifiable(_summary.behaviorInsights);
  List<String> get recommendations =>
      List.unmodifiable(_summary.recommendations);
  BehaviorSummary get summary => _summary;
  bool get isLoading => _isLoading;

  /// Gets [MissionBehaviorAnalysis] for a specific target ID.
  MissionBehaviorAnalysis? getHealthForTarget(String targetId) =>
      _summary.missionHealthMap[targetId];

  // ── Initialization & Loading ───────────────────────────────────────────────

  /// Loads persisted behavior summary from storage.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _summary = await BehaviorService.loadSummary();

    _isLoading = false;
    notifyListeners();
  }

  // ── Evaluation Action ──────────────────────────────────────────────────────

  /// Evaluates behavior patterns and updates the behavior summary.
  Future<void> evaluate({
    required List<DailyHistoryLog> history,
    required List<PlannerEntry> todayEntries,
    required List<PlannerEntry> tomorrowEntries,
  }) async {
    final newSummary = BehaviorService.analyzeBehavior(
      history: history,
      todayEntries: todayEntries,
      tomorrowEntries: tomorrowEntries,
    );

    _summary = newSummary;
    await BehaviorService.saveSummary(newSummary);
    notifyListeners();
  }
}
