import 'package:flutter/material.dart';

// Default icon data for categories
const Map<String, IconData> defaultCategoryIcons = {
  'food': Icons.restaurant,
  'transport': Icons.directions_car,
  'shopping': Icons.shopping_bag,
  'entertainment': Icons.movie,
  'health': Icons.health_and_safety,
  'education': Icons.school,
  'utilities': Icons.water,
  'salary': Icons.work,
  'bonus': Icons.card_giftcard,
  'investment': Icons.trending_up,
  'other': Icons.category,
};

// Default categories
final List<Map<String, dynamic>> defaultExpenseCategories = [
  {'name': 'Ăn uống', 'icon': Icons.restaurant, 'color': Colors.orange},
  {'name': 'Đi lại', 'icon': Icons.directions_car, 'color': Colors.blue},
  {'name': 'Mua sắm', 'icon': Icons.shopping_bag, 'color': Colors.pink},
  {'name': 'Giải trí', 'icon': Icons.movie, 'color': Colors.purple},
  {'name': 'Sức khỏe', 'icon': Icons.health_and_safety, 'color': Colors.red},
  {'name': 'Giáo dục', 'icon': Icons.school, 'color': Colors.green},
  {'name': 'Tiện ích', 'icon': Icons.water, 'color': Colors.cyan},
  {'name': 'Khác', 'icon': Icons.category, 'color': Colors.grey},
];

final List<Map<String, dynamic>> defaultIncomeCategories = [
  {'name': 'Lương', 'icon': Icons.work, 'color': Colors.green},
  {'name': 'Thưởng', 'icon': Icons.card_giftcard, 'color': Colors.lightGreen},
  {'name': 'Đầu tư', 'icon': Icons.trending_up, 'color': Colors.lightBlue},
  {'name': 'Khác', 'icon': Icons.category, 'color': Colors.grey},
];
