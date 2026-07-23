class ChecklistItem {
  ChecklistItem({
    required this.id,
    required this.text,
    required this.type,
    this.completed = false,
  });

  final String id;
  final String text;
  final String type;
  final bool completed;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String,
      type: json['type'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'completed': completed,
    };
  }

  ChecklistItem copyWith({String? text, String? type, bool? completed}) {
    return ChecklistItem(
      id: id,
      text: text ?? this.text,
      type: type ?? this.type,
      completed: completed ?? this.completed,
    );
  }
}
