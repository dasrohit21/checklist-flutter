import 'package:flutter/material.dart';

import '../models/mission_context.dart';
import '../models/planner_entry.dart';
import '../models/planning_summary.dart';
import '../services/planner_service.dart';

/// State provider for the Execution Planner feature.
///
/// Responsibilities:
///   - Load today's planner data (triggering carry-forward first).
///   - Expose computed planning analysis (workload, status, summary).
///   - Refresh the UI after mutations.
///   - Delegate all business logic to [PlannerService].
class PlannerProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────

  List<PlannerEntry> _todayEntries = [];
  List<PlannerEntry> _carryForwardEntries = [];
  List<PlannerEntry> _tomorrowEntries = [];
  int _availableMinutes = PlannerService.defaultAvailableMinutes;
  bool _isLoading = false;

  // ── Getters: lists ─────────────────────────────────────────────────────────

  /// All entries planned for today that are NOT carry-forwards.
  List<PlannerEntry> get todayEntries =>
      List.unmodifiable(_todayEntries.where((e) => !e.isCarryForward));

  /// Entries that were automatically moved from a previous day.
  List<PlannerEntry> get carryForwardEntries =>
      List.unmodifiable(_carryForwardEntries);

  /// Read-only preview of tomorrow's plan.
  List<PlannerEntry> get tomorrowEntries =>
      List.unmodifiable(_tomorrowEntries);

  bool get isLoading => _isLoading;

  // ── Getters: planning analysis (computed, no extra storage) ────────────────

  /// User's configured available daily time in minutes.
  int get availableMinutes => _availableMinutes;

  /// Total estimated minutes for all non-completed entries today.
  int get dailyWorkloadMinutes =>
      PlannerService.calculateDailyWorkload(_todayEntries);

  /// Status comparing today's workload against available time.
  PlannerStatus get plannerStatus => PlannerService.calculatePlannerStatus(
        dailyWorkloadMinutes,
        _availableMinutes,
      );

  /// True when today's plan exceeds available time.
  bool get isOverplanned => plannerStatus == PlannerStatus.overloaded;

  /// Aggregated summary of today's plan.
  PlanningSummary get planningSummary => PlanningSummary(
        totalMissions: _todayEntries.length,
        totalMinutes: dailyWorkloadMinutes,
        carryForwardCount: _carryForwardEntries.length,
        status: plannerStatus,
      );

  // ── Public API: loading ────────────────────────────────────────────────────

  /// Loads all planner data.
  ///
  /// Runs carry-forward first (idempotent), then fetches today's, tomorrow's
  /// entries, and the user's available-time setting. Called once at startup.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    await PlannerService.performCarryForward();
    await _reloadAll();

    _isLoading = false;
    notifyListeners();
  }

  /// Refreshes planner data without showing the loading state.
  Future<void> refresh() async {
    await _reloadAll();
    notifyListeners();
  }

  // ── Public API: mutations ──────────────────────────────────────────────────

  /// Adds a new entry to today's plan and refreshes.
  Future<void> addEntry(PlannerEntry entry) async {
    await PlannerService.addTodayEntry(entry);
    await _reloadAll();
    notifyListeners();
  }

  /// Removes an entry from today's plan and refreshes.
  Future<void> removeEntry(String entryId) async {
    await PlannerService.removeTodayEntry(entryId);
    await _reloadAll();
    notifyListeners();
  }

  /// Updates the status of a single entry and refreshes.
  Future<void> updateEntryStatus(
    String entryId,
    PlannerEntryStatus newStatus,
  ) async {
    await PlannerService.updateEntryStatus(entryId, newStatus);
    await _reloadAll();
    notifyListeners();
  }

  /// Moves an entry from today to tomorrow and refreshes.
  ///
  /// The moved entry becomes a regular planned entry for tomorrow
  /// (not a carry-forward). Carry-forward logic is unaffected.
  Future<void> moveMissionToTomorrow(String entryId) async {
    await PlannerService.moveMissionToTomorrow(entryId);
    await _reloadAll();
    notifyListeners();
  }

  /// Saves the user's available daily time and refreshes analysis.
  Future<void> setAvailableMinutes(int minutes) async {
    await PlannerService.saveAvailableMinutes(minutes);
    _availableMinutes = minutes;
    notifyListeners();
  }

  /// Saves a mission context snapshot for a target.
  Future<void> saveMissionContext(MissionContext ctx) async {
    await PlannerService.saveMissionContext(ctx);
    // No UI refresh needed — context is loaded on-demand per card.
  }

  /// Loads the mission context for a specific target.
  Future<MissionContext?> getMissionContext(String targetId) {
    return PlannerService.loadMissionContext(targetId);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _reloadAll() async {
    final all = await PlannerService.loadTodayEntries();
    _todayEntries = all;
    _carryForwardEntries = all.where((e) => e.isCarryForward).toList();
    _tomorrowEntries = await PlannerService.loadTomorrowEntries();
    _availableMinutes = await PlannerService.loadAvailableMinutes();
  }
}
