import 'package:flutter/foundation.dart';
import '../models/index.dart';

// SpendingLimit notifier
class SpendingLimitNotifier extends ChangeNotifier {
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

    _limits = _limitStore.putIfAbsent(
      userId,
      () => _buildDefaultLimits(userId),
    );

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
    notifyListeners();
  }

  void updateLimit(SpendingLimit limit) {
    final index = _limits.indexWhere((l) => l.id == limit.id);
    if (index != -1) {
      _limits[index] = limit;
      notifyListeners();
    }
  }

  void deleteLimit(String id) {
    _limits.removeWhere((l) => l.id == id);
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
    if (limit == null) return 0;
    return (spent / limit.limitAmount) * 100;
  }
}
