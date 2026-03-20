import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/index.dart' as models;

// Category notifier
class CategoryNotifier extends ChangeNotifier {
  List<models.Category> _categories = [];
  bool _isLoading = false;

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryNotifier() {
    _initialize();
  }

  void _initialize() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    // Create default categories
    _categories = [
      models.Category(
        id: 'cat1',
        userId: 'user1',
        name: 'Ăn uống',
        icon: '🍔',
        type: models.TransactionType.expense,
        createdAt: DateTime.now(),
      ),
      models.Category(
        id: 'cat2',
        userId: 'user1',
        name: 'Đi lại',
        icon: '🚗',
        type: models.TransactionType.expense,
        createdAt: DateTime.now(),
      ),
      models.Category(
        id: 'cat3',
        userId: 'user1',
        name: 'Mua sắm',
        icon: '🛍️',
        type: models.TransactionType.expense,
        createdAt: DateTime.now(),
      ),
      models.Category(
        id: 'cat4',
        userId: 'user1',
        name: 'Giải trí',
        icon: '🎬',
        type: models.TransactionType.expense,
        createdAt: DateTime.now(),
      ),
      models.Category(
        id: 'cat5',
        userId: 'user1',
        name: 'Sức khỏe',
        icon: '⚕️',
        type: models.TransactionType.expense,
        createdAt: DateTime.now(),
      ),
      models.Category(
        id: 'cat_income',
        userId: 'user1',
        name: 'Lương',
        icon: '💼',
        type: models.TransactionType.income,
        createdAt: DateTime.now(),
      ),
      models.Category(
        id: 'cat_bonus',
        userId: 'user1',
        name: 'Thưởng',
        icon: '🎁',
        type: models.TransactionType.income,
        createdAt: DateTime.now(),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void addCategory(models.Category category) {
    _categories.add(category);
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
