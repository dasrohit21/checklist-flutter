import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/target_item.dart';
import '../models/mission_session.dart';
import '../models/planner_entry.dart';
import '../providers/app_state.dart';
import '../providers/planner_provider.dart';
import '../providers/coach_provider.dart';
import '../providers/learning_provider.dart';
import '../providers/behavior_provider.dart';

/// MissionSessionService coordinates temporary Mission Session creation,
/// execution lifecycle, and target progress synchronization.
class MissionSessionService {
  /// Launches a new Mission Session for the specified target.
  static Future<void> launchSession(
    BuildContext context, {
    required TargetItem target,
    required int durationMinutes,
    int selectedGoalCount = 3,
    List<String> selectedItemIds = const [],
  }) async {
    final appState = Provider.of<AppState>(context, listen: false);

    final session = MissionSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      targetId: target.id,
      targetTitle: target.title,
      targetType: target.type,
      startTime: DateTime.now(),
      estimatedDurationMinutes: durationMinutes,
      selectedGoalCount: selectedGoalCount,
      selectedItemIds: selectedItemIds,
      status: MissionSessionStatus.active,
      lastResumeTime: DateTime.now(),
    );

    await appState.startSession(session);
    if (!context.mounted) return;

    // Update Planner if there's a pending planner entry for this target today
    final planner = Provider.of<PlannerProvider>(context, listen: false);
    final matchingEntries = planner.todayEntries.where((e) => e.targetId == target.id).toList();
    if (matchingEntries.isNotEmpty) {
      await planner.updateEntryStatus(matchingEntries.first.id, PlannerEntryStatus.inProgress);
    }
  }

  /// Pauses the active Mission Session.
  static void pauseSession(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.pauseSession();
  }

  /// Resumes the active Mission Session.
  static void resumeSession(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.resumeSession();
  }

  /// Completes the active Mission Session.
  /// Automatically updates Target progress, Planner, Learning Engine, Behavior Engine, and Coach.
  static Future<void> completeSession(
    BuildContext context, {
    int solvedDelta = 0,
    List<String> completedChecklistIds = const [],
  }) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final planner = Provider.of<PlannerProvider>(context, listen: false);
    final coach = Provider.of<CoachProvider>(context, listen: false);
    final learning = Provider.of<LearningProvider>(context, listen: false);
    final behavior = Provider.of<BehaviorProvider>(context, listen: false);

    final activeSession = appState.activeSession;
    if (activeSession == null) return;

    final targetId = activeSession.targetId;

    // Complete session in AppState (which updates Target solvedCount / checklist subItems and records history)
    await appState.completeActiveSession(
      solvedDelta: solvedDelta,
      completedChecklistIds: completedChecklistIds,
    );

    // Update Planner entry if exists
    final matchingEntries = planner.todayEntries.where((e) => e.targetId == targetId).toList();
    if (matchingEntries.isNotEmpty) {
      await planner.updateEntryStatus(matchingEntries.first.id, PlannerEntryStatus.completed);
    }

    // Update Engines
    await learning.load();
    await coach.evaluate(planner);
    await behavior.evaluate(
      history: learning.dailyHistory,
      todayEntries: planner.todayEntries,
      tomorrowEntries: planner.tomorrowEntries,
    );
  }
}
