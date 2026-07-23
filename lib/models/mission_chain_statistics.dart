class MissionChainStatistics {
  final int chainsCompleted;
  final int currentChainStreak;
  final int longestChainStreak;
  final int perfectDays;
  final int consecutiveCompletedChains;
  final double averageCompletionRate;
  final int averageDurationSeconds;
  final String? bestPerformingChainName;
  final String? mostFailedChainName;

  const MissionChainStatistics({
    this.chainsCompleted = 0,
    this.currentChainStreak = 0,
    this.longestChainStreak = 0,
    this.perfectDays = 0,
    this.consecutiveCompletedChains = 0,
    this.averageCompletionRate = 0.0,
    this.averageDurationSeconds = 0,
    this.bestPerformingChainName,
    this.mostFailedChainName,
  });

  MissionChainStatistics copyWith({
    int? chainsCompleted,
    int? currentChainStreak,
    int? longestChainStreak,
    int? perfectDays,
    int? consecutiveCompletedChains,
    double? averageCompletionRate,
    int? averageDurationSeconds,
    String? bestPerformingChainName,
    String? mostFailedChainName,
  }) {
    return MissionChainStatistics(
      chainsCompleted: chainsCompleted ?? this.chainsCompleted,
      currentChainStreak: currentChainStreak ?? this.currentChainStreak,
      longestChainStreak: longestChainStreak ?? this.longestChainStreak,
      perfectDays: perfectDays ?? this.perfectDays,
      consecutiveCompletedChains: consecutiveCompletedChains ?? this.consecutiveCompletedChains,
      averageCompletionRate: averageCompletionRate ?? this.averageCompletionRate,
      averageDurationSeconds: averageDurationSeconds ?? this.averageDurationSeconds,
      bestPerformingChainName: bestPerformingChainName ?? this.bestPerformingChainName,
      mostFailedChainName: mostFailedChainName ?? this.mostFailedChainName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chainsCompleted': chainsCompleted,
      'currentChainStreak': currentChainStreak,
      'longestChainStreak': longestChainStreak,
      'perfectDays': perfectDays,
      'consecutiveCompletedChains': consecutiveCompletedChains,
      'averageCompletionRate': averageCompletionRate,
      'averageDurationSeconds': averageDurationSeconds,
      'bestPerformingChainName': bestPerformingChainName,
      'mostFailedChainName': mostFailedChainName,
    };
  }

  factory MissionChainStatistics.fromJson(Map<String, dynamic> json) {
    return MissionChainStatistics(
      chainsCompleted: json['chainsCompleted'] as int? ?? 0,
      currentChainStreak: json['currentChainStreak'] as int? ?? 0,
      longestChainStreak: json['longestChainStreak'] as int? ?? 0,
      perfectDays: json['perfectDays'] as int? ?? 0,
      consecutiveCompletedChains: json['consecutiveCompletedChains'] as int? ?? 0,
      averageCompletionRate: (json['averageCompletionRate'] as num?)?.toDouble() ?? 0.0,
      averageDurationSeconds: json['averageDurationSeconds'] as int? ?? 0,
      bestPerformingChainName: json['bestPerformingChainName'] as String?,
      mostFailedChainName: json['mostFailedChainName'] as String?,
    );
  }
}
