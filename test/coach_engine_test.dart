import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist/models/coach_message.dart';
import 'package:checklist/models/coach_personality.dart';
import 'package:checklist/models/planner_entry.dart';
import 'package:checklist/models/planning_summary.dart';
import 'package:checklist/services/coach_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Coach Engine Unit Tests', () {
    test('evaluatePlannerData generates Achievement message when 100% completed', () {
      final entries = [
        const PlannerEntry(
          id: '1',
          targetId: 't1',
          targetName: 'Task 1',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
          status: PlannerEntryStatus.completed,
        ),
      ];

      final message = CoachService.evaluatePlannerData(
        todayEntries: entries,
        tomorrowEntries: [],
        availableMinutes: 360,
        status: PlannerStatus.onTrack,
        isRecoveryActive: false,
        personality: CoachPersonality.mentor,
      );

      expect(message.type, CoachMessageType.achievement);
      expect(message.body, contains('completed every mission today'));
      expect(message.actionRecommendation, contains('momentum'));
    });

    test('evaluatePlannerData generates Warning message when carry-forwards exist', () {
      final entries = [
        const PlannerEntry(
          id: '1',
          targetId: 't1',
          targetName: 'Flutter Authentication',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 90,
          isCarryForward: true,
          status: PlannerEntryStatus.pending,
        ),
      ];

      final message = CoachService.evaluatePlannerData(
        todayEntries: entries,
        tomorrowEntries: [],
        availableMinutes: 360,
        status: PlannerStatus.onTrack,
        isRecoveryActive: false,
        personality: CoachPersonality.balanced,
      );

      expect(message.type, CoachMessageType.warning);
      expect(message.body, contains('Flutter Authentication'));
      expect(message.actionRecommendation, contains('first tomorrow'));
    });

    test('evaluatePlannerData generates Recovery message when recovery is active', () {
      final entries = [
        const PlannerEntry(
          id: '1',
          targetId: 't1',
          targetName: 'Task 1',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
        ),
      ];

      final message = CoachService.evaluatePlannerData(
        todayEntries: entries,
        tomorrowEntries: [],
        availableMinutes: 360,
        status: PlannerStatus.overloaded,
        isRecoveryActive: true,
        personality: CoachPersonality.drillSergeant,
      );

      expect(message.type, CoachMessageType.recovery);
      expect(message.title, contains('Tactical Re-alignment'));
      expect(message.body, contains('unrealistic'));
    });

    test('All 5 personalities format messages with evidence and constructive tone', () {
      final entries = [
        const PlannerEntry(
          id: '1',
          targetId: 't1',
          targetName: 'Task 1',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
        ),
      ];

      for (final p in CoachPersonality.values) {
        final message = CoachService.evaluatePlannerData(
          todayEntries: entries,
          tomorrowEntries: [],
          availableMinutes: 360,
          status: PlannerStatus.onTrack,
          isRecoveryActive: false,
          personality: p,
        );

        expect(message.title.isNotEmpty, isTrue);
        expect(message.body.isNotEmpty, isTrue);
        expect(message.actionRecommendation.isNotEmpty, isTrue);
        // Ensure constructive phrasing (no insults)
        expect(message.body.toLowerCase(), isNot(contains('lazy')));
        expect(message.body.toLowerCase(), isNot(contains('failure')));
        expect(message.body.toLowerCase(), isNot(contains('pathetic')));
      }
    });

    test('CoachService persistence for enable toggle and personality', () async {
      await CoachService.saveEnabled(false);
      await CoachService.savePersonality(CoachPersonality.stoic);

      final enabled = await CoachService.loadEnabled();
      final personality = await CoachService.loadPersonality();

      expect(enabled, isFalse);
      expect(personality, CoachPersonality.stoic);
    });
  });
}
