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
    this.isFocused = false,
    this.dueDate,
    this.priority = 'medium', // 'high', 'medium', 'low'
    this.notes = '',
    this.tags = const [],
    this.categoryId,
    this.links = const [],
  });

  final String id;
  final String title;
  final int targetCount;
  final int solvedCount;
  final bool isFocused;
  final DateTime? dueDate;
  final String priority;
  final String notes;
  final List<String> tags;
  final String? categoryId;
  final List<TargetLink> links;

  factory TargetItem.fromJson(Map<String, dynamic> json) {
    return TargetItem(
      id: json['id'] as String,
      title: json['title'] as String,
      targetCount: json['targetCount'] as int,
      solvedCount: json['solvedCount'] as int? ?? 0,
      isFocused: json['isFocused'] as bool? ?? false,
      dueDate: json['dueDate'] == null ? null : DateTime.tryParse(json['dueDate'] as String),
      priority: json['priority'] as String? ?? 'medium',
      notes: json['notes'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      categoryId: json['categoryId'] as String?,
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => TargetLink.fromJson(e as Map<String, dynamic>))
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
      'isFocused': isFocused,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'notes': notes,
      'tags': tags,
      'categoryId': categoryId,
      'links': links.map((l) => l.toJson()).toList(),
    };
  }

  TargetItem copyWith({
    String? title,
    int? targetCount,
    int? solvedCount,
    bool? isFocused,
    Object? dueDate = _unchanged,
    String? priority,
    String? notes,
    List<String>? tags,
    Object? categoryId = _unchanged,
    List<TargetLink>? links,
  }) {
    return TargetItem(
      id: id,
      title: title ?? this.title,
      targetCount: targetCount ?? this.targetCount,
      solvedCount: solvedCount ?? this.solvedCount,
      isFocused: isFocused ?? this.isFocused,
      dueDate: dueDate == _unchanged ? this.dueDate : dueDate as DateTime?,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      categoryId: categoryId == _unchanged ? this.categoryId : categoryId as String?,
      links: links ?? this.links,
    );
  }
}
