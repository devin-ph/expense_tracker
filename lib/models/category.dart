import 'enums.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final String icon; // Unicode icon or icon name
  final TransactionType type;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.type,
    required this.createdAt,
  });

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    TransactionType? type,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      type: TransactionType.values[json['type'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'icon': icon,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
