import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import '../models/index.dart' as models;

// Category notifier
class CategoryNotifier extends ChangeNotifier {
  final cf.FirebaseFirestore _firestore = cf.FirebaseFirestore.instance;

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

    final local = _categoryStore.putIfAbsent(userId, () => <models.Category>[]);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      if (snapshot.docs.isEmpty) {
        if (local.isEmpty) {
          local.addAll(_buildDefaultCategories(userId));
        }
        for (final category in local) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('categories')
              .doc(category.id)
              .set(category.toJson());
        }
      } else {
        local
          ..clear()
          ..addAll(
            snapshot.docs.map(
              (doc) => models.Category.fromJson({...doc.data(), 'id': doc.id}),
            ),
          );
      }
    } catch (_) {
      if (local.isEmpty) {
        local.addAll(_buildDefaultCategories(userId));
      }
    }

    _categories = local;
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
    _categoryStore[_currentUserId!] = _categories;
    _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('categories')
        .doc(scoped.id)
        .set(scoped.toJson());
    notifyListeners();
  }

  void updateCategory(models.Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      if (_currentUserId != null) {
        _categoryStore[_currentUserId!] = _categories;
        _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('categories')
            .doc(category.id)
            .set(category.toJson());
      }
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    if (_currentUserId != null) {
      _categoryStore[_currentUserId!] = _categories;
      _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .doc(id)
          .delete();
    }
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
