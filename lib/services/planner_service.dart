import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mission_context.dart';
import '../models/planner_entry.dart';
import '../models/planning_summary.dart';
import '../models/recovery_plan.dart';

/// Pure business-logic service for the Execution Planner.
///
/// All data lives in [SharedPreferences]. No UI dependencies here.
class PlannerService {
  // ── SharedPreferences key constants ────────────────────────────────────────

  static const String _lastCarryForwardKey = 'planner_last_carry_forward_date';
  static const String _availableMinutesKey = 'planner_available_minutes';
  static const String _recoveryPlanKey = 'planner_recovery_plan';
  static const String _recoveryStateKey = 'planner_recovery_state';
  static const String _recoveryDismissedSigKey = 'planner_recovery_dismissed_sig';

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

  // ── Tomorrow preview & Adaptive Planning ──────────────────────────────────

  /// Loads the tomorrow preview entries.
  static Future<List<PlannerEntry>> loadTomorrowEntries() async {
    return _loadEntries(tomorrowStr);
  }

  /// Saves tomorrow's preview entries.
  static Future<void> saveTomorrowEntries(List<PlannerEntry> entries) async {
    await _saveEntries(tomorrowStr, entries);
  }

  /// Calculates total estimated workload in minutes for tomorrow's entries.
  static Future<int> calculateTomorrowWorkload() async {
    final entries = await loadTomorrowEntries();
    return entries
        .where((e) => e.status != PlannerEntryStatus.completed)
        .fold<int>(0, (sum, e) => sum + e.estimatedDurationMinutes);
  }

  /// Sorts [entries] according to deterministic priority rules:
  ///   P1: Mission in progress
  ///   P2: Carry Forward missions
  ///   P3: High Priority missions
  ///   P4: Normal Priority missions
  ///   P5: Low Priority missions
  /// Preserves relative order within the same priority bucket.
  /// Completed missions remain at the end.
  static List<PlannerEntry> sortPlanner(List<PlannerEntry> entries) {
    if (entries.isEmpty) return [];

    final indexed = entries.asMap().entries.toList();

    int getPriorityScore(PlannerEntry entry) {
      if (entry.status == PlannerEntryStatus.inProgress) return 1;
      if (entry.isCarryForward) return 2;
      final p = entry.priority.toLowerCase();
      if (p == 'high') return 3;
      if (p == 'normal' || p == 'medium') return 4;
      if (p == 'low') return 5;
      return 4;
    }

    indexed.sort((a, b) {
      if (a.value.status == PlannerEntryStatus.completed &&
          b.value.status != PlannerEntryStatus.completed) {
        return 1;
      }
      if (a.value.status != PlannerEntryStatus.completed &&
          b.value.status == PlannerEntryStatus.completed) {
        return -1;
      }

      final scoreA = getPriorityScore(a.value);
      final scoreB = getPriorityScore(b.value);
      if (scoreA != scoreB) {
        return scoreA.compareTo(scoreB);
      }
      return a.key.compareTo(b.key);
    });

    return indexed.map((e) => e.value).toList();
  }

  /// Returns the recommended first mission to execute today:
  ///   - In-progress mission if one exists ("Continue First")
  ///   - Otherwise the top non-completed mission from sorted today entries.
  static PlannerEntry? recommendFirstMission(List<PlannerEntry> todayEntries) {
    if (todayEntries.isEmpty) return null;

    final sorted = sortPlanner(todayEntries);
    return sorted.cast<PlannerEntry?>().firstWhere(
          (e) => e != null && e.status != PlannerEntryStatus.completed,
          orElse: () => null,
        );
  }

  /// Automatically generates tomorrow's plan by combining existing scheduled
  /// entries and optional new entries, deduplicating by targetId, and sorting.
  static Future<List<PlannerEntry>> generateTomorrowPlan({
    List<PlannerEntry>? additionalEntries,
  }) async {
    final currentTomorrow = await loadTomorrowEntries();
    final existingTargetIds = currentTomorrow.map((e) => e.targetId).toSet();

    final merged = List<PlannerEntry>.from(currentTomorrow);

    if (additionalEntries != null) {
      for (final entry in additionalEntries) {
        if (!existingTargetIds.contains(entry.targetId)) {
          merged.add(entry.copyWith(scheduledDate: tomorrowStr));
          existingTargetIds.add(entry.targetId);
        }
      }
    }

    final sorted = sortPlanner(merged);
    await saveTomorrowEntries(sorted);
    return sorted;
  }

  /// Persists a custom mission ordering for a given date.
  static Future<void> updateMissionOrder(
    String dateStr,
    List<PlannerEntry> entries,
  ) async {
    await _saveEntries(dateStr, entries);
  }

  // ── Quick Actions for Tomorrow ─────────────────────────────────────────────

  /// Moves a tomorrow entry up by 1 position.
  static Future<void> moveTomorrowEntryUp(String entryId) async {
    final entries = await loadTomorrowEntries();
    final idx = entries.indexWhere((e) => e.id == entryId);
    if (idx <= 0) return;

    final item = entries.removeAt(idx);
    entries.insert(idx - 1, item);
    await saveTomorrowEntries(entries);
  }

  /// Moves a tomorrow entry down by 1 position.
  static Future<void> moveTomorrowEntryDown(String entryId) async {
    final entries = await loadTomorrowEntries();
    final idx = entries.indexWhere((e) => e.id == entryId);
    if (idx == -1 || idx >= entries.length - 1) return;

    final item = entries.removeAt(idx);
    entries.insert(idx + 1, item);
    await saveTomorrowEntries(entries);
  }

  /// Transfers an entry from tomorrow's list to today's list.
  static Future<void> moveTomorrowEntryToToday(String entryId) async {
    final tomorrowEntries = await loadTomorrowEntries();
    final idx = tomorrowEntries.indexWhere((e) => e.id == entryId);
    if (idx == -1) return;

    final entry = tomorrowEntries.removeAt(idx);
    await saveTomorrowEntries(tomorrowEntries);

    final todayEntries = await loadTodayEntries();
    // Avoid duplicates in today
    if (!todayEntries.any((e) => e.targetId == entry.targetId)) {
      todayEntries.add(entry.copyWith(
        scheduledDate: todayStr,
        isCarryForward: false,
      ));
      await saveTodayEntries(todayEntries);
    }
  }

  /// Removes an entry from tomorrow's list.
  static Future<void> removeTomorrowEntry(String entryId) async {
    final entries = await loadTomorrowEntries();
    entries.removeWhere((e) => e.id == entryId);
    await saveTomorrowEntries(entries);
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

  // ── Recovery Engine ────────────────────────────────────────────────────────

  /// Returns the total estimated minutes for remaining (non-completed) [entries].
  static int calculateRemainingWorkload(List<PlannerEntry> entries) {
    return entries
        .where((e) => e.status != PlannerEntryStatus.completed)
        .fold(0, (sum, e) => sum + e.estimatedDurationMinutes);
  }

  /// Calculates remaining available time in minutes for today.
  ///
  /// Subtracts duration of completed missions from total [availableMinutes].
  static int calculateRemainingTime(
    int availableMinutes,
    List<PlannerEntry> todayEntries,
  ) {
    final completedMinutes = todayEntries
        .where((e) => e.status == PlannerEntryStatus.completed)
        .fold(0, (sum, e) => sum + e.estimatedDurationMinutes);
    final remaining = availableMinutes - completedMinutes;
    return remaining < 0 ? 0 : remaining;
  }

  /// Generates a [RecoveryPlan] using the 6 Priority Rules:
  ///   P1: Never move completed missions.
  ///   P2: Try to keep in-progress missions.
  ///   P3: Move largest pending missions first.
  ///   P4: Keep remaining workload within remaining available time.
  ///   P5: Never duplicate missions.
  ///   P6: Maintain original order.
  static RecoveryPlan generateRecoveryPlan({
    required List<PlannerEntry> todayEntries,
    required int availableMinutes,
  }) {
    final remainingWorkload = calculateRemainingWorkload(todayEntries);
    final remainingTime =
        calculateRemainingTime(availableMinutes, todayEntries);

    final pending =
        todayEntries.where((e) => e.status == PlannerEntryStatus.pending).toList();

    // Target workload to trim from pending missions
    final targetTrimAmount = remainingWorkload - remainingTime;

    final toMoveIds = <String>{};

    if (targetTrimAmount > 0 && pending.isNotEmpty) {
      // Sort pending entries by duration descending (largest first)
      final sortedPending = List<PlannerEntry>.from(pending)
        ..sort((a, b) =>
            b.estimatedDurationMinutes.compareTo(a.estimatedDurationMinutes));

      int movedAcc = 0;
      for (final entry in sortedPending) {
        toMoveIds.add(entry.id);
        movedAcc += entry.estimatedDurationMinutes;
        if (movedAcc >= targetTrimAmount) break;
      }
    }

    // Assemble items maintaining original order (P6)
    final items = <RecoveryItem>[];
    for (final entry in todayEntries) {
      if (entry.status == PlannerEntryStatus.completed) {
        items.add(RecoveryItem(
          entry: entry,
          action: RecoveryItemAction.keep,
          reason: 'Completed',
        ));
      } else if (entry.status == PlannerEntryStatus.inProgress) {
        items.add(RecoveryItem(
          entry: entry,
          action: RecoveryItemAction.keep,
          reason: 'In Progress',
        ));
      } else if (toMoveIds.contains(entry.id)) {
        items.add(RecoveryItem(
          entry: entry,
          action: RecoveryItemAction.moveToTomorrow,
          reason: 'Move to tomorrow to fit available time',
        ));
      } else {
        items.add(RecoveryItem(
          entry: entry,
          action: RecoveryItemAction.keep,
          reason: 'Fits within available time',
        ));
      }
    }

    return RecoveryPlan(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      remainingWorkloadMinutes: remainingWorkload,
      remainingAvailableMinutes: remainingTime,
      items: items,
    );
  }

  /// Applies a [RecoveryPlan]:
  ///   - Moves recommended entries to tomorrow.
  ///   - Removes moved entries from today's plan.
  ///   - Preserves mission context & progress.
  ///   - Sets recovery state to [RecoveryState.accepted].
  static Future<void> applyRecoveryPlan(RecoveryPlan plan) async {
    final todayEntries = await loadTodayEntries();
    final tomorrowEntries = await loadTomorrowEntries();
    final existingTomorrowTargetIds =
        tomorrowEntries.map((e) => e.targetId).toSet();

    final moveItems = plan.moveItems;
    final moveIds = moveItems.map((i) => i.entry.id).toSet();

    // Update today's entries
    final updatedToday =
        todayEntries.where((e) => !moveIds.contains(e.id)).toList();
    await saveTodayEntries(updatedToday);

    // Update tomorrow's entries (P5: avoid duplicates)
    for (final item in moveItems) {
      if (existingTomorrowTargetIds.contains(item.entry.targetId)) continue;
      tomorrowEntries.add(item.entry.copyWith(
        scheduledDate: tomorrowStr,
        isCarryForward: false,
        status: PlannerEntryStatus.pending,
      ));
      existingTomorrowTargetIds.add(item.entry.targetId);
    }
    await saveTomorrowEntries(tomorrowEntries);

    // Save state
    await saveRecoveryState(RecoveryState.accepted);
    await saveRecoveryPlan(null);
  }

  /// Dismisses the recovery plan for the current planner state.
  static Future<void> dismissRecoveryPlan(
      List<PlannerEntry> currentEntries) async {
    final prefs = await SharedPreferences.getInstance();
    await saveRecoveryState(RecoveryState.dismissed);
    await saveRecoveryPlan(null);

    // Compute signature of current entries to detect future changes
    final sig = _computeEntriesSignature(currentEntries);
    await prefs.setString(_recoveryDismissedSigKey, sig);
  }

  /// Checks if dismissal signature matches current entries.
  static Future<bool> isDismissedForState(
      List<PlannerEntry> currentEntries) async {
    final prefs = await SharedPreferences.getInstance();
    final state = await loadRecoveryState();
    if (state != RecoveryState.dismissed) return false;

    final savedSig = prefs.getString(_recoveryDismissedSigKey);
    final currentSig = _computeEntriesSignature(currentEntries);
    return savedSig == currentSig;
  }

  /// Loads saved recovery plan or null.
  static Future<RecoveryPlan?> loadRecoveryPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recoveryPlanKey);
    if (raw == null) return null;
    try {
      return RecoveryPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Saves recovery plan.
  static Future<void> saveRecoveryPlan(RecoveryPlan? plan) async {
    final prefs = await SharedPreferences.getInstance();
    if (plan == null) {
      await prefs.remove(_recoveryPlanKey);
    } else {
      await prefs.setString(_recoveryPlanKey, jsonEncode(plan.toJson()));
    }
  }

  /// Loads recovery state.
  static Future<RecoveryState> loadRecoveryState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recoveryStateKey);
    if (raw == null) return RecoveryState.none;
    return RecoveryState.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => RecoveryState.none,
    );
  }

  /// Saves recovery state.
  static Future<void> saveRecoveryState(RecoveryState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recoveryStateKey, state.name);
  }

  static String _computeEntriesSignature(List<PlannerEntry> entries) {
    final str = entries
        .map((e) => '${e.id}:${e.status.name}:${e.estimatedDurationMinutes}')
        .join('|');
    return str;
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
