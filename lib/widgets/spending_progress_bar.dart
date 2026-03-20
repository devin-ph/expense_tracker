import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';

/// Progress bar widget for spending limits
class SpendingProgressBar extends StatelessWidget {
  final double spent;
  final double limit;
  final String categoryName;
  final String? categoryIcon;
  final VoidCallback? onTap;

  const SpendingProgressBar({
    Key? key,
    required this.spent,
    required this.limit,
    required this.categoryName,
    this.categoryIcon,
    this.onTap,
  }) : super(key: key);

  Color _getProgressColor(double percentage) {
    if (percentage < 50) {
      return incomeColor; // Green
    } else if (percentage < 80) {
      return warningColor; // Orange
    } else {
      return expenseColor; // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = limit > 0 ? (spent / limit) * 100 : 0.0;
    final progressColor = _getProgressColor(percentage);
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and category name
              Row(
                children: [
                  if (categoryIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        categoryIcon!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  Text(categoryName, style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              // Amount text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppCurrency.format(spent)} / ${AppCurrency.format(limit)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
