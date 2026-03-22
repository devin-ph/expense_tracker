class SpendingLimit {
  final String id;
  final String userId;
  final String categoryId;
  final double limitAmount;
  final DateTime? lastResetAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpendingLimit({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.limitAmount,
    this.lastResetAt,
    required this.createdAt,
    required this.updatedAt,
  });

  SpendingLimit copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? limitAmount,
    DateTime? lastResetAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpendingLimit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      limitAmount: limitAmount ?? this.limitAmount,
      lastResetAt: lastResetAt ?? this.lastResetAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SpendingLimit.fromJson(Map<String, dynamic> json) {
    return SpendingLimit(
      id: json['id'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      lastResetAt: json['lastResetAt'] != null
          ? DateTime.parse(json['lastResetAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'lastResetAt': lastResetAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
