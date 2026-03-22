import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/index.dart' as models;

// Category notifier
class CategoryNotifier extends ChangeNotifier {
  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _currentUserId;

  final Map<String, List<models.Category>> _categoryStore = {};

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> syncForUser(String? userId) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUserId = userId;
    if (userId == null || userId.isEmpty) {
      _categories = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _categories = _categoryStore.putIfAbsent(
      userId,
      () => _buildDefaultCategories(userId),
    );

    _isLoading = false;
    notifyListeners();
  }

  List<models.Category> _buildDefaultCategories(String userId) {
    final now = DateTime.now();
    return [
      models.Category(
        id: 'cat1',
        userId: userId,
        name: 'Chi tiêu cố định',
        icon: '🏠',
        type: models.TransactionType.expense,
        createdAt: now,
      ),
      models.Category(
        id: 'cat2',
        userId: userId,
        name: 'Chi tiêu thiết yếu',
        icon: '🛒',
        type: models.TransactionType.expense,
        createdAt: now,
      ),
      models.Category(
        id: 'cat3',
        userId: userId,
        name: 'Chi tiêu phát sinh',
        icon: '🎁',
        type: models.TransactionType.expense,
        createdAt: now,
      ),
      models.Category(
        id: 'cat4',
        userId: userId,
        name: 'Chi tiêu khẩn cấp',
        icon: '🚨',
        type: models.TransactionType.expense,
        createdAt: now,
      ),
      models.Category(
        id: 'cat5',
        userId: userId,
        name: 'Chi tiêu tùy ý',
        icon: '⭐',
        type: models.TransactionType.expense,
        createdAt: now,
      ),
      models.Category(
        id: 'cat_income',
        userId: userId,
        name: 'Lương',
        icon: '💼',
        type: models.TransactionType.income,
        createdAt: now,
      ),
      models.Category(
        id: 'cat_bonus',
        userId: userId,
        name: 'Thưởng',
        icon: '🎁',
        type: models.TransactionType.income,
        createdAt: now,
      ),
    ];
  }

  void addCategory(models.Category category) {
    if (_currentUserId == null) return;
    final scoped = category.userId == _currentUserId
        ? category
        : category.copyWith(userId: _currentUserId);
    _categories.add(scoped);
    notifyListeners();
  }

  void updateCategory(models.Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  List<models.Category> getCategoriesByType(models.TransactionType type) {
    return _categories.where((c) => c.type == type).toList();
  }

  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
