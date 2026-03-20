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

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Thu nhập'),
            Tab(text: 'Chi tiêu'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date filter
          _buildDateFilter(context),
          // Statistics
          Consumer<TransactionNotifier>(
            builder: (context, transactionNotifier, _) {
              final isIncome = _tabController.index == 0;
              final type = isIncome
                  ? TransactionType.income
                  : TransactionType.expense;

              final filtered = transactionNotifier
                  .getTransactionsByDateRange(
                    _startDate ?? DateTime.now(),
                    _endDate ?? DateTime.now(),
                  )
                  .where((t) => t.type == type)
                  .toList();

              final total = filtered.fold(0.0, (sum, t) => sum + t.amount);

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        'Tổng ${isIncome ? 'Thu nhập' : 'Chi tiêu'}',
                        AppCurrency.format(total),
                        isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Transactions list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(TransactionType.income),
                _buildTransactionList(TransactionType.expense),
              ],
            ),
          ),
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

  Widget _buildTransactionList(TransactionType type) {
    return Consumer2<TransactionNotifier, CategoryNotifier>(
      builder: (context, transactionNotifier, categoryNotifier, _) {
        final filtered =
            transactionNotifier
                .getTransactionsByDateRange(
                  _startDate ?? DateTime.now(),
                  _endDate ?? DateTime.now(),
                )
                .where((t) => t.type == type)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

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
              isIncome: type == TransactionType.income,
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
