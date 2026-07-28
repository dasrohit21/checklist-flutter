import 'mission.dart';

enum ChainRepeatOption {
  oneTime,
  daily,
  weekdays,
  weekly,
  custom,
}

enum ChainStatus {
  idle,
  active,
  paused,
  completed,
  failed,
  abandoned,
}

class MissionChainItem {
  final String id;
  final String targetId;
  final String name;
  final int estimatedDurationMinutes;
  final MissionType type;
  final int order;
  final bool isCompleted;
  final bool isLocked;

  const MissionChainItem({
    required this.id,
    required this.targetId,
    required this.name,
    required this.estimatedDurationMinutes,
    required this.type,
    required this.order,
    this.isCompleted = false,
    this.isLocked = true,
  });

  MissionChainItem copyWith({
    String? id,
    String? targetId,
    String? name,
    int? estimatedDurationMinutes,
    MissionType? type,
    int? order,
    bool? isCompleted,
    bool? isLocked,
  }) {
    return MissionChainItem(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      name: name ?? this.name,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      type: type ?? this.type,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'name': name,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'type': type.name,
      'order': order,
      'isCompleted': isCompleted,
      'isLocked': isLocked,
    };
  }

  factory MissionChainItem.fromJson(Map<String, dynamic> json) {
    return MissionChainItem(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      name: json['name'] as String,
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int? ?? 30,
      type: MissionType.values.firstWhere(
        (e) => e.name == (json['type'] as String?),
        orElse: () => MissionType.normal,
      ),
      order: json['order'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? true,
    );
  }
}

class MissionChain {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final String description;
  final ChainRepeatOption repeatOption;
  final List<int> customDays;
  final List<MissionChainItem> items;
  final int currentMissionIndex;
  final ChainStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int currentStreak;
  final int bestStreak;
  final String? lastCompletionDate;

  const MissionChain({
    required this.id,
    required this.name,
    this.iconName = 'routine',
    this.colorHex = '0xFF6366F1',
    this.description = '',
    this.repeatOption = ChainRepeatOption.daily,
    this.customDays = const [],
    required this.items,
    this.currentMissionIndex = 0,
    this.status = ChainStatus.idle,
    this.startTime,
    this.endTime,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletionDate,
  });

  int get totalMissions => items.length;

  int get completedMissionsCount => items.where((i) => i.isCompleted).length;

  double get completionPercentage {
    if (items.isEmpty) return 0.0;
    return completedMissionsCount / items.length;
  }

  int get estimatedTotalDurationMinutes {
    return items.fold(0, (sum, i) => sum + i.estimatedDurationMinutes);
  }

  int get xpReward {
    // 100 XP per mission + 300 XP Chain Bonus
    return (items.length * 100) + 300;
  }

  bool get isFinished =>
      status == ChainStatus.completed ||
      status == ChainStatus.failed ||
      status == ChainStatus.abandoned;

  /// Alias for [name] — provided for backward compatibility.
  String get title => name;

  /// All target IDs referenced in this chain's items.
  List<String> get targetIds => items.map((i) => i.targetId).toList();

  /// Target IDs of items that have been completed.
  List<String> get completedTargetIds =>
      items.where((i) => i.isCompleted).map((i) => i.targetId).toList();

  MissionChain copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    String? description,
    ChainRepeatOption? repeatOption,
    List<int>? customDays,
    List<MissionChainItem>? items,
    int? currentMissionIndex,
    ChainStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? currentStreak,
    int? bestStreak,
    String? lastCompletionDate,
  }) {
    return MissionChain(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      description: description ?? this.description,
      repeatOption: repeatOption ?? this.repeatOption,
      customDays: customDays ?? this.customDays,
      items: items ?? this.items,
      currentMissionIndex: currentMissionIndex ?? this.currentMissionIndex,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
      'description': description,
      'repeatOption': repeatOption.name,
      'customDays': customDays,
      'items': items.map((i) => i.toJson()).toList(),
      'currentMissionIndex': currentMissionIndex,
      'status': status.name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletionDate': lastCompletionDate,
    };
  }

  factory MissionChain.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return MissionChain(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['iconName'] as String? ?? 'routine',
      colorHex: json['colorHex'] as String? ?? '0xFF6366F1',
      description: json['description'] as String? ?? '',
      repeatOption: ChainRepeatOption.values.firstWhere(
        (e) => e.name == (json['repeatOption'] as String?),
        orElse: () => ChainRepeatOption.daily,
      ),
      customDays: (json['customDays'] as List<dynamic>?)?.cast<int>() ?? const [],
      items: rawItems.map((i) => MissionChainItem.fromJson(i as Map<String, dynamic>)).toList(),
      currentMissionIndex: json['currentMissionIndex'] as int? ?? 0,
      status: ChainStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => ChainStatus.idle,
      ),
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime'] as String) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'] as String) : null,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastCompletionDate: json['lastCompletionDate'] as String?,
    );
  }
}
