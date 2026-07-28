/// Workspace metadata and session tracking for a specific mission target.
class MissionWorkspaceData {
  final String targetId;
  final DateTime? notesLastEdited;
  final int totalSessions;
  final int totalElapsedSeconds;
  final int recoveryCount;
  final int postponementCount;
  final int longestPauseSeconds;

  const MissionWorkspaceData({
    required this.targetId,
    this.notesLastEdited,
    this.totalSessions = 0,
    this.totalElapsedSeconds = 0,
    this.recoveryCount = 0,
    this.postponementCount = 0,
    this.longestPauseSeconds = 0,
  });

  factory MissionWorkspaceData.empty(String targetId) => MissionWorkspaceData(
        targetId: targetId,
      );

  Map<String, dynamic> toJson() => {
        'targetId': targetId,
        'notesLastEdited': notesLastEdited?.toIso8601String(),
        'totalSessions': totalSessions,
        'totalElapsedSeconds': totalElapsedSeconds,
        'recoveryCount': recoveryCount,
        'postponementCount': postponementCount,
        'longestPauseSeconds': longestPauseSeconds,
      };

  factory MissionWorkspaceData.fromJson(Map<String, dynamic> json) =>
      MissionWorkspaceData(
        targetId: json['targetId'] as String? ?? '',
        notesLastEdited: json['notesLastEdited'] == null
            ? null
            : DateTime.tryParse(json['notesLastEdited'] as String),
        totalSessions: json['totalSessions'] as int? ?? 0,
        totalElapsedSeconds: json['totalElapsedSeconds'] as int? ?? 0,
        recoveryCount: json['recoveryCount'] as int? ?? 0,
        postponementCount: json['postponementCount'] as int? ?? 0,
        longestPauseSeconds: json['longestPauseSeconds'] as int? ?? 0,
      );

  MissionWorkspaceData copyWith({
    Object? notesLastEdited = const Object(),
    int? totalSessions,
    int? totalElapsedSeconds,
    int? recoveryCount,
    int? postponementCount,
    int? longestPauseSeconds,
  }) {
    return MissionWorkspaceData(
      targetId: targetId,
      notesLastEdited: notesLastEdited == const Object()
          ? this.notesLastEdited
          : notesLastEdited as DateTime?,
      totalSessions: totalSessions ?? this.totalSessions,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      recoveryCount: recoveryCount ?? this.recoveryCount,
      postponementCount: postponementCount ?? this.postponementCount,
      longestPauseSeconds: longestPauseSeconds ?? this.longestPauseSeconds,
    );
  }
}
