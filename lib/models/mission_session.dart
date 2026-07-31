import 'target_item.dart';

enum MissionSessionStatus { active, paused, completed, cancelled }

const Object _unchangedSession = Object();

class MissionSession {
  final String id;
  final String targetId;
  final String targetTitle;
  final TargetType targetType;
  final DateTime startTime;
  final DateTime? endTime;
  final int estimatedDurationMinutes;
  final int currentStepIndex;
  final String currentStepTitle;
  final bool isPaused;
  final int accumulatedSeconds;
  final DateTime? lastResumeTime;
  final int interruptionCount;
  final int selectedGoalCount; // Number of problems or items selected for today
  final List<String> selectedItemIds; // Checklist item IDs selected for today
  final int solvedCountDelta; // How many completed during this session
  final MissionSessionStatus status;
  final String notes;
  final String recoveryStatus; // 'normal', 'recovering', 'recovered'

  MissionSession({
    required this.id,
    required this.targetId,
    required this.targetTitle,
    required this.targetType,
    required this.startTime,
    this.endTime,
    required this.estimatedDurationMinutes,
    this.currentStepIndex = 1,
    this.currentStepTitle = 'Focus Execution',
    this.isPaused = false,
    this.accumulatedSeconds = 0,
    this.lastResumeTime,
    this.interruptionCount = 0,
    this.selectedGoalCount = 3,
    this.selectedItemIds = const [],
    this.solvedCountDelta = 0,
    this.status = MissionSessionStatus.active,
    this.notes = '',
    this.recoveryStatus = 'normal',
  });

  factory MissionSession.fromJson(Map<String, dynamic> json) {
    return MissionSession(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      targetTitle: json['targetTitle'] as String? ?? 'Target Execution',
      targetType: TargetType.values.firstWhere(
        (e) => e.name == json['targetType'],
        orElse: () => TargetType.problem,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null ? null : DateTime.parse(json['endTime'] as String),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int? ?? 60,
      currentStepIndex: json['currentStepIndex'] as int? ?? 1,
      currentStepTitle: json['currentStepTitle'] as String? ?? 'Focus Execution',
      isPaused: json['isPaused'] as bool? ?? false,
      accumulatedSeconds: json['accumulatedSeconds'] as int? ?? 0,
      lastResumeTime: json['lastResumeTime'] == null ? null : DateTime.parse(json['lastResumeTime'] as String),
      interruptionCount: json['interruptionCount'] as int? ?? 0,
      selectedGoalCount: json['selectedGoalCount'] as int? ?? 3,
      selectedItemIds: (json['selectedItemIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      solvedCountDelta: json['solvedCountDelta'] as int? ?? 0,
      status: MissionSessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MissionSessionStatus.active,
      ),
      notes: json['notes'] as String? ?? '',
      recoveryStatus: json['recoveryStatus'] as String? ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'targetTitle': targetTitle,
      'targetType': targetType.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'currentStepIndex': currentStepIndex,
      'currentStepTitle': currentStepTitle,
      'isPaused': isPaused,
      'accumulatedSeconds': accumulatedSeconds,
      'lastResumeTime': lastResumeTime?.toIso8601String(),
      'interruptionCount': interruptionCount,
      'selectedGoalCount': selectedGoalCount,
      'selectedItemIds': selectedItemIds,
      'solvedCountDelta': solvedCountDelta,
      'status': status.name,
      'notes': notes,
      'recoveryStatus': recoveryStatus,
    };
  }

  MissionSession copyWith({
    String? targetTitle,
    DateTime? endTime,
    int? currentStepIndex,
    String? currentStepTitle,
    bool? isPaused,
    int? accumulatedSeconds,
    Object? lastResumeTime = _unchangedSession,
    int? interruptionCount,
    int? selectedGoalCount,
    List<String>? selectedItemIds,
    int? solvedCountDelta,
    MissionSessionStatus? status,
    String? notes,
    String? recoveryStatus,
  }) {
    return MissionSession(
      id: id,
      targetId: targetId,
      targetTitle: targetTitle ?? this.targetTitle,
      targetType: targetType,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      estimatedDurationMinutes: estimatedDurationMinutes,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentStepTitle: currentStepTitle ?? this.currentStepTitle,
      isPaused: isPaused ?? this.isPaused,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      lastResumeTime: lastResumeTime == _unchangedSession ? this.lastResumeTime : lastResumeTime as DateTime?,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      selectedGoalCount: selectedGoalCount ?? this.selectedGoalCount,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      solvedCountDelta: solvedCountDelta ?? this.solvedCountDelta,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      recoveryStatus: recoveryStatus ?? this.recoveryStatus,
    );
  }
}
