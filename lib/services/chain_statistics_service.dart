import '../models/mission_chain.dart';
import '../models/mission_chain_history.dart';
import '../models/mission_chain_statistics.dart';

class ChainStatisticsService {
  static MissionChainStatistics recalculateStatistics({
    required List<MissionChainHistory> history,
    required List<MissionChain> chains,
  }) {
    if (history.isEmpty) {
      return const MissionChainStatistics();
    }

    final completedList = history.where((h) => h.status == 'completed').toList();
    final chainsCompleted = completedList.length;

    final totalCompletionRate = history.fold(0.0, (sum, h) => sum + h.completionPercentage);
    final avgCompletionRate = history.isEmpty ? 0.0 : totalCompletionRate / history.length;

    final totalDuration = completedList.fold(0, (sum, h) => sum + h.durationSeconds);
    final avgDurationSeconds = completedList.isEmpty ? 0 : totalDuration ~/ completedList.length;

    // Best & Worst performing chain calculation
    final Map<String, int> successCounts = {};
    final Map<String, int> failureCounts = {};

    for (final item in history) {
      if (item.status == 'completed') {
        successCounts[item.chainName] = (successCounts[item.chainName] ?? 0) + 1;
      } else {
        failureCounts[item.chainName] = (failureCounts[item.chainName] ?? 0) + 1;
      }
    }

    String? bestName;
    int bestCount = 0;
    successCounts.forEach((name, count) {
      if (count > bestCount) {
        bestCount = count;
        bestName = name;
      }
    });

    String? worstName;
    int worstCount = 0;
    failureCounts.forEach((name, count) {
      if (count > worstCount) {
        worstCount = count;
        worstName = name;
      }
    });

    // Consecutive completed chains calculation
    int currentConsecutive = 0;
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i].status == 'completed') {
        currentConsecutive++;
      } else {
        break;
      }
    }

    // Streaks calculation (unique dates with completion)
    final Set<String> completedDates = {};
    for (final h in completedList) {
      final dStr = '${h.date.year}-${h.date.month.toString().padLeft(2, '0')}-${h.date.day.toString().padLeft(2, '0')}';
      completedDates.add(dStr);
    }
    final perfectDays = completedDates.length;

    // Overall current chain streak from chains list
    int currentStreak = 0;
    int longestStreak = 0;
    for (final c in chains) {
      if (c.currentStreak > currentStreak) currentStreak = c.currentStreak;
      if (c.bestStreak > longestStreak) longestStreak = c.bestStreak;
    }

    return MissionChainStatistics(
      chainsCompleted: chainsCompleted,
      currentChainStreak: currentStreak,
      longestChainStreak: longestStreak,
      perfectDays: perfectDays,
      consecutiveCompletedChains: currentConsecutive,
      averageCompletionRate: avgCompletionRate,
      averageDurationSeconds: avgDurationSeconds,
      bestPerformingChainName: bestName,
      mostFailedChainName: worstName,
    );
  }
}
