import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coach_message.dart';
import '../models/coach_personality.dart';
import '../models/planner_entry.dart';
import '../models/planning_summary.dart';

/// Pure business logic service for the Coach Engine.
///
/// Analyzes real user planner data and generates fact-based observations
/// paired with concrete action recommendations formatted for the selected personality.
class CoachService {
  static const String _enabledKey = 'coach_enabled';
  static const String _personalityKey = 'coach_personality';
  static const String _latestMessageKey = 'coach_latest_message';

  // ── Persistence ────────────────────────────────────────────────────────────

  static Future<bool> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  static Future<CoachPersonality> loadPersonality() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_personalityKey);
    if (raw == null) return CoachPersonality.balanced;
    return CoachPersonality.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CoachPersonality.balanced,
    );
  }

  static Future<void> savePersonality(CoachPersonality personality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalityKey, personality.name);
  }

  static Future<CoachMessage?> loadLatestMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_latestMessageKey);
    if (raw == null) return null;
    try {
      return CoachMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLatestMessage(CoachMessage? message) async {
    final prefs = await SharedPreferences.getInstance();
    if (message == null) {
      await prefs.remove(_latestMessageKey);
    } else {
      await prefs.setString(_latestMessageKey, jsonEncode(message.toJson()));
    }
  }

  // ── Fact Evaluation & Message Generation ───────────────────────────────────

  /// Analyzes current planner data and returns a tailored [CoachMessage].
  static CoachMessage evaluatePlannerData({
    required List<PlannerEntry> todayEntries,
    required List<PlannerEntry> tomorrowEntries,
    required int availableMinutes,
    required PlannerStatus status,
    required bool isRecoveryActive,
    required CoachPersonality personality,
    int currentStreak = 0,
  }) {
    final completed =
        todayEntries.where((e) => e.status == PlannerEntryStatus.completed).toList();
    final carryForwards =
        todayEntries.where((e) => e.isCarryForward && e.status != PlannerEntryStatus.completed).toList();
    final totalCount = todayEntries.length;
    final completedCount = completed.length;
    final remainingWorkload = todayEntries
        .where((e) => e.status != PlannerEntryStatus.completed)
        .fold(0, (sum, e) => sum + e.estimatedDurationMinutes);

    // Rule Priority 1: Achievement (100% completed)
    if (todayEntries.isNotEmpty && completedCount == totalCount) {
      return _buildMessage(
        type: CoachMessageType.achievement,
        facts: 'You completed every mission today ($completedCount of $totalCount).',
        action: 'Keep tomorrow\'s workload similar to maintain this momentum.',
        personality: personality,
        evidence: {'completed': completedCount, 'total': totalCount},
      );
    }

    // Rule Priority 2: Recovery (Active recovery plan)
    if (isRecoveryActive) {
      return _buildMessage(
        type: CoachMessageType.recovery,
        facts: 'Today\'s workload became unrealistic. Recovery plan is active.',
        action: 'Focus on finishing remaining kept missions first.',
        personality: personality,
        evidence: {'isRecoveryActive': true},
      );
    }

    // Rule Priority 3: Warning (Repeated postponements or overload)
    if (carryForwards.isNotEmpty) {
      final topCarried = carryForwards.first;
      return _buildMessage(
        type: CoachMessageType.warning,
        facts: '"${topCarried.targetName}" has been postponed from a previous day.',
        action: 'Consider completing "${topCarried.targetName}" first tomorrow.',
        personality: personality,
        evidence: {'postponedTarget': topCarried.targetName},
      );
    }

    if (status == PlannerStatus.overloaded) {
      final workloadH = remainingWorkload ~/ 60;
      final availableH = availableMinutes ~/ 60;
      return _buildMessage(
        type: CoachMessageType.warning,
        facts: 'Remaining workload (~${workloadH}h) exceeds available time (${availableH}h).',
        action: 'Move one or two non-essential missions to tomorrow.',
        personality: personality,
        evidence: {
          'workloadMinutes': remainingWorkload,
          'availableMinutes': availableMinutes
        },
      );
    }

    // Rule Priority 4: Improvement (Partial progress made)
    if (completedCount > 0) {
      return _buildMessage(
        type: CoachMessageType.improvement,
        facts: 'You completed $completedCount of $totalCount missions today.',
        action: 'Focus on finishing your next scheduled mission.',
        personality: personality,
        evidence: {'completed': completedCount, 'total': totalCount},
      );
    }

    // Rule Priority 5: Planning (Realistic workload)
    final workloadH = remainingWorkload ~/ 60;
    return _buildMessage(
      type: CoachMessageType.planning,
      facts: 'Today\'s plan contains $totalCount mission(s) totaling ~${workloadH}h.',
      action: 'Execute missions in order without interruption.',
      personality: personality,
      evidence: {'total': totalCount, 'workloadMinutes': remainingWorkload},
    );
  }

  // ── Personality Tone Formatting ────────────────────────────────────────────

  static CoachMessage _buildMessage({
    required CoachMessageType type,
    required String facts,
    required String action,
    required CoachPersonality personality,
    required Map<String, dynamic> evidence,
  }) {
    final title = _getTitle(type, personality);
    final formattedBody = _formatBody(facts, personality);
    final formattedAction = _formatAction(action, personality);

    return CoachMessage(
      id: 'coach_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      body: formattedBody,
      actionRecommendation: formattedAction,
      timestamp: DateTime.now(),
      evidence: evidence,
    );
  }

  static String _getTitle(CoachMessageType type, CoachPersonality p) {
    switch (p) {
      case CoachPersonality.mentor:
        return switch (type) {
          CoachMessageType.achievement => 'Outstanding Consistency! 🌟',
          CoachMessageType.warning => 'Friendly Reminder 💡',
          CoachMessageType.recovery => 'Adjusting Course 🛠️',
          CoachMessageType.improvement => 'Steady Growth 📈',
          CoachMessageType.planning => 'Well Planned Day 🎯',
        };
      case CoachPersonality.balanced:
        return switch (type) {
          CoachMessageType.achievement => 'Plan Completed 🎯',
          CoachMessageType.warning => 'Workload Alert ⚠️',
          CoachMessageType.recovery => 'Recovery Suggestion 🔄',
          CoachMessageType.improvement => 'Progress Update 📊',
          CoachMessageType.planning => 'Daily Execution Overview 📋',
        };
      case CoachPersonality.drillSergeant:
        return switch (type) {
          CoachMessageType.achievement => 'Mission Accomplished! ⚡',
          CoachMessageType.warning => 'Attention Required! 🛑',
          CoachMessageType.recovery => 'Tactical Re-alignment 🛠️',
          CoachMessageType.improvement => 'Execution In Progress ⚔️',
          CoachMessageType.planning => 'Standard Execution Plan 🎯',
        };
      case CoachPersonality.rival:
        return switch (type) {
          CoachMessageType.achievement => 'Top Score Achieved! 🏆',
          CoachMessageType.warning => 'Don\'t Fall Behind! ⚔️',
          CoachMessageType.recovery => 'Course Correction Needed 🔄',
          CoachMessageType.improvement => 'Closing The Gap 🚀',
          CoachMessageType.planning => 'Challenge Set 🎯',
        };
      case CoachPersonality.stoic:
        return switch (type) {
          CoachMessageType.achievement => 'Disciplined Completion 🏛️',
          CoachMessageType.warning => 'Observe The Friction ⚖️',
          CoachMessageType.recovery => 'Adapt To Reality 🌊',
          CoachMessageType.improvement => 'Measured Effort 🌿',
          CoachMessageType.planning => 'Orderly Intention 🏛️',
        };
    }
  }

  static String _formatBody(String facts, CoachPersonality p) {
    switch (p) {
      case CoachPersonality.mentor:
        return '$facts Keep going step by step.';
      case CoachPersonality.balanced:
        return facts;
      case CoachPersonality.drillSergeant:
        return '$facts Stand by for action.';
      case CoachPersonality.rival:
        return '$facts Let\'s see how far you push it.';
      case CoachPersonality.stoic:
        return '$facts Action speaks without noise.';
    }
  }

  static String _formatAction(String action, CoachPersonality p) {
    switch (p) {
      case CoachPersonality.mentor:
        return 'Tip: $action';
      case CoachPersonality.balanced:
        return 'Recommended: $action';
      case CoachPersonality.drillSergeant:
        return 'Directive: $action';
      case CoachPersonality.rival:
        return 'Next Challenge: $action';
      case CoachPersonality.stoic:
        return 'Focus: $action';
    }
  }
}
