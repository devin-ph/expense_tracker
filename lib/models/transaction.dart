import 'enums.dart';

class Transaction {
  final String id;
  final String userId;
  final String walletId;
  final String categoryId;
  final TransactionType type;
  final double amount;
  final String? note;
  final List<String> attachments;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    List<String>? attachments,
    required this.date,
    required this.createdAt,
  }) : attachments = List<String>.unmodifiable(
         (attachments ?? const <String>[]).map((item) => item.toString()),
       );

  Transaction copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? note,
    List<String>? attachments,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      attachments: attachments ?? this.attachments,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      categoryId: json['categoryId'] as String,
      type: TransactionType.values[json['type'] as int],
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      attachments: json['attachments'] is List
          ? (json['attachments'] as List<dynamic>)
                .map((item) => item.toString())
                .toList()
          : const <String>[],
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'type': type.index,
      'amount': amount,
      'note': note,
      'attachments': attachments,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
