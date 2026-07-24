import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mission_context.dart';
import '../models/planner_entry.dart';
import '../models/planning_summary.dart';

/// Pure business-logic service for the Execution Planner.
///
/// All data lives in [SharedPreferences]. No UI dependencies here.
class PlannerService {
  // ── SharedPreferences key constants ────────────────────────────────────────

  static const String _lastCarryForwardKey = 'planner_last_carry_forward_date';
  static const String _tomorrowEntriesKey = 'planner_tomorrow_entries';
  static const String _availableMinutesKey = 'planner_available_minutes';

  /// Default available working time (6 hours).
  static const int defaultAvailableMinutes = 360;

  /// Returns the key used to store entries for a given date.
  static String _entriesKey(String dateStr) => 'planner_entries_$dateStr';

  /// Returns the key used to store the context for a given target.
  static String _contextKey(String targetId) =>
      'planner_mission_context_$targetId';

  // ── Date helpers ──────────────────────────────────────────────────────────

  static String dateString(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String get todayStr => dateString(DateTime.now());

  static String get yesterdayStr =>
      dateString(DateTime.now().subtract(const Duration(days: 1)));

  static String get tomorrowStr =>
      dateString(DateTime.now().add(const Duration(days: 1)));

  // ── Today's entries ────────────────────────────────────────────────────────

  /// Loads all planner entries scheduled for today.
  static Future<List<PlannerEntry>> loadTodayEntries() async {
    return _loadEntries(todayStr);
  }

  /// Persists today's planner entries.
  static Future<void> saveTodayEntries(List<PlannerEntry> entries) async {
    await _saveEntries(todayStr, entries);
  }

  // ── Carry-forward ──────────────────────────────────────────────────────────

  /// Loads the carry-forward entries that were automatically moved to today.
  ///
  /// Returns only entries in today's list that have [isCarryForward] == true.
  static Future<List<PlannerEntry>> loadCarryForwardEntries() async {
    final today = await loadTodayEntries();
    return today.where((e) => e.isCarryForward).toList();
  }

  /// Checks whether carry-forward should run (once per day) and, if so,
  /// moves unfinished missions from yesterday into today.
  ///
  /// This is idempotent — running it multiple times on the same day is safe.
  static Future<void> performCarryForward() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getString(_lastCarryForwardKey);

    // Skip if already ran today.
    if (lastRun == todayStr) return;

    final yesterdayEntries = await _loadEntries(yesterdayStr);
    final unfinished = yesterdayEntries
        .where((e) => e.status != PlannerEntryStatus.completed)
        .toList();

    if (unfinished.isEmpty) {
      await prefs.setString(_lastCarryForwardKey, todayStr);
      return;
    }

    final todayEntries = await _loadEntries(todayStr);
    final existingTargetIds = todayEntries.map((e) => e.targetId).toSet();

    final toCarry = <PlannerEntry>[];
    for (final entry in unfinished) {
      // Avoid duplicating a target that's already in today's plan.
      if (existingTargetIds.contains(entry.targetId)) continue;
      toCarry.add(entry.copyWith(
        scheduledDate: todayStr,
        isCarryForward: true,
        status: PlannerEntryStatus.pending,
      ));
    }

    if (toCarry.isNotEmpty) {
      final merged = [...todayEntries, ...toCarry];
      await _saveEntries(todayStr, merged);
    }

    await prefs.setString(_lastCarryForwardKey, todayStr);
  }

  // ── Status mutation ────────────────────────────────────────────────────────

  /// Updates the status of a single entry in today's list and persists.
  static Future<void> updateEntryStatus(
    String entryId,
    PlannerEntryStatus newStatus,
  ) async {
    final entries = await loadTodayEntries();
    final updated = entries.map((e) {
      return e.id == entryId ? e.copyWith(status: newStatus) : e;
    }).toList();
    await saveTodayEntries(updated);
  }

  // ── Add / remove entries ──────────────────────────────────────────────────

  /// Adds a new entry to today's planner.
  static Future<void> addTodayEntry(PlannerEntry entry) async {
    final entries = await loadTodayEntries();
    entries.add(entry);
    await saveTodayEntries(entries);
  }

  /// Removes an entry from today's planner by id.
  static Future<void> removeTodayEntry(String entryId) async {
    final entries = await loadTodayEntries();
    entries.removeWhere((e) => e.id == entryId);
    await saveTodayEntries(entries);
  }

  // ── Tomorrow preview ──────────────────────────────────────────────────────

  /// Loads the read-only tomorrow preview entries.
  static Future<List<PlannerEntry>> loadTomorrowEntries() async {
    return _loadEntries(tomorrowStr);
  }

  /// Saves tomorrow's preview entries.
  static Future<void> saveTomorrowEntries(List<PlannerEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_tomorrowEntriesKey, jsonEncode(jsonList));
  }

  // ── Available time ─────────────────────────────────────────────────────────

  /// Loads the user's configured available daily minutes.
  static Future<int> loadAvailableMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_availableMinutesKey) ?? defaultAvailableMinutes;
  }

  /// Persists the user's configured available daily minutes.
  static Future<void> saveAvailableMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_availableMinutesKey, minutes);
  }

  // ── Workload analysis ──────────────────────────────────────────────────────

  /// Returns the total estimated minutes for all non-completed [entries].
  ///
  /// Pure computation — no I/O.
  static int calculateDailyWorkload(List<PlannerEntry> entries) {
    return entries
        .where((e) => e.status != PlannerEntryStatus.completed)
        .fold(0, (sum, e) => sum + e.estimatedDurationMinutes);
  }

  /// Compares [workloadMinutes] against [availableMinutes] and returns a
  /// [PlannerStatus].
  ///
  /// Thresholds:
  ///   ≤ 85 % → onTrack
  ///   ≤ 100 % → nearLimit
  ///   > 100 % → overloaded
  ///
  /// Pure computation — no I/O.
  static PlannerStatus calculatePlannerStatus(
    int workloadMinutes,
    int availableMinutes,
  ) {
    if (availableMinutes <= 0) return PlannerStatus.overloaded;
    final ratio = workloadMinutes / availableMinutes;
    if (ratio <= 0.85) return PlannerStatus.onTrack;
    if (ratio <= 1.00) return PlannerStatus.nearLimit;
    return PlannerStatus.overloaded;
  }

  // ── Manual move ────────────────────────────────────────────────────────────

  /// Removes [entryId] from today and appends it to tomorrow's list.
  ///
  /// The moved entry is NOT marked as carry-forward — it becomes a regular
  /// planned entry for tomorrow. The user explicitly chose to move it.
  static Future<void> moveMissionToTomorrow(String entryId) async {
    final todayEntries = await loadTodayEntries();
    final idx = todayEntries.indexWhere((e) => e.id == entryId);
    if (idx == -1) return; // Already gone — silently succeed.

    final entry = todayEntries[idx];
    todayEntries.removeAt(idx);
    await saveTodayEntries(todayEntries);

    // Insert into tomorrow as a regular (non-carry-forward) planned entry.
    final tomorrowEntries = await loadTomorrowEntries();
    tomorrowEntries.add(entry.copyWith(
      scheduledDate: tomorrowStr,
      isCarryForward: false,
      status: PlannerEntryStatus.pending,
    ));
    await _saveEntries(tomorrowStr, tomorrowEntries);
  }

  // ── Mission context ────────────────────────────────────────────────────────

  /// Loads the saved mission context for a target, or null if none exists.
  static Future<MissionContext?> loadMissionContext(String targetId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_contextKey(targetId));
    if (raw == null) return null;
    try {
      return MissionContext.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Persists a mission context for a given target.
  static Future<void> saveMissionContext(MissionContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contextKey(ctx.targetId), jsonEncode(ctx.toJson()));
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<List<PlannerEntry>> _loadEntries(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey(dateStr));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PlannerEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveEntries(
    String dateStr,
    List<PlannerEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_entriesKey(dateStr), jsonEncode(jsonList));
  }
}
