import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../config/constants.dart';

/// Add Transaction Screen - Bottom sheet for adding new transactions
/// Implemented by: Trần Quang Quân
class AddTransactionSheet extends StatefulWidget {
  final VoidCallback? onTransactionAdded;

  const AddTransactionSheet({Key? key, this.onTransactionAdded})
    : super(key: key);

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TransactionType _transactionType;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  DateTime? _selectedDate;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transactionType = TransactionType.expense;
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _selectedDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedWallet = context.read<WalletNotifier>().selectedWallet;
      if (selectedWallet != null) {
        setState(() => _selectedWalletId = selectedWallet.id);
      }

      // Initialize selected category to first available category
      final categoryNotifier = context.read<CategoryNotifier>();
      final categories = categoryNotifier.getCategoriesByType(_transactionType);
      if (categories.isNotEmpty && _selectedCategoryId == null) {
        setState(() => _selectedCategoryId = categories.first.id);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thêm giao dịch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Transaction type tabs
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.lg),
            // Amount input
            _buildAmountInput(),
            const SizedBox(height: AppSpacing.lg),
            // Category selection
            _buildCategorySelection(),
            const SizedBox(height: AppSpacing.lg),
            // Wallet selection
            _buildWalletSelection(),
            const SizedBox(height: AppSpacing.lg),
            // Date selection
            _buildDateSelection(),
            const SizedBox(height: AppSpacing.lg),
            // Note input
            _buildNoteInput(),
            const SizedBox(height: AppSpacing.xl),
            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addTransaction,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Thêm giao dịch'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            'Thu nhập',
            TransactionType.income,
            Colors.green,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: _buildTypeButton(
            'Chi tiêu',
            TransactionType.expense,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String label, TransactionType type, Color color) {
    final isSelected = _transactionType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = type;
          _selectedCategoryId = null; // Reset category when type changes
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isSelected ? color : null,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    final currentAmount =
        int.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), '')) ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Số tiền', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0',
            filled: true,
            fillColor: _transactionType == TransactionType.income
                ? Colors.green.withOpacity(0.05)
                : Colors.red.withOpacity(0.05),
            suffixText: '₫',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              final numericValue = value.replaceAll(RegExp(r'[^\d]'), '');
              final formatted = _formatAmount(numericValue);
              setState(() {
                _amountController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: formatted.length),
                  ),
                );
              });
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Quick amount suggestions (pills)
        if (currentAmount > 0)
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _buildQuickAmountChip(currentAmount + 1000),
              _buildQuickAmountChip(currentAmount + 2000),
              _buildQuickAmountChip(currentAmount + 3000),
              _buildQuickAmountChip(currentAmount + 4000),
            ],
          ),
      ],
    );
  }

  Widget _buildQuickAmountChip(int amount) {
    return FilterChip(
      label: Text(
        '+${AppCurrency.format(amount.toDouble())}',
        style: const TextStyle(fontSize: 12),
      ),
      onSelected: (_) {
        setState(() {
          _amountController.text = amount.toString();
        });
      },
      backgroundColor: _transactionType == TransactionType.income
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Danh mục', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm mới'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Consumer<CategoryNotifier>(
          builder: (context, categoryNotifier, _) {
            final categories = categoryNotifier.getCategoriesByType(
              _transactionType,
            );

            if (categories.isEmpty) {
              return Text(
                'Không có danh mục cho loại ${_transactionType.label}',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            // Check if current selected category is valid for this type
            final currentCategoryValid = categories.any(
              (c) => c.id == _selectedCategoryId,
            );
            final effectiveValue = currentCategoryValid
                ? _selectedCategoryId
                : categories.first.id;

            if (effectiveValue != _selectedCategoryId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _selectedCategoryId = effectiveValue);
              });
            }

            return Container(
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
                  value: effectiveValue,
                  items: categories.map<DropdownMenuItem<String>>((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Row(
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(category.name)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategoryId = value);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWalletSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ví', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Consumer<WalletNotifier>(
          builder: (context, walletNotifier, _) {
            final wallets = walletNotifier.wallets;

            if (wallets.isEmpty) {
              return Text(
                'Vui lòng tạo ví trước',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            return Container(
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
                  value: _selectedWalletId,
                  items: wallets.map<DropdownMenuItem<String>>((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(wallet.name)),
                          Text(
                            AppCurrency.format(wallet.balance),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedWalletId = value);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ngày', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? DateFormat(AppDateFormat.date).format(_selectedDate!)
                      : 'Chọn ngày',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú (tuỳ chọn)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addTransaction() async {
    // Validation
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền')));
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId == 'add_new') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ví')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final transaction = Transaction(
        id: const Uuid().v4(),
        userId: 'user1',
        walletId: _selectedWalletId!,
        categoryId: _selectedCategoryId!,
        type: _transactionType,
        amount: amount,
        note: _noteController.text,
        date: _selectedDate ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Add transaction
      context.read<TransactionNotifier>().addTransaction(transaction);

      // Update wallet balance
      final wallet = context.read<WalletNotifier>().wallets.firstWhere(
        (w) => w.id == _selectedWalletId,
      );
      final newBalance = _transactionType == TransactionType.income
          ? wallet.balance + amount
          : wallet.balance - amount;

      context.read<WalletNotifier>().updateWallet(
        wallet.copyWith(balance: newBalance),
      );

      widget.onTransactionAdded?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedIcon = '💰';
    TransactionType selectedType = _transactionType;
    bool isLoading = false;

    final commonIcons = [
      '💰',
      '🛒',
      '🍔',
      '🚗',
      '🏠',
      '💊',
      '🎮',
      '📚',
      '✈️',
      '🎬',
      '🎂',
      '👕',
      '💇',
      '🏋️',
      '💇‍♀️',
      '📱',
      '⚽',
      '🎸',
      '💰',
      '📦',
      '🎁',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon selector
                Text(
                  'Biểu tượng',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: commonIcons
                      .map(
                        (icon) => GestureDetector(
                          onTap: () => setState(() => selectedIcon = icon),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedIcon == icon
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.withOpacity(0.3),
                                width: selectedIcon == icon ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.md,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Name input
                Text(
                  'Tên danh mục',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên danh mục',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Type selector
                Text('Loại', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogTypeButton(
                        'Thu nhập',
                        TransactionType.income,
                        Colors.green,
                        selectedType,
                        () => setState(
                          () => selectedType = TransactionType.income,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildDialogTypeButton(
                        'Chi tiêu',
                        TransactionType.expense,
                        Colors.red,
                        selectedType,
                        () => setState(
                          () => selectedType = TransactionType.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading || nameController.text.isEmpty
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      try {
                        final newCategory = Category(
                          id: const Uuid().v4(),
                          userId: 'user1', // Current user
                          name: nameController.text.trim(),
                          icon: selectedIcon,
                          type: selectedType,
                          createdAt: DateTime.now(),
                        );

                        context.read<CategoryNotifier>().addCategory(
                          newCategory,
                        );

                        if (mounted) {
                          this.setState(
                            () => _selectedCategoryId = newCategory.id,
                          );
                          Navigator.pop(context);
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Danh mục đã được thêm'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        }
                      }
                    },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTypeButton(
    String label,
    TransactionType type,
    Color color,
    TransactionType selectedType,
    VoidCallback onTap,
  ) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? color : null,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(String numericValue) {
    if (numericValue.isEmpty) return '';

    // Remove any existing separators
    final cleanValue = numericValue.replaceAll('.', '');

    // Add thousand separators (period) - Vietnamese format
    final reversed = cleanValue.split('').reversed.join();
    final withSeparators = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        withSeparators.add('.');
      }
      withSeparators.add(reversed[i]);
    }

    return withSeparators.reversed.join();
  }
}
