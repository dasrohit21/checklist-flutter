import 'checklist_item.dart';

enum TargetType { problem, checklist }

const Object _unchanged = Object();

class TargetLink {
  final String title;
  final String url;

  TargetLink({required this.title, required this.url});

  factory TargetLink.fromJson(Map<String, dynamic> json) {
    return TargetLink(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
    };
  }
}

class TargetItem {
  TargetItem({
    required this.id,
    required this.title,
    required this.targetCount,
    this.solvedCount = 0,
    this.type = TargetType.problem,
    this.difficulty = 'Medium',
    this.isFocused = false,
    this.dueDate,
    this.priority = 'medium', // 'high', 'medium', 'low'
    this.notes = '',
    this.tags = const [],
    this.categoryId,
    this.categoryName,
    this.links = const [],
    this.checklistSubItems = const [],
  });

  final String id;
  final String title;
  final int targetCount;
  final int solvedCount;
  final TargetType type;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final bool isFocused;
  final DateTime? dueDate;
  final String priority;
  final String notes;
  final List<String> tags;
  final String? categoryId;
  final String? categoryName;
  final List<TargetLink> links;
  final List<ChecklistItem> checklistSubItems;

  double get progress {
    if (type == TargetType.checklist && checklistSubItems.isNotEmpty) {
      final done = checklistSubItems.where((i) => i.completed).length;
      return (done / checklistSubItems.length).clamp(0.0, 1.0);
    }
    if (targetCount == 0) return 0.0;
    return (solvedCount / targetCount).clamp(0.0, 1.0);
  }

  bool get isCompleted => progress >= 1.0;

  int get effectiveTotalCount {
    if (type == TargetType.checklist && checklistSubItems.isNotEmpty) {
      return checklistSubItems.length;
    }
    return targetCount;
  }

  int get effectiveSolvedCount {
    if (type == TargetType.checklist && checklistSubItems.isNotEmpty) {
      return checklistSubItems.where((i) => i.completed).length;
    }
    return solvedCount;
  }

  factory TargetItem.fromJson(Map<String, dynamic> json) {
    TargetType parsedType = TargetType.problem;
    if (json['type'] != null) {
      if (json['type'] == 'checklist' || json['type'] == TargetType.checklist.name) {
        parsedType = TargetType.checklist;
      }
    }

    return TargetItem(
      id: json['id'] as String,
      title: json['title'] as String,
      targetCount: json['targetCount'] as int? ?? 1,
      solvedCount: json['solvedCount'] as int? ?? 0,
      type: parsedType,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      isFocused: json['isFocused'] as bool? ?? false,
      dueDate: json['dueDate'] == null ? null : DateTime.tryParse(json['dueDate'] as String),
      priority: json['priority'] as String? ?? 'medium',
      notes: json['notes'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => TargetLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checklistSubItems: (json['checklistSubItems'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetCount': targetCount,
      'solvedCount': solvedCount,
      'type': type.name,
      'difficulty': difficulty,
      'isFocused': isFocused,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'notes': notes,
      'tags': tags,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'links': links.map((l) => l.toJson()).toList(),
      'checklistSubItems': checklistSubItems.map((c) => c.toJson()).toList(),
    };
  }

  TargetItem copyWith({
    String? title,
    int? targetCount,
    int? solvedCount,
    TargetType? type,
    String? difficulty,
    bool? isFocused,
    Object? dueDate = _unchanged,
    String? priority,
    String? notes,
    List<String>? tags,
    Object? categoryId = _unchanged,
    Object? categoryName = _unchanged,
    List<TargetLink>? links,
    List<ChecklistItem>? checklistSubItems,
  }) {
    return TargetItem(
      id: id,
      title: title ?? this.title,
      targetCount: targetCount ?? this.targetCount,
      solvedCount: solvedCount ?? this.solvedCount,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      isFocused: isFocused ?? this.isFocused,
      dueDate: dueDate == _unchanged ? this.dueDate : dueDate as DateTime?,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      categoryId: categoryId == _unchanged ? this.categoryId : categoryId as String?,
      categoryName: categoryName == _unchanged ? this.categoryName : categoryName as String?,
      links: links ?? this.links,
      checklistSubItems: checklistSubItems ?? this.checklistSubItems,
    );
  }
}

