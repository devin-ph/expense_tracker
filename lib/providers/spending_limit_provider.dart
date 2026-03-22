import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

// SpendingLimit notifier
class SpendingLimitNotifier extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SpendingLimit> _limits = [];
  bool _isLoading = false;
  String? _currentUserId;

  final Map<String, List<SpendingLimit>> _limitStore = {};

  List<SpendingLimit> get limits => _limits;
  bool get isLoading => _isLoading;

  Future<void> syncForUser(String? userId) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUserId = userId;
    if (userId == null || userId.isEmpty) {
      _limits = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final local = _limitStore.putIfAbsent(userId, () => <SpendingLimit>[]);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('spending_limits')
          .get();

      if (snapshot.docs.isEmpty) {
        if (local.isEmpty) {
          local.addAll(_buildDefaultLimits(userId));
        }
        for (final limit in local) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('spending_limits')
              .doc(limit.id)
              .set(limit.toJson());
        }
      } else {
        local
          ..clear()
          ..addAll(
            snapshot.docs.map(
              (doc) => SpendingLimit.fromJson({...doc.data(), 'id': doc.id}),
            ),
          );

        final defaultByCategory = {
          for (final item in _buildDefaultLimits(userId))
            item.categoryId: item.limitAmount,
        };
        final migrated = <SpendingLimit>[];
        final migrationTime = DateTime.now();

        for (var i = 0; i < local.length; i++) {
          final current = local[i];
          if (current.limitAmount > 0) continue;

          final fallbackAmount = defaultByCategory[current.categoryId];
          if (fallbackAmount == null || fallbackAmount <= 0) continue;

          final fixed = current.copyWith(
            limitAmount: fallbackAmount,
            lastResetAt: current.lastResetAt ?? current.updatedAt,
            updatedAt: migrationTime,
          );
          local[i] = fixed;
          migrated.add(fixed);
        }

        for (final limit in migrated) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('spending_limits')
              .doc(limit.id)
              .set(limit.toJson());
        }
      }
    } catch (_) {
      if (local.isEmpty) {
        local.addAll(_buildDefaultLimits(userId));
      }
    }

    _limits = local;

    _isLoading = false;
    notifyListeners();
  }

  List<SpendingLimit> _buildDefaultLimits(String userId) {
    final now = DateTime.now();
    return [
      SpendingLimit(
        id: '${userId}_limit1',
        userId: userId,
        categoryId: 'cat1',
        limitAmount: 1500000,
        createdAt: now,
        updatedAt: now,
      ),
      SpendingLimit(
        id: '${userId}_limit2',
        userId: userId,
        categoryId: 'cat2',
        limitAmount: 800000,
        createdAt: now,
        updatedAt: now,
      ),
      SpendingLimit(
        id: '${userId}_limit3',
        userId: userId,
        categoryId: 'cat3',
        limitAmount: 2000000,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  void addLimit(SpendingLimit limit) {
    if (_currentUserId == null) return;
    final scoped = limit.userId == _currentUserId
        ? limit
        : limit.copyWith(userId: _currentUserId);
    _limits.add(scoped);
    _limitStore[_currentUserId!] = _limits;
    _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('spending_limits')
        .doc(scoped.id)
        .set(scoped.toJson());
    notifyListeners();
  }

  void updateLimit(SpendingLimit limit) {
    var index = _limits.indexWhere((l) => l.id == limit.id);
    if (index == -1) {
      index = _limits.indexWhere(
        (l) =>
            l.categoryId == limit.categoryId &&
            (_currentUserId == null || l.userId == _currentUserId),
      );
    }

    if (index != -1) {
      _limits = List<SpendingLimit>.from(_limits)..[index] = limit;
      if (_currentUserId != null) {
        _limitStore[_currentUserId!] = _limits;
        _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('spending_limits')
            .doc(limit.id)
            .set(limit.toJson());
      }
      notifyListeners();
    }
  }

  void deleteLimit(String id) {
    _limits.removeWhere((l) => l.id == id);
    if (_currentUserId != null) {
      _limitStore[_currentUserId!] = _limits;
      _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('spending_limits')
          .doc(id)
          .delete();
    }
    notifyListeners();
  }

  SpendingLimit? getLimitByCategoryId(String categoryId) {
    try {
      return _limits.firstWhere((l) => l.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  double getProgressPercentage(String categoryId, double spent) {
    final limit = getLimitByCategoryId(categoryId);
    if (limit == null || limit.limitAmount <= 0) return 0;
    return (spent / limit.limitAmount) * 100;
  }
}
