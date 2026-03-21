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
  {'name': 'Chi tiêu cố định', 'icon': Icons.home_work, 'color': Colors.indigo},
  {
    'name': 'Chi tiêu thiết yếu',
    'icon': Icons.shopping_basket,
    'color': Colors.teal,
  },
  {
    'name': 'Chi tiêu phát sinh',
    'icon': Icons.celebration,
    'color': Colors.amber,
  },
  {'name': 'Chi tiêu khẩn cấp', 'icon': Icons.emergency, 'color': Colors.red},
  {
    'name': 'Chi tiêu tùy ý',
    'icon': Icons.emoji_emotions,
    'color': Colors.deepPurple,
  },
];

final List<Map<String, dynamic>> defaultIncomeCategories = [
  {'name': 'Lương', 'icon': Icons.work, 'color': Colors.green},
  {'name': 'Thưởng', 'icon': Icons.card_giftcard, 'color': Colors.lightGreen},
  {'name': 'Đầu tư', 'icon': Icons.trending_up, 'color': Colors.lightBlue},
  {'name': 'Khác', 'icon': Icons.category, 'color': Colors.grey},
];
