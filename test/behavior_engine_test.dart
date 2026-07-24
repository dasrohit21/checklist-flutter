import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist/models/daily_history_log.dart';
import 'package:checklist/models/mission_behavior_analysis.dart';
import 'package:checklist/models/planner_entry.dart';
import 'package:checklist/services/behavior_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Behavior Intelligence Engine Unit Tests', () {
    test('calculateMissionHealth computes correct health score levels', () {
      final excellent = BehaviorService.calculateMissionHealth(
        completionPercentage: 0.90,
        postponementsCount: 0,
        daysSinceActivity: 1,
        recoveriesCount: 0,
      );
      expect(excellent, MissionHealthStatus.excellent);

      final warning = BehaviorService.calculateMissionHealth(
        completionPercentage: 0.50,
        postponementsCount: 3,
        daysSinceActivity: 2,
        recoveriesCount: 1,
      );
      expect(warning, MissionHealthStatus.warning);

      final critical = BehaviorService.calculateMissionHealth(
        completionPercentage: 0.20,
        postponementsCount: 6,
        daysSinceActivity: 8,
        recoveriesCount: 2,
      );
      expect(critical, MissionHealthStatus.critical);
    });

    test('analyzeBehavior generates health map, insights, and recommendations', () {
      const history = [
        DailyHistoryLog(
          date: '2026-07-24',
          plannedMissionsCount: 2,
          completedMissionsCount: 1,
          carryForwardCount: 1,
          totalEstimatedWorkloadMinutes: 120,
          totalCompletedWorkloadMinutes: 90,
          actualCompletionTimeMinutes: 90,
          availableWorkingTimeMinutes: 360,
          missionLogs: [
            MissionExecutionLog(
              missionId: 'm1',
              targetId: 't1',
              targetName: 'Flutter State',
              categoryId: 'Flutter',
              durationMinutes: 90,
              estimatedMinutes: 60,
              status: 'completed',
            ),
            MissionExecutionLog(
              missionId: 'm2',
              targetId: 't2',
              targetName: 'DSA Graph',
              categoryId: 'DSA',
              durationMinutes: 0,
              estimatedMinutes: 60,
              status: 'postponed',
            ),
          ],
        ),
      ];

      const todayEntries = [
        PlannerEntry(
          id: 'p1',
          targetId: 't2',
          targetName: 'DSA Graph',
          scheduledDate: '2026-07-24',
          estimatedDurationMinutes: 60,
          isCarryForward: true,
        ),
      ];

      final summary = BehaviorService.analyzeBehavior(
        history: history,
        todayEntries: todayEntries,
        tomorrowEntries: const [],
      );

      expect(summary.missionHealthMap.containsKey('t1'), isTrue);
      expect(summary.missionHealthMap.containsKey('t2'), isTrue);

      final dsaHealth = summary.missionHealthMap['t2']!;
      expect(dsaHealth.postponementsCount, 2);
      expect(summary.lastAnalyzed, isNotNull);
    });

    test('BehaviorService persistence for behavior summary', () async {
      const history = <DailyHistoryLog>[];
      final summary = BehaviorService.analyzeBehavior(
        history: history,
        todayEntries: const [],
        tomorrowEntries: const [],
      );

      await BehaviorService.saveSummary(summary);
      final loaded = await BehaviorService.loadSummary();

      expect(loaded.lastAnalyzed, isNotNull);
    });
  });
}
