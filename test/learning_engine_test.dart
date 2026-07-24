import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist/models/daily_history_log.dart';
import 'package:checklist/services/learning_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Learning Engine Unit Tests', () {
    test('calculateStatistics computes completion rate, streak, and best working period', () {
      const history = [
        DailyHistoryLog(
          date: '2026-07-22',
          plannedMissionsCount: 2,
          completedMissionsCount: 2,
          carryForwardCount: 0,
          totalEstimatedWorkloadMinutes: 120,
          totalCompletedWorkloadMinutes: 110,
          actualCompletionTimeMinutes: 110,
          availableWorkingTimeMinutes: 360,
          missionLogs: [
            MissionExecutionLog(
              missionId: 'm1',
              targetId: 't1',
              targetName: 'Flutter Task',
              categoryId: 'Flutter',
              durationMinutes: 60,
              estimatedMinutes: 60,
              timeOfDayBucket: 'morning',
              status: 'completed',
            ),
            MissionExecutionLog(
              missionId: 'm2',
              targetId: 't2',
              targetName: 'Reading Task',
              categoryId: 'Reading',
              durationMinutes: 50,
              estimatedMinutes: 60,
              timeOfDayBucket: 'morning',
              status: 'completed',
            ),
          ],
        ),
        DailyHistoryLog(
          date: '2026-07-23',
          plannedMissionsCount: 2,
          completedMissionsCount: 1,
          carryForwardCount: 1,
          totalEstimatedWorkloadMinutes: 100,
          totalCompletedWorkloadMinutes: 60,
          actualCompletionTimeMinutes: 60,
          availableWorkingTimeMinutes: 360,
          missionLogs: [
            MissionExecutionLog(
              missionId: 'm3',
              targetId: 't3',
              targetName: 'Gym Task',
              categoryId: 'Gym',
              durationMinutes: 60,
              estimatedMinutes: 60,
              timeOfDayBucket: 'afternoon',
              status: 'completed',
            ),
          ],
        ),
      ];

      final stats = LearningService.calculateStatistics(history);

      expect(stats.avgCompletionRate, 0.75); // (1.0 + 0.5) / 2 = 0.75 (75%)
      expect(stats.bestWorkingPeriod, 'Morning'); // 2 morning missions vs 1 afternoon
      expect(stats.longestStreakDays, 2);
      expect(stats.avgCategoryDurationMinutes['Flutter'], 60);
      expect(stats.avgCategoryDurationMinutes['Reading'], 50);
    });

    test('generateInsights produces fact-backed insights only from historical data', () {
      const history = [
        DailyHistoryLog(
          date: '2026-07-24',
          plannedMissionsCount: 3,
          completedMissionsCount: 3,
          carryForwardCount: 0,
          totalEstimatedWorkloadMinutes: 180,
          totalCompletedWorkloadMinutes: 210,
          actualCompletionTimeMinutes: 210,
          availableWorkingTimeMinutes: 360,
          missionLogs: [
            MissionExecutionLog(
              missionId: 'm1',
              targetId: 't1',
              targetName: 'Flutter State',
              categoryId: 'Flutter',
              durationMinutes: 90,
              estimatedMinutes: 60,
              timeOfDayBucket: 'morning',
              status: 'completed',
            ),
          ],
        ),
      ];

      final stats = LearningService.calculateStatistics(history);
      final insights = LearningService.generateInsights(history, stats);

      expect(insights.isNotEmpty, isTrue);
      expect(insights.any((i) => i.contains('morning')), isTrue);
      expect(insights.any((i) => i.contains('completion rate')), isTrue);
    });

    test('LearningService persistence for daily history logs', () async {
      const log = DailyHistoryLog(
        date: '2026-07-24',
        plannedMissionsCount: 1,
        completedMissionsCount: 1,
        carryForwardCount: 0,
        totalEstimatedWorkloadMinutes: 60,
        totalCompletedWorkloadMinutes: 60,
        actualCompletionTimeMinutes: 60,
        availableWorkingTimeMinutes: 360,
      );

      await LearningService.recordDailySnapshot(log);
      final loaded = await LearningService.loadHistory();

      expect(loaded.length, 1);
      expect(loaded.first.date, '2026-07-24');
    });
  });
}
