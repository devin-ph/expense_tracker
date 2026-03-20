class Wallet {
  final String id;
  final String userId;
  final String name;
  final double balance;
  final DateTime createdAt;
  final bool isDefault;

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.createdAt,
    this.isDefault = false,
  });

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }
}
