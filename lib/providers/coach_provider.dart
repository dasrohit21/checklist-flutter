import 'package:flutter/material.dart';

import '../models/coach_message.dart';
import '../models/coach_personality.dart';
import '../services/coach_service.dart';
import 'planner_provider.dart';

/// State provider for the behavior-driven Coach Engine.
///
/// Responsibilities:
///   - Expose [currentMessage], [personality], and [isEnabled].
///   - Persist settings via [CoachService].
///   - Evaluate planner data and refresh coach observations.
class CoachProvider extends ChangeNotifier {
  CoachMessage? _currentMessage;
  CoachPersonality _personality = CoachPersonality.balanced;
  bool _isEnabled = true;
  bool _isLoading = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  CoachMessage? get currentMessage => _currentMessage;
  CoachPersonality get personality => _personality;
  bool get isEnabled => _isEnabled;
  bool get isLoading => _isLoading;

  // ── Initialization & Loading ───────────────────────────────────────────────

  /// Loads coach configuration and latest message from persistence.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _isEnabled = await CoachService.loadEnabled();
    _personality = await CoachService.loadPersonality();
    _currentMessage = await CoachService.loadLatestMessage();

    _isLoading = false;
    notifyListeners();
  }

  // ── Action Methods ─────────────────────────────────────────────────────────

  /// Enables or disables the Coach Engine.
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await CoachService.saveEnabled(enabled);
    notifyListeners();
  }

  /// Changes the Coach personality and updates the current observation.
  Future<void> setPersonality(CoachPersonality personality) async {
    _personality = personality;
    await CoachService.savePersonality(personality);
    notifyListeners();
  }

  /// Evaluates current planner data and updates the coach message.
  Future<void> evaluate(PlannerProvider planner) async {
    if (!_isEnabled) return;

    final message = CoachService.evaluatePlannerData(
      todayEntries: planner.todayEntries,
      tomorrowEntries: planner.tomorrowEntries,
      availableMinutes: planner.availableMinutes,
      status: planner.plannerStatus,
      isRecoveryActive: planner.shouldShowRecoveryCard,
      personality: _personality,
    );

    _currentMessage = message;
    await CoachService.saveLatestMessage(message);
    notifyListeners();
  }

  /// Generates a sample preview message for any personality.
  CoachMessage getPreviewMessage(CoachPersonality p) {
    return CoachMessage(
      id: 'preview_${p.name}',
      type: CoachMessageType.planning,
      title: 'Sample Observation',
      body: p.sampleQuote,
      actionRecommendation: 'Execute your planned missions with focus.',
      timestamp: DateTime.now(),
    );
  }
}
