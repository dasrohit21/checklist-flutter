class CategoryItem {
  final String id;
  final String name;
  final int colorValue;

  CategoryItem({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int? ?? 0xFF38BDF8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
    };
  }

  CategoryItem copyWith({
    String? name,
    int? colorValue,
  }) {
    return CategoryItem(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
