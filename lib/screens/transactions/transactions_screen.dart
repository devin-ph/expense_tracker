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
  final ValueChanged<int>? onTabIndexChanged;
  final int initialTabIndex;

  const TransactionsScreen({
    super.key,
    this.onTypeChanged,
    this.onTabIndexChanged,
    this.initialTabIndex = 0,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const Map<String, List<String>> _expenseCategoryOptions = {
    'cat1': [
      'Tiền thuê nhà/ Trả góp mua nhà',
      'Điện, nước, internet, truyền hình',
      'Phí bảo hiểm (y tế, xe, nhà)',
      'Học phí/ Phí dịch vụ định kỳ',
      'Thẻ tín dụng',
      'Khác',
    ],
    'cat2': [
      'Thực phẩm, nhu yếu phẩm',
      'Xăng xe, vé xe buýt...',
      'Quần áo cơ bản, giày dép',
      'Khám sức khỏe định kỳ',
      'Dụng cụ sinh hoạt',
      'Khác',
    ],
    'cat3': [
      'Quà tặng cho bạn bè/người thân',
      'Tiệc cưới, sinh nhật, lễ hội',
      'Sửa chữa đồ dùng hỏng hóc',
      'Đóng góp xã hội, từ thiện',
      'Khác',
    ],
    'cat4': [
      'Chi phí y tế khẩn cấp',
      'Hỗ trợ tài chính cho người thân',
      'Thiên tai hoặc sự cố bất khả kháng',
      'Khác',
    ],
    'cat5': [
      'Ăn uống ngoài, cà phê',
      'Du lịch, nghỉ dưỡng',
      'Mua sắm',
      'Giải trí: xem phim, concert, thể thao...',
      'Sở thích cá nhân',
      'Khác',
    ],
  };
  static const Map<String, List<String>> _incomeCategoryOptions = {
    'cat_income': ['Lương tháng', 'Lương làm thêm', 'Phụ cấp', 'Khác'],
    'cat_bonus': ['Thưởng hiệu suất', 'Thưởng lễ/tết', 'Hoa hồng', 'Khác'],
  };

  static const Set<String> _knownCategoryDetailOptions = {
    'Tiền thuê nhà/ Trả góp mua nhà',
    'Điện, nước, internet, truyền hình',
    'Phí bảo hiểm (y tế, xe, nhà)',
    'Học phí/ Phí dịch vụ định kỳ',
    'Thẻ tín dụng',
    'Thực phẩm, nhu yếu phẩm',
    'Xăng xe, vé xe buýt...',
    'Quần áo cơ bản, giày dép',
    'Khám sức khỏe định kỳ',
    'Dụng cụ sinh hoạt',
    'Quà tặng cho bạn bè/người thân',
    'Tiệc cưới, sinh nhật, lễ hội',
    'Sửa chữa đồ dùng hỏng hóc',
    'Đóng góp xã hội, từ thiện',
    'Chi phí y tế khẩn cấp',
    'Hỗ trợ tài chính cho người thân',
    'Thiên tai hoặc sự cố bất khả kháng',
    'Ăn uống ngoài, cà phê',
    'Du lịch, nghỉ dưỡng',
    'Mua sắm',
    'Giải trí: xem phim, concert, thể thao...',
    'Sở thích cá nhân',
    'Lương tháng',
    'Lương làm thêm',
    'Phụ cấp',
    'Thưởng hiệu suất',
    'Thưởng lễ/tết',
    'Hoa hồng',
    'Khác',
  };

  DateTime? _startDate;
  DateTime? _endDate;
  int _currentTabIndex = 0;
  TransactionType? _lastReportedType;
  TransactionType?
  _selectedFilter; // null = all, income = income, expense = expense

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _currentTabIndex = widget.initialTabIndex.clamp(0, 1);
    _selectedFilter = null; // Show all by default
    _reportCurrentType();
  }

  void _handleTabChanged() {
    _reportCurrentType();
    if (mounted) {
      setState(() {});
    }
  }

  void _reportCurrentType() {
    final effectiveIndex = _selectedFilter == TransactionType.income
        ? 0
        : _selectedFilter == TransactionType.expense
        ? 1
        : _currentTabIndex;
    widget.onTabIndexChanged?.call(effectiveIndex);
    final currentType = effectiveIndex == 0
        ? TransactionType.income
        : TransactionType.expense;
    if (_lastReportedType == currentType) {
      return;
    }
    _lastReportedType = currentType;
    widget.onTypeChanged?.call(currentType);
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
          final nextFilter = isSelected ? null : type;
          _selectedFilter = nextFilter;
          if (nextFilter != null) {
            _currentTabIndex = nextFilter == TransactionType.income ? 0 : 1;
          }
        });
        _reportCurrentType();
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
    return Consumer2<TransactionNotifier, WalletNotifier>(
      builder: (context, transactionNotifier, walletNotifier, _) {
        final walletId = walletNotifier.selectedWallet?.id;
        final filtered = transactionNotifier.getTransactionsByDateRange(
          _startDate ?? DateTime.now(),
          _endDate ?? DateTime.now(),
          walletId: walletId,
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
    return Consumer3<TransactionNotifier, CategoryNotifier, WalletNotifier>(
      builder: (
        context,
        transactionNotifier,
        categoryNotifier,
        walletNotifier,
        _,
      ) {
        final walletId = walletNotifier.selectedWallet?.id;
        var filtered = transactionNotifier.getTransactionsByDateRange(
          _startDate ?? DateTime.now(),
          _endDate ?? DateTime.now(),
          walletId: walletId,
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
              attachments: transaction.attachments,
              dateTime: transaction.date,
              isIncome: transaction.type == TransactionType.income,
              onTap: () => _showTransactionDetail(transaction),
              onLongPress: () => _showEditTransactionSheet(transaction),
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
                Text('Chi tiết danh mục: ${noteParts.detail ?? '(Trống)'}'),
                const SizedBox(height: AppSpacing.sm),
                Text('Ví: $walletName'),
                const SizedBox(height: AppSpacing.sm),
                Text('Số tiền: ${AppCurrency.format(transaction.amount)}'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ngày: ${DateFormat(AppDateFormat.date).format(transaction.date)} ${DateFormat(AppDateFormat.time).format(transaction.date)}',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Ghi chú: ${noteParts.note ?? '(Trống)'}'),
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
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _showEditTransactionSheet(transaction);
                            }
                          });
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
    final parentContext = context;
    final messenger = ScaffoldMessenger.maybeOf(parentContext);
    final wallets = context.read<WalletNotifier>().wallets;
    final categoryNotifier = context.read<CategoryNotifier>();
    final noteParts = _parseTransactionNote(transaction.note);
    String amountInput = transaction.amount.toStringAsFixed(0);
    String categoryDetailInput = noteParts.detail ?? '';
    String noteInput = noteParts.note ?? '';
    String? otherDetailInput;

    TransactionType selectedType = transaction.type;
    String? selectedWalletId = transaction.walletId;
    String? selectedCategoryId = transaction.categoryId;
    DateTime selectedDate = transaction.date;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
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
                      MediaQuery.of(modalContext).viewInsets.bottom +
                      AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sửa giao dịch',
                      style: Theme.of(parentContext).textTheme.headlineSmall,
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
                      initialValue: amountInput,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số tiền'),
                      onChanged: (value) => amountInput = value,
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
                    _buildEditCategoryDetailSelection(
                      selectedType,
                      selectedCategoryId,
                      categoryDetailInput,
                      (value) => setSheetState(() => categoryDetailInput = value),
                      (custom) => setSheetState(() => otherDetailInput = custom),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      initialValue: noteInput,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                      onChanged: (value) => noteInput = value,
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
                          context: modalContext,
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
                            amountInput.replaceAll(
                              RegExp(r'[^\d]'),
                              '',
                            ),
                          );

                          if (parsedAmount == null || parsedAmount <= 0) {
                            messenger?.showSnackBar(
                              const SnackBar(
                                content: Text('Số tiền không hợp lệ'),
                              ),
                            );
                            return;
                          }

                          if (selectedWalletId == null ||
                              selectedCategoryId == null) {
                            messenger?.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng chọn đủ ví và danh mục',
                                ),
                              ),
                            );
                            return;
                          }

                          final finalCategoryDetail = _buildFinalCategoryDetail(
                            categoryDetailInput,
                            otherDetailInput,
                          );
                          final updated = transaction.copyWith(
                            type: selectedType,
                            amount: parsedAmount,
                            walletId: selectedWalletId,
                            categoryId: selectedCategoryId,
                            note: _composeEditedTransactionNote(
                              categoryDetail: finalCategoryDetail,
                              note: noteInput,
                            ),
                            date: selectedDate,
                          );

                          _applyTransactionUpdate(transaction, updated);
                          Navigator.pop(sheetContext);
                          if (mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                messenger?.showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã cập nhật giao dịch'),
                                  ),
                                );
                              }
                            });
                          }
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

  String _composeEditedTransactionNote({
    required String categoryDetail,
    required String note,
  }) {
    final detailValue = categoryDetail.trim();
    final noteValue = note.trim();

    if (detailValue.isEmpty) {
      return noteValue;
    }

    if (noteValue.isEmpty) {
      return detailValue;
    }

    return '$detailValue - $noteValue';
  }

  String _buildFinalCategoryDetail(
    String selectedDetail,
    String? otherDetail,
  ) {
    final detail = selectedDetail.trim();
    if (detail == 'Khác' && otherDetail != null && otherDetail.isNotEmpty) {
      return 'Khác - ${otherDetail.trim()}';
    }
    return detail;
  }

  Widget _buildEditCategoryDetailSelection(
    TransactionType transactionType,
    String? categoryId,
    String currentDetail,
    Function(String) onDetailChanged,
    Function(String?) onOtherDetailChanged,
  ) {
    if (categoryId == null) {
      return const SizedBox.shrink();
    }

    final detailOptions = transactionType == TransactionType.expense
        ? (_expenseCategoryOptions[categoryId] ?? const <String>[])
        : (_incomeCategoryOptions[categoryId] ?? const <String>[]);

    if (detailOptions.isEmpty) {
      return TextFormField(
        initialValue: currentDetail,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Chi tiết danh mục',
          hintText: 'Nhập chi tiết',
        ),
        onChanged: onDetailChanged,
      );
    }

    final isOtherSelected = currentDetail == 'Khác';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: detailOptions.contains(currentDetail)
                  ? currentDetail
                  : (isOtherSelected ? 'Khác' : null),
              hint: const Text('Chọn chi tiết danh mục'),
              items: detailOptions.map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onDetailChanged(value);
                  if (value != 'Khác') {
                    onOtherDetailChanged(null);
                  }
                }
              },
            ),
          ),
        ),
        if (isOtherSelected) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            initialValue: currentDetail != 'Khác' ? currentDetail : '',
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Chi tiết danh mục (tùy chỉnh)',
              hintText: 'Nhập chi tiết khác',
            ),
            onChanged: onOtherDetailChanged,
          ),
        ],
      ],
    );
  }

  _TransactionNoteParts _parseTransactionNote(String? rawNote) {
    if (rawNote == null || rawNote.trim().isEmpty) {
      return const _TransactionNoteParts();
    }

    final note = rawNote.trim();
    try {
      final decoded = jsonDecode(note);
      if (decoded is Map<String, dynamic>) {
        final parsedDetail =
            (decoded['detail'] as String?)?.trim() ??
            (decoded['categoryDetail'] as String?)?.trim() ??
            (decoded['category_detail'] as String?)?.trim();
        final parsedNote =
            (decoded['note'] as String?)?.trim() ??
            (decoded['content'] as String?)?.trim() ??
            (decoded['remark'] as String?)?.trim();
        return _normalizeNoteParts(
          _TransactionNoteParts(detail: parsedDetail, note: parsedNote),
        );
      }
    } catch (_) {
      // Fallback for legacy plain text notes.
    }

    if (note.contains('|')) {
      final parts = note.split('|');
      final detail = parts.isNotEmpty ? parts.first.trim() : null;
      final content = parts.length > 1
          ? parts.sublist(1).join('|').trim()
          : null;
      return _normalizeNoteParts(
        _TransactionNoteParts(detail: detail, note: content),
      );
    }

    // Legacy note format from add transaction screen:
    // - "<detail> - <note>"
    // - "Khác - <other detail> - <note>"
    final dashParts = note
        .split(RegExp(r'\s+-\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (dashParts.length >= 2) {
      final isOther = dashParts.first.toLowerCase() == 'khác';
      final firstPart = dashParts.first;

      if (!isOther && !_knownCategoryDetailOptions.contains(firstPart)) {
        return _TransactionNoteParts(note: note);
      }

      if (isOther && dashParts.length == 2) {
        return _TransactionNoteParts(detail: note);
      }

      if (isOther && dashParts.length >= 3) {
        final detail = '${dashParts[0]} - ${dashParts[1]}';
        final content = dashParts.sublist(2).join(' - ').trim();
        return _normalizeNoteParts(
          _TransactionNoteParts(detail: detail, note: content),
        );
      }

      final detail = dashParts.first;
      final content = dashParts.sublist(1).join(' - ').trim();
      return _normalizeNoteParts(
        _TransactionNoteParts(detail: detail, note: content),
      );
    }

    if (_isCategoryDetailValue(note)) {
      return _TransactionNoteParts(detail: note);
    }

    return _TransactionNoteParts(note: note);
  }

  _TransactionNoteParts _normalizeNoteParts(_TransactionNoteParts parts) {
    final detail = parts.detail;
    final note = parts.note;

    if (detail == null || note == null) {
      return parts;
    }

    final detailLooksLikeCategory = _isCategoryDetailValue(detail);
    final noteLooksLikeCategory = _isCategoryDetailValue(note);

    if (!detailLooksLikeCategory && noteLooksLikeCategory) {
      // Some legacy data stores detail and note in reverse order.
      return _TransactionNoteParts(detail: note, note: detail);
    }

    return parts;
  }

  bool _isCategoryDetailValue(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }

    return _knownCategoryDetailOptions.contains(normalized) ||
        normalized.startsWith('Khác -');
  }
}

class _TransactionNoteParts {
  final String? detail;
  final String? note;

  const _TransactionNoteParts({String? detail, String? note})
    : detail = (detail != null && detail != '') ? detail : null,
      note = (note != null && note != '') ? note : null;
}
