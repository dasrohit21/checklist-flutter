class MissionChainHistory {
  final String id;
  final String chainId;
  final String chainName;
  final DateTime date;
  final double completionPercentage;
  final int durationSeconds;
  final int completedMissions;
  final int skippedMissions;
  final int interruptions;
  final int xpEarned;
  final String status; // 'completed', 'failed', 'abandoned'

  const MissionChainHistory({
    required this.id,
    required this.chainId,
    required this.chainName,
    required this.date,
    required this.completionPercentage,
    required this.durationSeconds,
    required this.completedMissions,
    required this.skippedMissions,
    required this.interruptions,
    required this.xpEarned,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chainId': chainId,
      'chainName': chainName,
      'date': date.toIso8601String(),
      'completionPercentage': completionPercentage,
      'durationSeconds': durationSeconds,
      'completedMissions': completedMissions,
      'skippedMissions': skippedMissions,
      'interruptions': interruptions,
      'xpEarned': xpEarned,
      'status': status,
    };
  }

  factory MissionChainHistory.fromJson(Map<String, dynamic> json) {
    return MissionChainHistory(
      id: json['id'] as String,
      chainId: json['chainId'] as String,
      chainName: json['chainName'] as String,
      date: DateTime.parse(json['date'] as String),
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      completedMissions: json['completedMissions'] as int,
      skippedMissions: json['skippedMissions'] as int,
      interruptions: json['interruptions'] as int,
      xpEarned: json['xpEarned'] as int,
      status: json['status'] as String,
    );
  }
}
