/// Aggregated pattern statistics computed by the Learning Engine.
class LearningStatistics {
  final double avgCompletionRate;
  final int avgPlanningAccuracyMinutes; // difference: actual - estimated
  final String bestWorkingPeriod; // 'Morning', 'Afternoon', 'Evening', 'Night'
  final Map<String, int> avgCategoryDurationMinutes;
  final Map<String, Map<String, int>> categoryFrequency; // {category: {completed, postponed, abandoned}}
  final int longestStreakDays;
  final Map<String, int> longestPostponementDays;
  final int totalRecoveryAccepted;
  final int totalRecoveryDismissed;

  const LearningStatistics({
    required this.avgCompletionRate,
    required this.avgPlanningAccuracyMinutes,
    required this.bestWorkingPeriod,
    required this.avgCategoryDurationMinutes,
    required this.categoryFrequency,
    required this.longestStreakDays,
    required this.longestPostponementDays,
    required this.totalRecoveryAccepted,
    required this.totalRecoveryDismissed,
  });

  factory LearningStatistics.empty() => const LearningStatistics(
        avgCompletionRate: 0.0,
        avgPlanningAccuracyMinutes: 0,
        bestWorkingPeriod: 'Morning',
        avgCategoryDurationMinutes: {},
        categoryFrequency: {},
        longestStreakDays: 0,
        longestPostponementDays: {},
        totalRecoveryAccepted: 0,
        totalRecoveryDismissed: 0,
      );
}

/// Aggregated output from the Learning Engine combining statistics and fact-backed insights.
class LearningSummary {
  final LearningStatistics statistics;
  final List<String> insights;

  const LearningSummary({
    required this.statistics,
    required this.insights,
  });

  factory LearningSummary.empty() => LearningSummary(
        statistics: LearningStatistics.empty(),
        insights: const [],
      );
}
