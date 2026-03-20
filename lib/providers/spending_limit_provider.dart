import 'package:flutter/foundation.dart';
import '../models/index.dart';

// SpendingLimit notifier
class SpendingLimitNotifier extends ChangeNotifier {
  List<SpendingLimit> _limits = [];
  bool _isLoading = false;

  List<SpendingLimit> get limits => _limits;
  bool get isLoading => _isLoading;

  SpendingLimitNotifier() {
    _initialize();
  }

  void _initialize() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // Create default spending limits
    _limits = [
      SpendingLimit(
        id: 'limit1',
        userId: 'user1',
        categoryId: 'cat1',
        limitAmount: 1500000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      SpendingLimit(
        id: 'limit2',
        userId: 'user1',
        categoryId: 'cat2',
        limitAmount: 800000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      SpendingLimit(
        id: 'limit3',
        userId: 'user1',
        categoryId: 'cat3',
        limitAmount: 2000000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void addLimit(SpendingLimit limit) {
    _limits.add(limit);
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
