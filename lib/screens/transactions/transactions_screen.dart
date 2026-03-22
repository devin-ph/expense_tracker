import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';
import '../../config/constants.dart';

/// Transactions Screen - Shows transaction history with filtering
/// Implemented by: Đinh Phương Ly
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  TransactionType?
  _selectedFilter; // null = all, income = income, expense = expense

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _selectedFilter = null; // Show all by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao dịch'), elevation: 0),
      body: Column(
        children: [
          // Date filter
          _buildDateFilter(context),
          // Filter buttons
          _buildFilterButtons(),
          // Statistics
          _buildStatistics(),
          // Transactions list
          Expanded(child: _buildTransactionList()),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              'Từ',
              _startDate,
              () => _selectDate(context, true),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: _buildDateButton(
              'Đến',
              _endDate,
              () => _selectDate(context, false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              date != null
                  ? DateFormat(AppDateFormat.date).format(date)
                  : 'Chọn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              'Thu nhập',
              TransactionType.income,
              Colors.green,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildFilterButton(
              'Chi tiêu',
              TransactionType.expense,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, TransactionType type, Color color) {
    final isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? null : type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isSelected ? color : Colors.grey,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<TransactionNotifier>(
      builder: (context, transactionNotifier, _) {
        final filtered = transactionNotifier.getTransactionsByDateRange(
          _startDate ?? DateTime.now(),
          _endDate ?? DateTime.now(),
        );

        // Filter by selected type if applicable
        final filteredByType = _selectedFilter == null
            ? filtered
            : filtered.where((t) => t.type == _selectedFilter).toList();

        // Calculate totals
        final incomeTotal = filteredByType
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final expenseTotal = filteredByType
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Show income stat if no filter or income filter is selected
              if (_selectedFilter == null ||
                  _selectedFilter == TransactionType.income)
                Expanded(
                  child: _buildStatBox(
                    'Tổng Thu nhập',
                    AppCurrency.format(incomeTotal),
                    Colors.green,
                  ),
                ),
              // Add spacing between stats only if both are shown
              if (_selectedFilter == null) const SizedBox(width: AppSpacing.md),
              // Show expense stat if no filter or expense filter is selected
              if (_selectedFilter == null ||
                  _selectedFilter == TransactionType.expense)
                Expanded(
                  child: _buildStatBox(
                    'Tổng Chi tiêu',
                    AppCurrency.format(expenseTotal),
                    Colors.red,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionList() {
    return Consumer2<TransactionNotifier, CategoryNotifier>(
      builder: (context, transactionNotifier, categoryNotifier, _) {
        var filtered = transactionNotifier.getTransactionsByDateRange(
          _startDate ?? DateTime.now(),
          _endDate ?? DateTime.now(),
        );

        // Filter by selected type if applicable
        if (_selectedFilter != null) {
          filtered = filtered.where((t) => t.type == _selectedFilter).toList();
        }

        // Sort by date descending
        filtered.sort((a, b) => b.date.compareTo(a.date));

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'Chưa có giao dịch nào',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final transaction = filtered[index];
            final category = categoryNotifier.getCategoryById(
              transaction.categoryId,
            );
            if (category == null) return const SizedBox();

            return TransactionCard(
              categoryName: category.name,
              categoryIcon: category.icon,
              amount: transaction.amount,
              note: transaction.note,
              dateTime: transaction.date,
              isIncome: transaction.type == TransactionType.income,
              onTap: () {
                // Show transaction details
              },
              onLongPress: () {
                // Delete or edit
              },
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
}
