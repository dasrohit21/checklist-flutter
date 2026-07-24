import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist/models/planner_entry.dart';
import 'package:checklist/models/recovery_plan.dart';
import 'package:checklist/services/planner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Recovery Engine Priority Rules & Logic Tests', () {
    test('calculateRemainingWorkload sums non-completed entries', () {
      final entries = [
        const PlannerEntry(
          id: '1',
          targetId: 't1',
          targetName: 'Task 1',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
          status: PlannerEntryStatus.completed,
        ),
        const PlannerEntry(
          id: '2',
          targetId: 't2',
          targetName: 'Task 2',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 90,
          status: PlannerEntryStatus.inProgress,
        ),
        const PlannerEntry(
          id: '3',
          targetId: 't3',
          targetName: 'Task 3',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 120,
          status: PlannerEntryStatus.pending,
        ),
      ];

      final remaining = PlannerService.calculateRemainingWorkload(entries);
      expect(remaining, 210); // 90 + 120 (completed 60 excluded)
    });

    test('calculateRemainingTime subtracts completed minutes from available time', () {
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

      final remaining = PlannerService.calculateRemainingTime(360, entries);
      expect(remaining, 300); // 360 - 60
    });

    test('generateRecoveryPlan respects Priority 1, 2, 3, 4, 6', () {
      final entries = [
        const PlannerEntry(
          id: 'e1',
          targetId: 't1',
          targetName: 'Completed Mission',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
          status: PlannerEntryStatus.completed,
        ),
        const PlannerEntry(
          id: 'e2',
          targetId: 't2',
          targetName: 'In Progress Mission',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 90,
          status: PlannerEntryStatus.inProgress,
        ),
        const PlannerEntry(
          id: 'e3',
          targetId: 't3',
          targetName: 'Small Pending',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 30,
          status: PlannerEntryStatus.pending,
        ),
        const PlannerEntry(
          id: 'e4',
          targetId: 't4',
          targetName: 'Huge Pending DSA',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 180,
          status: PlannerEntryStatus.pending,
        ),
      ];

      // Available time = 180 min (3h)
      // Completed = 60 min -> remaining available time = 120 min
      // Remaining workload = 90 (inProgress) + 30 (small) + 180 (huge) = 300 min
      // Need to trim: 300 - 120 = 180 min
      // Priority 1: Keep completed (e1)
      // Priority 2: Keep in-progress (e2)
      // Priority 3: Move largest pending first -> e4 (180 min) moved to tomorrow
      final plan = PlannerService.generateRecoveryPlan(
        todayEntries: entries,
        availableMinutes: 180,
      );

      expect(plan.remainingWorkloadMinutes, 300);
      expect(plan.remainingAvailableMinutes, 120);

      // Check item actions
      final e1Item = plan.items.firstWhere((i) => i.entry.id == 'e1');
      expect(e1Item.action, RecoveryItemAction.keep);

      final e2Item = plan.items.firstWhere((i) => i.entry.id == 'e2');
      expect(e2Item.action, RecoveryItemAction.keep);

      final e3Item = plan.items.firstWhere((i) => i.entry.id == 'e3');
      expect(e3Item.action, RecoveryItemAction.keep);

      final e4Item = plan.items.firstWhere((i) => i.entry.id == 'e4');
      expect(e4Item.action, RecoveryItemAction.moveToTomorrow);
      expect(e4Item.reason, contains('Move to tomorrow'));
    });

    test('applyRecoveryPlan updates today and tomorrow plans without duplication (P5)', () async {
      final todayEntries = [
        const PlannerEntry(
          id: 'e1',
          targetId: 't1',
          targetName: 'Keep Me',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
          status: PlannerEntryStatus.pending,
        ),
        const PlannerEntry(
          id: 'e2',
          targetId: 't2',
          targetName: 'Move Me',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 120,
          status: PlannerEntryStatus.pending,
        ),
      ];

      await PlannerService.saveTodayEntries(todayEntries);

      final plan = RecoveryPlan(
        id: 'r1',
        generatedAt: DateTime.now(),
        remainingWorkloadMinutes: 180,
        remainingAvailableMinutes: 60,
        items: [
          RecoveryItem(
            entry: todayEntries[0],
            action: RecoveryItemAction.keep,
            reason: 'Fits',
          ),
          RecoveryItem(
            entry: todayEntries[1],
            action: RecoveryItemAction.moveToTomorrow,
            reason: 'Move',
          ),
        ],
      );

      await PlannerService.applyRecoveryPlan(plan);

      final updatedToday = await PlannerService.loadTodayEntries();
      final updatedTomorrow = await PlannerService.loadTomorrowEntries();

      expect(updatedToday.length, 1);
      expect(updatedToday.first.id, 'e1');

      expect(updatedTomorrow.length, 1);
      expect(updatedTomorrow.first.id, 'e2');
      expect(updatedTomorrow.first.scheduledDate, PlannerService.tomorrowStr);

      final state = await PlannerService.loadRecoveryState();
      expect(state, RecoveryState.accepted);
    });

    test('dismissRecoveryPlan saves signature and updates state', () async {
      final entries = [
        const PlannerEntry(
          id: 'e1',
          targetId: 't1',
          targetName: 'Task 1',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 120,
          status: PlannerEntryStatus.pending,
        ),
      ];

      await PlannerService.dismissRecoveryPlan(entries);

      final isDismissed = await PlannerService.isDismissedForState(entries);
      expect(isDismissed, isTrue);

      final state = await PlannerService.loadRecoveryState();
      expect(state, RecoveryState.dismissed);
    });
  });
}
