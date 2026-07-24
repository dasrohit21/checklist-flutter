import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist/models/planner_entry.dart';
import 'package:checklist/services/planner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Adaptive Planner Engine Unit Tests', () {
    test('sortPlanner orders entries by Priority rules (P1 > P2 > P3 > P4 > P5)', () {
      final entries = [
        const PlannerEntry(
          id: 'e1',
          targetId: 't1',
          targetName: 'Low Priority Task',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 30,
          priority: 'low',
        ),
        const PlannerEntry(
          id: 'e2',
          targetId: 't2',
          targetName: 'High Priority Task',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
          priority: 'high',
        ),
        const PlannerEntry(
          id: 'e3',
          targetId: 't3',
          targetName: 'In Progress Task',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 45,
          status: PlannerEntryStatus.inProgress,
          priority: 'low',
        ),
        const PlannerEntry(
          id: 'e4',
          targetId: 't4',
          targetName: 'Carry Forward Task',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 90,
          isCarryForward: true,
          priority: 'low',
        ),
        const PlannerEntry(
          id: 'e5',
          targetId: 't5',
          targetName: 'Normal Priority Task',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
          priority: 'normal',
        ),
      ];

      final sorted = PlannerService.sortPlanner(entries);

      expect(sorted[0].id, 'e3'); // Priority 1: In Progress
      expect(sorted[1].id, 'e4'); // Priority 2: Carry Forward
      expect(sorted[2].id, 'e2'); // Priority 3: High Priority
      expect(sorted[3].id, 'e5'); // Priority 4: Normal Priority
      expect(sorted[4].id, 'e1'); // Priority 5: Low Priority
    });

    test('recommendFirstMission enforces "Continue First" rule', () {
      final entries = [
        const PlannerEntry(
          id: 'e1',
          targetId: 't1',
          targetName: 'High Priority Pending',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
          priority: 'high',
        ),
        const PlannerEntry(
          id: 'e2',
          targetId: 't2',
          targetName: 'Active Flutter Authentication',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 90,
          status: PlannerEntryStatus.inProgress,
          priority: 'normal',
        ),
      ];

      final recommended = PlannerService.recommendFirstMission(entries);
      expect(recommended, isNotNull);
      expect(recommended!.id, 'e2');
      expect(recommended.targetName, 'Active Flutter Authentication');
    });

    test('generateTomorrowPlan deduplicates and sorts tomorrow entries', () async {
      final initialTomorrow = [
        PlannerEntry(
          id: 'tm1',
          targetId: 't1',
          targetName: 'Tomorrow Normal Task',
          scheduledDate: PlannerService.tomorrowStr,
          estimatedDurationMinutes: 60,
          priority: 'normal',
        ),
      ];
      await PlannerService.saveTomorrowEntries(initialTomorrow);

      final additional = [
        PlannerEntry(
          id: 'tm2',
          targetId: 't1', // Duplicate targetId
          targetName: 'Tomorrow Duplicate Task',
          scheduledDate: PlannerService.tomorrowStr,
          estimatedDurationMinutes: 60,
        ),
        PlannerEntry(
          id: 'tm3',
          targetId: 't2',
          targetName: 'Tomorrow High Task',
          scheduledDate: PlannerService.tomorrowStr,
          estimatedDurationMinutes: 120,
          priority: 'high',
        ),
      ];

      final result = await PlannerService.generateTomorrowPlan(additionalEntries: additional);

      expect(result.length, 2); // Duplicate t1 ignored
      expect(result.first.targetId, 't2'); // High priority sorted first
    });

    test('Quick Actions (moveTomorrowEntryUp, moveTomorrowEntryDown, moveTomorrowEntryToToday, removeTomorrowEntry)', () async {
      final entries = [
        PlannerEntry(
          id: 'item1',
          targetId: 't1',
          targetName: 'Item 1',
          scheduledDate: PlannerService.tomorrowStr,
          estimatedDurationMinutes: 30,
        ),
        PlannerEntry(
          id: 'item2',
          targetId: 't2',
          targetName: 'Item 2',
          scheduledDate: PlannerService.tomorrowStr,
          estimatedDurationMinutes: 45,
        ),
      ];
      await PlannerService.saveTomorrowEntries(entries);

      // Move item2 up
      await PlannerService.moveTomorrowEntryUp('item2');
      var tomorrowList = await PlannerService.loadTomorrowEntries();
      expect(tomorrowList.first.id, 'item2');

      // Move item2 down
      await PlannerService.moveTomorrowEntryDown('item2');
      tomorrowList = await PlannerService.loadTomorrowEntries();
      expect(tomorrowList.first.id, 'item1');

      // Move item1 to today
      await PlannerService.moveTomorrowEntryToToday('item1');
      tomorrowList = await PlannerService.loadTomorrowEntries();
      final todayList = await PlannerService.loadTodayEntries();
      expect(tomorrowList.length, 1);
      expect(todayList.any((e) => e.id == 'item1'), isTrue);

      // Remove item2
      await PlannerService.removeTomorrowEntry('item2');
      tomorrowList = await PlannerService.loadTomorrowEntries();
      expect(tomorrowList.isEmpty, isTrue);
    });

    test('calculateTomorrowWorkload computes total non-completed minutes for tomorrow', () async {
      final tomorrowEntries = [
        PlannerEntry(
          id: 'tm1',
          targetId: 't1',
          targetName: 'Task 1',
          scheduledDate: PlannerService.tomorrowStr,
          estimatedDurationMinutes: 90,
        ),
        PlannerEntry(
          id: 'tm2',
          targetId: 't2',
          targetName: 'Task 2',
          scheduledDate: PlannerService.tomorrowStr,
          estimatedDurationMinutes: 150,
        ),
      ];
      await PlannerService.saveTomorrowEntries(tomorrowEntries);

      final workload = await PlannerService.calculateTomorrowWorkload();
      expect(workload, 240); // 90 + 150
    });
  });
}
