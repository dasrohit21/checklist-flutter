import 'mission.dart';

class MissionHistoryItem {
  final String id;
  final String targetId;
  final String name;
  final MissionType type;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final int problemsSolved;
  final int interruptions;
  final String status; // 'completed' or 'abandoned'
  final int xpEarned;
  final int focusScore;

  MissionHistoryItem({
    required this.id,
    this.targetId = '',
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.problemsSolved,
    required this.interruptions,
    required this.status,
    required this.xpEarned,
    required this.focusScore,
  });

  factory MissionHistoryItem.fromJson(Map<String, dynamic> json) {
    return MissionHistoryItem(
      id: json['id'] as String,
      targetId: json['targetId'] as String? ?? '',
      name: json['name'] as String,
      type: MissionType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => MissionType.normal,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationSeconds: json['durationSeconds'] as int,
      problemsSolved: json['problemsSolved'] as int,
      interruptions: json['interruptions'] as int,
      status: json['status'] as String,
      xpEarned: json['xpEarned'] as int? ?? 0,
      focusScore: json['focusScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'name': name,
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'problemsSolved': problemsSolved,
      'interruptions': interruptions,
      'status': status,
      'xpEarned': xpEarned,
      'focusScore': focusScore,
    };
  }
}

