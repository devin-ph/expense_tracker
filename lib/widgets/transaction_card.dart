import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';

/// Transaction card widget for displaying transaction details
class TransactionCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final String? note;
  final DateTime dateTime;
  final bool isIncome;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionCard({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    this.note,
    required this.dateTime,
    this.isIncome = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isIncome
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
                alignment: Alignment.center,
                child: Text(categoryIcon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Category and Note
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note != null && note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          note!,
                          style: textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        DateFormat(AppDateFormat.time).format(dateTime),
                        style: textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '${isIncome ? '+' : '-'}${AppCurrency.format(amount)}',
                style: textTheme.titleMedium?.copyWith(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
