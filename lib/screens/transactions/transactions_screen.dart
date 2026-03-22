import 'dart:convert';

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
  final ValueChanged<TransactionType>? onTypeChanged;

  const TransactionsScreen({Key? key, this.onTypeChanged}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  int _lastReportedTabIndex = 0;

  _TransactionNoteParts _parseTransactionNote(String? rawNote) {
    final note = rawNote?.trim() ?? '';
    if (note.isEmpty) {
      return const _TransactionNoteParts();
    }

    final separator = ' - ';
    if (!note.contains(separator)) {
      return _TransactionNoteParts(note: note);
    }

    final parts = note.split(separator);
    if (parts.length == 2) {
      return _TransactionNoteParts(detail: parts[0].trim(), note: parts[1].trim());
    }

    if (parts.length >= 3 && parts.first.trim() == 'Khác') {
      final detail = parts.take(2).join(separator).trim();
      final noteText = parts.skip(2).join(separator).trim();
      return _TransactionNoteParts(detail: detail, note: noteText);
    }

    final detail = parts.first.trim();
    final noteText = parts.skip(1).join(separator).trim();
    return _TransactionNoteParts(detail: detail, note: noteText);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTypeChanged?.call(TransactionType.income);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.index == _lastReportedTabIndex) {
      return;
    }

    _lastReportedTabIndex = _tabController.index;
    final currentType = _tabController.index == 0
        ? TransactionType.income
        : TransactionType.expense;

    widget.onTypeChanged?.call(currentType);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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
              attachments: transaction.attachments,
              dateTime: transaction.date,
              isIncome: type == TransactionType.income,
              onTap: () => _showTransactionDetail(transaction),
              onLongPress: () => _showTransactionDetail(transaction),
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

  double _transactionImpact(Transaction transaction) {
    return transaction.type == TransactionType.income
        ? transaction.amount
        : -transaction.amount;
  }

  void _showTransactionDetail(Transaction transaction) {
    final categoryNotifier = context.read<CategoryNotifier>();
    final walletNotifier = context.read<WalletNotifier>();
    final category = categoryNotifier.getCategoryById(transaction.categoryId);
    final wallet = walletNotifier.wallets.where(
      (w) => w.id == transaction.walletId,
    );
    final walletName = wallet.isNotEmpty
        ? wallet.first.name
        : 'Ví không xác định';
    final noteParts = _parseTransactionNote(transaction.note);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết giao dịch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Loại: ${transaction.type.label}'),
                const SizedBox(height: AppSpacing.sm),
                Text('Danh mục: ${category?.name ?? 'Không xác định'}'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chi tiết danh mục: ${noteParts.detail ?? '(Trống)'}',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Ví: $walletName'),
                const SizedBox(height: AppSpacing.sm),
                Text('Số tiền: ${AppCurrency.format(transaction.amount)}'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ngày: ${DateFormat(AppDateFormat.date).format(transaction.date)} ${DateFormat(AppDateFormat.time).format(transaction.date)}',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ghi chú: ${noteParts.note ?? '(Trống)'}',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Đính kèm: ${transaction.attachments.length} tệp'),
                if (transaction.attachments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ...transaction.attachments
                      .take(3)
                      .map(
                        (item) => Text(
                          '- ${_attachmentName(item)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showEditTransactionSheet(transaction);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Sửa'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Xóa giao dịch'),
                                content: const Text(
                                  'Bạn có chắc muốn xóa giao dịch này không?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm != true || !mounted) return;

                          final wallet = context
                              .read<WalletNotifier>()
                              .wallets
                              .firstWhere(
                                (w) => w.id == transaction.walletId,
                                orElse: () => Wallet(
                                  id: transaction.walletId,
                                  userId: transaction.userId,
                                  name: 'Ví không xác định',
                                  balance: 0,
                                  createdAt: DateTime.now(),
                                ),
                              );

                          if (wallet.id == transaction.walletId) {
                            final restoredBalance =
                                wallet.balance -
                                _transactionImpact(transaction);
                            context.read<WalletNotifier>().updateWallet(
                              wallet.copyWith(balance: restoredBalance),
                            );
                          }

                          context.read<TransactionNotifier>().deleteTransaction(
                            transaction.id,
                          );
                          if (mounted) {
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa giao dịch')),
                            );
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditTransactionSheet(Transaction transaction) async {
    final wallets = context.read<WalletNotifier>().wallets;
    final categoryNotifier = context.read<CategoryNotifier>();

    final amountController = TextEditingController(
      text: transaction.amount.toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: transaction.note ?? '');

    TransactionType selectedType = transaction.type;
    String? selectedWalletId = transaction.walletId;
    String? selectedCategoryId = transaction.categoryId;
    DateTime selectedDate = transaction.date;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final categories = categoryNotifier.getCategoriesByType(
              selectedType,
            );
            if (!categories.any((c) => c.id == selectedCategoryId) &&
                categories.isNotEmpty) {
              selectedCategoryId = categories.first.id;
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sửa giao dịch',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<TransactionType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Loại giao dịch',
                      ),
                      items: TransactionType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedType = value;
                          final newCategories = categoryNotifier
                              .getCategoriesByType(value);
                          selectedCategoryId = newCategories.isNotEmpty
                              ? newCategories.first.id
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số tiền'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: selectedWalletId,
                      decoration: const InputDecoration(labelText: 'Ví'),
                      items: wallets
                          .map(
                            (wallet) => DropdownMenuItem(
                              value: wallet.id,
                              child: Text(wallet.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => selectedWalletId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.icon} ${c.name}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => selectedCategoryId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày giao dịch'),
                      subtitle: Text(
                        DateFormat(AppDateFormat.date).format(selectedDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final parsedAmount = double.tryParse(
                            amountController.text.replaceAll(
                              RegExp(r'[^\d]'),
                              '',
                            ),
                          );

                          if (parsedAmount == null || parsedAmount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Số tiền không hợp lệ'),
                              ),
                            );
                            return;
                          }

                          if (selectedWalletId == null ||
                              selectedCategoryId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng chọn đủ ví và danh mục',
                                ),
                              ),
                            );
                            return;
                          }

                          final updated = transaction.copyWith(
                            type: selectedType,
                            amount: parsedAmount,
                            walletId: selectedWalletId,
                            categoryId: selectedCategoryId,
                            note: noteController.text.trim(),
                            date: selectedDate,
                          );

                          _applyTransactionUpdate(transaction, updated);
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật giao dịch'),
                            ),
                          );
                        },
                        child: const Text('Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    noteController.dispose();
  }

  void _applyTransactionUpdate(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) {
    final walletNotifier = context.read<WalletNotifier>();
    final transactionNotifier = context.read<TransactionNotifier>();

    final oldImpact = _transactionImpact(oldTransaction);
    final newImpact = _transactionImpact(newTransaction);

    final oldWallet = walletNotifier.wallets.firstWhere(
      (w) => w.id == oldTransaction.walletId,
      orElse: () => Wallet(
        id: oldTransaction.walletId,
        userId: oldTransaction.userId,
        name: 'Ví cũ',
        balance: 0,
        createdAt: DateTime.now(),
      ),
    );

    final newWallet = walletNotifier.wallets.firstWhere(
      (w) => w.id == newTransaction.walletId,
      orElse: () => Wallet(
        id: newTransaction.walletId,
        userId: newTransaction.userId,
        name: 'Ví mới',
        balance: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (oldTransaction.walletId == newTransaction.walletId) {
      final updatedBalance = oldWallet.balance - oldImpact + newImpact;
      walletNotifier.updateWallet(oldWallet.copyWith(balance: updatedBalance));
    } else {
      walletNotifier.updateWallet(
        oldWallet.copyWith(balance: oldWallet.balance - oldImpact),
      );
      walletNotifier.updateWallet(
        newWallet.copyWith(balance: newWallet.balance + newImpact),
      );
    }

    transactionNotifier.updateTransaction(newTransaction);
    setState(() {});
  }

  String _attachmentName(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return (decoded['name'] as String?) ?? payload;
      }
    } catch (_) {}

    return payload;
  }
}

class _TransactionNoteParts {
  final String? detail;
  final String? note;

  const _TransactionNoteParts({String? detail, String? note})
    : detail = (detail != null && detail != '') ? detail : null,
      note = (note != null && note != '') ? note : null;
}
