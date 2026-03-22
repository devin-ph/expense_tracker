import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';

/// Transaction card widget for displaying transaction details
class TransactionCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final String? note;
  final List<String> attachments;
  final DateTime dateTime;
  final bool isIncome;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    this.note,
    List<String>? attachments,
    required this.dateTime,
    this.isIncome = false,
    this.onTap,
    this.onLongPress,
  }) : attachments = attachments ?? const <String>[];

  String _attachmentName(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is Map<String, dynamic>) {
        return (json['name'] as String?) ?? 'Tệp đính kèm';
      }
    } catch (_) {}
    return payload;
  }

  bool _isImageAttachment(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is Map<String, dynamic>) {
        final ext = ((json['ext'] as String?) ?? '').toLowerCase();
        return ext == 'png' ||
            ext == 'jpg' ||
            ext == 'jpeg' ||
            ext == 'gif' ||
            ext == 'webp' ||
            ext == 'bmp';
      }
    } catch (_) {}
    return false;
  }

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
                    if (attachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: attachments.take(2).map((item) {
                            final isImage = _isImageAttachment(item);
                            final name = _attachmentName(item);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.sm,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isImage
                                        ? Icons.image_outlined
                                        : Icons.attach_file,
                                    size: 12,
                                    color: theme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    name,
                                    style: textTheme.labelSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (attachments.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+${attachments.length - 2} tệp đính kèm',
                          style: textTheme.labelSmall,
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
