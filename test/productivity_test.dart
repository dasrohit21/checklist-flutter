import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist/providers/app_state.dart';
import 'package:checklist/models/mission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppState Productivity System Tests', () {
    test('Initial productivity values default correctly', () {
      final appState = AppState();
      expect(appState.totalXp, equals(0));
      expect(appState.level, equals(1));
      expect(appState.disciplineScore, equals(75));
      expect(appState.missionHistory, isEmpty);
      expect(appState.unlockedAchievementIds, isEmpty);
    });

    test('Starting a mission initializes activeMission correctly', () async {
      final appState = AppState();
      await appState.addTarget('Solve 5 LeetCode Problems', 5);
      final target = appState.targets.first;

      await appState.startMission(
        target.id,
        'LeetCode Sprint',
        30,
        MissionType.normal,
      );

      expect(appState.activeMission, isNotNull);
      expect(appState.activeMission!.name, equals('LeetCode Sprint'));
      expect(appState.activeMission!.type, equals(MissionType.normal));
      expect(appState.activeMission!.status, equals(MissionStatus.active));
      expect(appState.activeMission!.isPaused, isFalse);
    });

    test('Pausing and resuming active mission tracks interruptions', () async {
      final appState = AppState();
      await appState.addTarget('Test Target', 5);
      final target = appState.targets.first;

      await appState.startMission(target.id, 'Test Mission', 30, MissionType.normal);
      expect(appState.activeMission!.interruptionCount, equals(0));

      await appState.pauseActiveMission();
      expect(appState.activeMission!.isPaused, isTrue);
      expect(appState.activeMission!.interruptionCount, equals(1));

      await appState.resumeActiveMission();
      expect(appState.activeMission!.isPaused, isFalse);
    });

    test('Completing a mission awards XP, updates scores, and records history', () async {
      final appState = AppState();
      await appState.addTarget('Math Problems', 2);
      final target = appState.targets.first;

      await appState.startMission(target.id, 'Math Sprint', 60, MissionType.strict);
      
      // Complete all items in mission
      await appState.setSolved(target.id, 1);
      await appState.setSolved(target.id, 2);

      expect(appState.activeMission!.status, equals(MissionStatus.completed));
      expect(appState.totalXp, greaterThan(0));
      expect(appState.disciplineScore, greaterThanOrEqualTo(75));
      expect(appState.missionHistory.length, equals(1));
      expect(appState.missionHistory.first.status, equals('completed'));
      expect(appState.unlockedAchievementIds, contains('first_mission'));
    });

    test('Abandoning a mission decrements discipline score', () async {
      final appState = AppState();
      await appState.addTarget('Physics Revision', 3);
      final target = appState.targets.first;

      await appState.startMission(target.id, 'Physics Session', 45, MissionType.ultimate);
      final initialDiscipline = appState.disciplineScore;

      await appState.clearActiveMission();
      
      expect(appState.activeMission, isNull);
      expect(appState.disciplineScore, equals(initialDiscipline - 15));
      expect(appState.missionHistory.length, equals(1));
      expect(appState.missionHistory.first.status, equals('abandoned'));
    });

    test('Preferences switches update correctly', () async {
      final appState = AppState();
      expect(appState.xpPopupsEnabled, isTrue);
      expect(appState.soundsEnabled, isTrue);
      expect(appState.notificationsEnabled, isTrue);

      await appState.setXpPopupsEnabled(false);
      await appState.setSoundsEnabled(false);
      await appState.setNotificationsEnabled(false);
      await appState.setDefaultEstimatedDurationMinutes(45);

      expect(appState.xpPopupsEnabled, isFalse);
      expect(appState.soundsEnabled, isFalse);
      expect(appState.notificationsEnabled, isFalse);
      expect(appState.defaultEstimatedDurationMinutes, equals(45));
    });
  });
}
