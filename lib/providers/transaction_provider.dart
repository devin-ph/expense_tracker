import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import '../models/index.dart';

// Transaction notifier
class TransactionNotifier extends ChangeNotifier {
  final cf.FirebaseFirestore _firestore = cf.FirebaseFirestore.instance;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _currentUserId;

  final Map<String, List<Transaction>> _transactionStore = {};

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> syncForUser(String? userId) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUserId = userId;
    if (userId == null || userId.isEmpty) {
      _transactions = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final local = _transactionStore.putIfAbsent(userId, () => <Transaction>[]);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      if (snapshot.docs.isEmpty) {
        if (local.isEmpty) {
          local.addAll(_buildDefaultTransactions(userId));
        }
        for (final tx in local) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc(tx.id)
              .set(tx.toJson());
        }
      } else {
        local
          ..clear()
          ..addAll(
            snapshot.docs.map(
              (doc) => Transaction.fromJson({...doc.data(), 'id': doc.id}),
            ),
          );
      }
    } catch (_) {
      if (local.isEmpty) {
        local.addAll(_buildDefaultTransactions(userId));
      }
    }

    _transactions = local;

    _isLoading = false;
    notifyListeners();
  }

  List<Transaction> _buildDefaultTransactions(String userId) {
    final now = DateTime.now();
    return [
      Transaction(
        id: '${userId}_tx_1',
        userId: userId,
        walletId: '${userId}_wallet_1',
        categoryId: 'cat1',
        type: TransactionType.expense,
        amount: 150000,
        note: 'Ăn trưa tại nhà hàng',
        date: now,
        createdAt: now,
      ),
      Transaction(
        id: '${userId}_tx_2',
        userId: userId,
        walletId: '${userId}_wallet_1',
        categoryId: 'cat2',
        type: TransactionType.expense,
        amount: 50000,
        note: 'Xăng',
        date: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: '${userId}_tx_3',
        userId: userId,
        walletId: '${userId}_wallet_1',
        categoryId: 'cat_income',
        type: TransactionType.income,
        amount: 2000000,
        note: 'Lương tháng 3',
        date: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void addTransaction(Transaction transaction) {
    if (_currentUserId == null) return;
    final scoped = transaction.userId == _currentUserId
        ? transaction
        : transaction.copyWith(userId: _currentUserId);
    _transactions.add(scoped);
    _transactionStore[_currentUserId!] = _transactions;
    _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('transactions')
        .doc(scoped.id)
        .set(scoped.toJson());
    notifyListeners();
  }

  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      if (_currentUserId != null) {
        _transactionStore[_currentUserId!] = _transactions;
        _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toJson());
      }
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    if (_currentUserId != null) {
      _transactionStore[_currentUserId!] = _transactions;
      _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .doc(id)
          .delete();
    }
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
