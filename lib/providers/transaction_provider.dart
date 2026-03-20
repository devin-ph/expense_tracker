import 'package:flutter/foundation.dart';
import '../models/index.dart';

// Transaction notifier
class TransactionNotifier extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  TransactionNotifier() {
    _initialize();
  }

  void _initialize() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    _transactions = [
      Transaction(
        id: '1',
        userId: 'user1',
        walletId: '1',
        categoryId: 'cat1',
        type: TransactionType.expense,
        amount: 150000,
        note: 'Ăn trưa tại nhà hàng',
        date: now,
        createdAt: now,
      ),
      Transaction(
        id: '2',
        userId: 'user1',
        walletId: '1',
        categoryId: 'cat2',
        type: TransactionType.expense,
        amount: 50000,
        note: 'Xăng',
        date: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: '3',
        userId: 'user1',
        walletId: '1',
        categoryId: 'cat_income',
        type: TransactionType.income,
        amount: 2000000,
        note: 'Lương tháng 3',
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<Transaction> getTransactionsByWallet(String walletId) {
    return _transactions.where((t) => t.walletId == walletId).toList();
  }

  List<Transaction> getTransactionsByType(
    TransactionType type, {
    String? walletId,
  }) {
    return _transactions.where((t) {
      if (walletId != null && t.walletId != walletId) return false;
      return t.type == type;
    }).toList();
  }

  List<Transaction> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? walletId,
  }) {
    return _transactions.where((t) {
      if (walletId != null && t.walletId != walletId) return false;
      return t.date.isAfter(startDate) &&
          t.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  List<Transaction> getTodayTransactions({String? walletId}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getTransactionsByDateRange(today, today, walletId: walletId);
  }

  double getTotalByType(TransactionType type, {String? walletId}) {
    final filtered = getTransactionsByType(type, walletId: walletId);
    return filtered.fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalByTypeAndDateRange(
    TransactionType type,
    DateTime startDate,
    DateTime endDate, {
    String? walletId,
  }) {
    final filtered = getTransactionsByDateRange(
      startDate,
      endDate,
      walletId: walletId,
    );
    return filtered
        .where((t) => t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
