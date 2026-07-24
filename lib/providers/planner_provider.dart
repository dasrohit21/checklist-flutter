import 'package:flutter/material.dart';

import '../models/mission_context.dart';
import '../models/planner_entry.dart';
import '../models/planning_summary.dart';
import '../models/recovery_plan.dart';
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

  // ── Recovery Engine State ──────────────────────────────────────────────────
  RecoveryPlan? _recoveryPlan;
  RecoveryState _recoveryState = RecoveryState.none;

  // ── Getters: lists ─────────────────────────────────────────────────────────

  /// All entries planned for today that are NOT carry-forwards.
  List<PlannerEntry> get todayEntries =>
      List.unmodifiable(_todayEntries.where((e) => !e.isCarryForward));

  /// Entries that were automatically moved from a previous day.
  List<PlannerEntry> get carryForwardEntries =>
      List.unmodifiable(_carryForwardEntries);

  /// Preview of tomorrow's plan.
  List<PlannerEntry> get tomorrowEntries =>
      List.unmodifiable(_tomorrowEntries);

  /// Tomorrow's plan list.
  List<PlannerEntry> get tomorrowPlan =>
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

  // ── Getters: Recovery Engine ───────────────────────────────────────────────

  RecoveryPlan? get recoveryPlan => _recoveryPlan;
  RecoveryState get recoveryState => _recoveryState;

  /// Remaining non-completed workload in minutes.
  int get remainingWorkloadMinutes =>
      PlannerService.calculateRemainingWorkload(_todayEntries);

  /// Remaining available working time in minutes.
  int get remainingTimeMinutes =>
      PlannerService.calculateRemainingTime(_availableMinutes, _todayEntries);

  /// Whether the Recovery Card should be displayed.
  bool get shouldShowRecoveryCard =>
      _recoveryState == RecoveryState.suggested && _recoveryPlan != null;

  // ── Getters: Adaptive Planner Engine ──────────────────────────────────────

  /// The single recommended first mission to execute today ("Continue First").
  PlannerEntry? get recommendedMission =>
      PlannerService.recommendFirstMission(_todayEntries);

  /// Estimated total workload in minutes for tomorrow's plan.
  int get tomorrowWorkloadMinutes => _tomorrowEntries
      .where((e) => e.status != PlannerEntryStatus.completed)
      .fold(0, (sum, e) => sum + e.estimatedDurationMinutes);

  /// Whether tomorrow's estimated workload exceeds available time ("Tomorrow Looks Busy").
  bool get isTomorrowOverflowed => tomorrowWorkloadMinutes > _availableMinutes;

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
    await _reloadAll();
    notifyListeners();
  }

  // ── Recovery Engine Actions ────────────────────────────────────────────────

  /// Generates a [RecoveryPlan]. If [force] is true (e.g. "Recover My Day"),
  /// overrides dismissal state.
  Future<void> generateRecoveryPlan({bool force = false}) async {
    final plan = PlannerService.generateRecoveryPlan(
      todayEntries: _todayEntries,
      availableMinutes: _availableMinutes,
    );
    _recoveryPlan = plan;
    _recoveryState = RecoveryState.suggested;
    await PlannerService.saveRecoveryPlan(plan);
    await PlannerService.saveRecoveryState(RecoveryState.suggested);
    notifyListeners();
  }

  /// Applies the current [recoveryPlan] and refreshes.
  Future<void> applyRecoveryPlan() async {
    if (_recoveryPlan == null) return;
    await PlannerService.applyRecoveryPlan(_recoveryPlan!);
    _recoveryPlan = null;
    _recoveryState = RecoveryState.accepted;
    await _reloadAll();
    notifyListeners();
  }

  /// Dismisses the recovery plan.
  Future<void> dismissRecoveryPlan() async {
    await PlannerService.dismissRecoveryPlan(_todayEntries);
    _recoveryPlan = null;
    _recoveryState = RecoveryState.dismissed;
    notifyListeners();
  }

  // ── Adaptive Planner Engine Actions ────────────────────────────────────────

  /// Moves a tomorrow entry up by 1 position.
  Future<void> moveTomorrowEntryUp(String id) async {
    await PlannerService.moveTomorrowEntryUp(id);
    await _reloadAll();
    notifyListeners();
  }

  /// Moves a tomorrow entry down by 1 position.
  Future<void> moveTomorrowEntryDown(String id) async {
    await PlannerService.moveTomorrowEntryDown(id);
    await _reloadAll();
    notifyListeners();
  }

  /// Transfers a tomorrow entry to today's plan.
  Future<void> moveTomorrowEntryToToday(String id) async {
    await PlannerService.moveTomorrowEntryToToday(id);
    await _reloadAll();
    notifyListeners();
  }

  /// Removes an entry from tomorrow's plan.
  Future<void> removeTomorrowEntry(String id) async {
    await PlannerService.removeTomorrowEntry(id);
    await _reloadAll();
    notifyListeners();
  }

  /// Auto-generates tomorrow's plan.
  Future<void> generateTomorrowPlan({List<PlannerEntry>? additionalEntries}) async {
    await PlannerService.generateTomorrowPlan(additionalEntries: additionalEntries);
    await _reloadAll();
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

    // Check Recovery Engine triggers
    final savedState = await PlannerService.loadRecoveryState();
    final isDismissed = await PlannerService.isDismissedForState(_todayEntries);

    final remWorkload = PlannerService.calculateRemainingWorkload(_todayEntries);
    final remTime = PlannerService.calculateRemainingTime(_availableMinutes, _todayEntries);

    if (remWorkload > remTime && !isDismissed) {
      final savedPlan = await PlannerService.loadRecoveryPlan();
      if (savedPlan != null && savedState == RecoveryState.suggested) {
        _recoveryPlan = savedPlan;
        _recoveryState = RecoveryState.suggested;
      } else {
        // Auto-generate suggestion when overloaded and not dismissed
        _recoveryPlan = PlannerService.generateRecoveryPlan(
          todayEntries: _todayEntries,
          availableMinutes: _availableMinutes,
        );
        _recoveryState = RecoveryState.suggested;
      }
    } else if (remWorkload <= remTime) {
      if (savedState == RecoveryState.suggested) {
        _recoveryPlan = null;
        _recoveryState = RecoveryState.none;
        await PlannerService.saveRecoveryState(RecoveryState.none);
        await PlannerService.saveRecoveryPlan(null);
      } else {
        _recoveryState = savedState;
        _recoveryPlan = await PlannerService.loadRecoveryPlan();
      }
    } else {
      _recoveryState = savedState;
      _recoveryPlan = await PlannerService.loadRecoveryPlan();
    }
  }
}
