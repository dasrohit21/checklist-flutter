import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist/providers/app_state.dart';
import 'package:checklist/models/mission.dart';
import 'package:checklist/models/mission_chain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Mission Chains System Tests', () {
    test('Adding and deleting a MissionChain', () async {
      final appState = AppState();
      await appState.addTarget('Target A', 2);
      final target = appState.targets.first;

      final chainItem = MissionChainItem(
        id: '1',
        targetId: target.id,
        name: 'Mission A',
        estimatedDurationMinutes: 30,
        type: MissionType.normal,
        order: 0,
      );

      final chain = MissionChain(
        id: 'chain_1',
        name: 'Morning Routine',
        items: [chainItem],
      );

      await appState.addChain(chain);
      expect(appState.chains.length, equals(1));
      expect(appState.chains.first.name, equals('Morning Routine'));

      await appState.deleteChain('chain_1');
      expect(appState.chains, isEmpty);
    });

    test('Starting a chain unlocks first mission and sets activeChain', () async {
      final appState = AppState();
      await appState.addTarget('Target 1', 1);
      await appState.addTarget('Target 2', 1);
      final t1 = appState.targets[0];
      final t2 = appState.targets[1];

      final chain = MissionChain(
        id: 'chain_routine',
        name: 'Focus Chain',
        items: [
          MissionChainItem(id: 'i1', targetId: t1.id, name: 'Mission 1', estimatedDurationMinutes: 15, type: MissionType.normal, order: 0),
          MissionChainItem(id: 'i2', targetId: t2.id, name: 'Mission 2', estimatedDurationMinutes: 20, type: MissionType.strict, order: 1),
        ],
      );

      await appState.addChain(chain);
      await appState.startChain('chain_routine');

      expect(appState.activeChain, isNotNull);
      expect(appState.activeChain!.status, equals(ChainStatus.active));
      expect(appState.activeChain!.currentMissionIndex, equals(0));
      expect(appState.activeMission, isNotNull);
      expect(appState.activeMission!.name, equals('Mission 1'));
    });

    test('Completing first mission automatically advances and launches second mission', () async {
      final appState = AppState();
      await appState.addTarget('Target 1', 1);
      await appState.addTarget('Target 2', 1);
      final t1 = appState.targets[0];
      final t2 = appState.targets[1];

      final chain = MissionChain(
        id: 'chain_routine_2',
        name: 'Sprint Chain',
        items: [
          MissionChainItem(id: 'i1', targetId: t1.id, name: 'Mission 1', estimatedDurationMinutes: 15, type: MissionType.normal, order: 0),
          MissionChainItem(id: 'i2', targetId: t2.id, name: 'Mission 2', estimatedDurationMinutes: 20, type: MissionType.strict, order: 1),
        ],
      );

      await appState.addChain(chain);
      await appState.startChain('chain_routine_2');

      // Complete Mission 1
      await appState.setSolved(t1.id, 1);

      // Verify auto-progression to Mission 2
      expect(appState.activeChain, isNotNull);
      expect(appState.activeChain!.currentMissionIndex, equals(1));
      expect(appState.activeMission, isNotNull);
      expect(appState.activeMission!.name, equals('Mission 2'));
    });

    test('Completing final mission finishes chain, awards bonus XP, and triggers celebration', () async {
      final appState = AppState();
      await appState.addTarget('Single Target', 1);
      final t1 = appState.targets.first;

      final chain = MissionChain(
        id: 'chain_single',
        name: 'Quick Chain',
        items: [
          MissionChainItem(id: 'i1', targetId: t1.id, name: 'Mission 1', estimatedDurationMinutes: 15, type: MissionType.normal, order: 0),
        ],
      );

      await appState.addChain(chain);
      await appState.startChain('chain_single');

      final xpBefore = appState.totalXp;
      // Complete Mission 1 (final)
      await appState.setSolved(t1.id, 1);

      expect(appState.activeChain, isNull);
      expect(appState.celebratingChain, isNotNull);
      expect(appState.celebratingChain!.name, equals('Quick Chain'));
      expect(appState.totalXp, greaterThan(xpBefore + 300)); // Base XP + 300 Chain Bonus
      expect(appState.chainHistory.length, equals(1));
      expect(appState.chainHistory.first.status, equals('completed'));
    });

    test('Abandoning a chain marks it as abandoned and updates discipline score', () async {
      final appState = AppState();
      await appState.addTarget('Target A', 5);
      final t1 = appState.targets.first;

      final chain = MissionChain(
        id: 'chain_abandon',
        name: 'Hard Routine',
        items: [
          MissionChainItem(id: 'i1', targetId: t1.id, name: 'Mission 1', estimatedDurationMinutes: 30, type: MissionType.ultimate, order: 0),
        ],
      );

      await appState.addChain(chain);
      await appState.startChain('chain_abandon');

      final initialDiscipline = appState.disciplineScore;
      await appState.abandonActiveChain();

      expect(appState.activeChain, isNull);
      expect(appState.disciplineScore, equals(initialDiscipline - 15));
      expect(appState.chainHistory.length, equals(1));
      expect(appState.chainHistory.first.status, equals('abandoned'));
    });
  });
}
