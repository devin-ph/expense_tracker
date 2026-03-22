import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
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
  final TransactionType initialType;
  final bool lockTransactionType;

  const AddTransactionSheet({
    Key? key,
    this.onTransactionAdded,
    this.initialType = TransactionType.expense,
    this.lockTransactionType = false,
  }) : super(key: key);

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AttachmentItem {
  final String value;
  final String displayName;
  final int sizeBytes;

  const _AttachmentItem({
    required this.value,
    required this.displayName,
    required this.sizeBytes,
  });
}

class _AttachmentMeta {
  final String name;
  final bool isImage;
  final Uint8List? imageBytes;

  const _AttachmentMeta({
    required this.name,
    required this.isImage,
    this.imageBytes,
  });
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
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
    'cat_income': [
      'Lương tháng',
      'Lương làm thêm',
      'Phụ cấp',
      'Khác',
    ],
    'cat_bonus': [
      'Thưởng hiệu suất',
      'Thưởng lễ/tết',
      'Hoa hồng',
      'Khác',
    ],
  };

  late TransactionType _transactionType;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _otherExpenseController;
  late FocusNode _amountFocusNode;
  DateTime? _selectedDate;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  String? _selectedExpenseOption;
  String? _selectedIncomeOption;
  final List<_AttachmentItem> _attachments = [];
  bool _isPickingAttachment = false;
  bool _isLoading = false;
  bool _showValidationErrors = false;

  void _handleAmountFocusChange() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _isOtherExpenseSelected =>
      _transactionType == TransactionType.expense &&
      _selectedExpenseOption == 'Khác';

  _AttachmentMeta _parseAttachmentMeta(_AttachmentItem attachment) {
    try {
      final json = jsonDecode(attachment.value);
      if (json is Map<String, dynamic>) {
        final name = (json['name'] as String?) ?? attachment.displayName;
        final ext = ((json['ext'] as String?) ?? '').toLowerCase();
        final data = json['data'] as String?;
        final isImage =
            ext == 'png' ||
            ext == 'jpg' ||
            ext == 'jpeg' ||
            ext == 'gif' ||
            ext == 'webp' ||
            ext == 'bmp';

        if (isImage && data != null && data.isNotEmpty) {
          return _AttachmentMeta(
            name: name,
            isImage: true,
            imageBytes: base64Decode(data),
          );
        }

        return _AttachmentMeta(name: name, isImage: isImage);
      }
    } catch (_) {}

    return _AttachmentMeta(name: attachment.displayName, isImage: false);
  }

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType;
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _otherExpenseController = TextEditingController();
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(_handleAmountFocusChange);
    _selectedDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedWallet = context.read<WalletNotifier>().selectedWallet;
      if (selectedWallet != null) {
        setState(() => _selectedWalletId = selectedWallet.id);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _otherExpenseController.dispose();
    _amountFocusNode.removeListener(_handleAmountFocusChange);
    _amountFocusNode.dispose();
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
        child: Form(
          key: _formKey,
          autovalidateMode: _showValidationErrors
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
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
      ),
    );
  }

  Widget _buildTypeSelector() {
    if (widget.lockTransactionType) {
      final isIncome = _transactionType == TransactionType.income;
      return _buildTypeButton(
        isIncome ? 'Thu nhập' : 'Chi tiêu',
        _transactionType,
        isIncome ? Colors.green : Colors.red,
      );
    }

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
      onTap: widget.lockTransactionType
          ? null
          : () {
              setState(() {
                _transactionType = type;
                _selectedCategoryId = null; // Reset category when type changes
                _selectedExpenseOption = null;
                _selectedIncomeOption = null;
                _otherExpenseController.clear();
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
              color: isSelected ? color : color.withOpacity(0.85),
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
    final walletNotifier = context.watch<WalletNotifier>();
    double? selectedWalletBalance;
    for (final wallet in walletNotifier.wallets) {
      if (wallet.id == _selectedWalletId) {
        selectedWalletBalance = wallet.balance;
        break;
      }
    }
    final suggestionLimit = _transactionType == TransactionType.expense
        ? selectedWalletBalance?.floor()
        : null;
    final suggestionMin =
      (_transactionType == TransactionType.income ||
        _transactionType == TransactionType.expense)
      ? 1000
      : null;
    final suggestionMax = _transactionType == TransactionType.income
      ? 100000000
      : suggestionLimit;
    final suggestions = currentAmount > 0
        ? _buildZeroExpandedSuggestions(
            currentAmount,
        minAmount: suggestionMin,
        maxAmount: suggestionMax,
          )
        : const <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Số tiền', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Stack(
          alignment: Alignment.center,
          children: [
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: TextInputType.number,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '',
                filled: true,
                fillColor: _transactionType == TransactionType.income
                    ? Colors.green.withOpacity(0.05)
                    : Colors.red.withOpacity(0.05),
                suffixText: 'đ',
                suffixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
                // Keep the caret slightly to the right of the fixed centered hint when focused.
                prefixIcon: _amountFocusNode.hasFocus &&
                        _amountController.text.isEmpty
                    ? const SizedBox(width: AppSpacing.xxl)
                    : null,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
              ),
              validator: _validateAmountField,
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
                } else {
                  setState(() {
                    _amountController.value = const TextEditingValue(text: '');
                  });
                }
              },
            ),
            if (_amountController.text.isEmpty)
              IgnorePointer(
                child: Text(
                  '0',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Quick amount suggestions (pills)
        if (suggestions.isNotEmpty)
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: suggestions.map(_buildQuickAmountChip).toList(),
          ),
      ],
    );
  }

  List<int> _buildZeroExpandedSuggestions(
    int baseAmount, {
    int? minAmount,
    int? maxAmount,
  }) {
    final multipliers = [10,100,1000, 10000, 100000,1000000,10000000,100000000];
    final suggestions = <int>{};

    for (final multiplier in multipliers) {
      final amount = baseAmount * multiplier;
      final meetsMin = minAmount == null || amount >= minAmount;
      final meetsMax = maxAmount == null || amount < maxAmount;
      if (meetsMin && meetsMax) {
        suggestions.add(amount);
      }
    }

    return suggestions.toList()..sort();
  }

  Widget _buildQuickAmountChip(int amount) {
    return FilterChip(
      label: Text(
        '${_formatAmount(amount.toString())} ${AppCurrency.symbol}',
        style: const TextStyle(fontSize: 12),
      ),
      onSelected: (_) {
        setState(() {
          _amountController.text = _formatAmount(amount.toString());
        });
      },
      backgroundColor: _transactionType == TransactionType.income
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
    );
  }

  Widget _buildCategorySelection() {
    if (_transactionType == TransactionType.expense) {
      return _buildExpenseCategorySelection();
    }

    if (_transactionType == TransactionType.income) {
      return _buildIncomeCategorySelection();
    }

    return const SizedBox.shrink();
  }

  Widget _buildIncomeCategorySelection() {
    return Consumer<CategoryNotifier>(
      builder: (context, categoryNotifier, _) {
        final categories = categoryNotifier.getCategoriesByType(
          TransactionType.income,
        );

        if (categories.isEmpty) {
          return Text(
            'Không có danh mục cho loại ${_transactionType.label}',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        final hasSelectedCategory = categories.any((c) => c.id == _selectedCategoryId);
        if (_selectedCategoryId != null && !hasSelectedCategory) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedCategoryId = null;
              _selectedIncomeOption = null;
            });
          });
        }

        final selectedCategory = categories.where(
          (category) => category.id == _selectedCategoryId,
        );
        final selectedCategoryId =
            selectedCategory.isNotEmpty ? selectedCategory.first.id : null;
        final selectedOptions = selectedCategoryId != null
            ? (_incomeCategoryOptions[selectedCategoryId] ?? const <String>[])
            : const <String>[];
        final hasSelectedOption = selectedOptions.contains(_selectedIncomeOption);

        if (_selectedIncomeOption != null && !hasSelectedOption) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedIncomeOption = null;
            });
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danh mục', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _showValidationErrors && _hasCategoryError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategoryId,
                  hint: const Text('Chọn nhóm danh mục thu nhập'),
                  items: categories.map<DropdownMenuItem<String>>((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Row(
                        children: [
                          Text(category.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(category.name)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      _selectedIncomeOption = null;
                    });
                  },
                ),
              ),
            ),
            if (_showValidationErrors && _hasCategoryError)
              _buildValidationErrorText('Vui lòng chọn danh mục'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _showValidationErrors && _hasIncomeOptionError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: hasSelectedOption ? _selectedIncomeOption : null,
                  hint: const Text('Chọn chi tiết danh mục thu nhập'),
                  items: selectedOptions.map<DropdownMenuItem<String>>((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: selectedCategoryId == null || selectedOptions.isEmpty
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedIncomeOption = value;
                          });
                        },
                ),
              ),
            ),
            if (_showValidationErrors && _hasIncomeOptionError)
              _buildValidationErrorText('Vui lòng chọn chi tiết danh mục thu nhập'),
          ],
        );
      },
    );
  }

  Widget _buildExpenseCategorySelection() {
    return Consumer<CategoryNotifier>(
      builder: (context, categoryNotifier, _) {
        final categories = categoryNotifier
            .getCategoriesByType(TransactionType.expense)
            .where(
              (category) => _expenseCategoryOptions.containsKey(category.id),
            )
            .toList();

        if (categories.isEmpty) {
          return Text(
            'Không có danh mục cho loại ${_transactionType.label}',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }

        final hasSelectedCategory = categories.any((c) => c.id == _selectedCategoryId);
        if (_selectedCategoryId != null && !hasSelectedCategory) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedCategoryId = null;
              _selectedExpenseOption = null;
            });
          });
        }

        final selectedCategory = categories.where(
          (category) => category.id == _selectedCategoryId,
        );
        final selectedCategoryId =
            selectedCategory.isNotEmpty ? selectedCategory.first.id : null;
        final selectedOptions = selectedCategoryId != null
            ? (_expenseCategoryOptions[selectedCategoryId] ?? const <String>[])
            : const <String>[];
        final hasSelectedOption = selectedOptions.contains(_selectedExpenseOption);

        if (_selectedExpenseOption != null && !hasSelectedOption) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedExpenseOption = null;
              _otherExpenseController.clear();
            });
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danh mục', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _showValidationErrors && _hasCategoryError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategoryId,
                  hint: const Text('Chọn nhóm danh mục chi tiêu'),
                  items: categories.map<DropdownMenuItem<String>>((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Row(
                        children: [
                          Text(category.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(category.name)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      _selectedExpenseOption = null;
                      _otherExpenseController.clear();
                    });
                  },
                ),
              ),
            ),
            if (_showValidationErrors && _hasCategoryError)
              _buildValidationErrorText('Vui lòng chọn danh mục'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _showValidationErrors && _hasExpenseOptionError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: hasSelectedOption ? _selectedExpenseOption : null,
                  hint: const Text('Chọn chi tiết danh mục'),
                  items: selectedOptions.map<DropdownMenuItem<String>>((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: selectedCategoryId == null
                      ? null
                      : (value) async {
                          if (value == null) return;
                          if (value == 'Khác') {
                            final confirmed = await _promptOtherExpenseDetail();
                            if (!confirmed || !mounted) return;
                          }

                          setState(() {
                            _selectedExpenseOption = value;
                            if (value != 'Khác') {
                              _otherExpenseController.clear();
                            }
                          });
                        },
                ),
              ),
            ),
            if (_showValidationErrors && _hasExpenseOptionError)
              _buildValidationErrorText('Vui lòng chọn chi tiết danh mục chi tiêu'),
          ],
        );
      },
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
                  color: _showValidationErrors && _hasWalletError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedWalletId,
                  hint: const Text('Chọn ví'),
                  items: wallets.map<DropdownMenuItem<String>>((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Text(wallet.name),
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
        if (_showValidationErrors && _hasWalletError)
          _buildValidationErrorText('Vui lòng chọn ví'),
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
                color: _showValidationErrors && _hasDateError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).primaryColor.withOpacity(0.3),
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
        if (_showValidationErrors && _hasDateError)
          _buildValidationErrorText('Vui lòng chọn ngày giao dịch'),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ghi chú (tuỳ chọn)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton.icon(
                  onPressed: _isPickingAttachment
                      ? null
                      : () => _pickAttachments(imageOnly: true),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Ảnh'),
                ),
                TextButton.icon(
                  onPressed: _isPickingAttachment
                      ? null
                      : () => _pickAttachments(imageOnly: false),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Tệp'),
                ),
              ],
            ),
          ],
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
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _attachments.map((attachment) {
              final meta = _parseAttachmentMeta(attachment);
              return InputChip(
                avatar: meta.isImage && meta.imageBytes != null
                    ? CircleAvatar(
                        backgroundImage: MemoryImage(meta.imageBytes!),
                      )
                    : Icon(
                        meta.isImage
                            ? Icons.image_outlined
                            : Icons.insert_drive_file_outlined,
                        size: 18,
                      ),
                label: Text(meta.name),
                onDeleted: () {
                  setState(() {
                    _attachments.removeWhere(
                      (item) => item.value == attachment.value,
                    );
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAttachments({required bool imageOnly}) async {
    if (_isPickingAttachment) return;

    setState(() => _isPickingAttachment = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: imageOnly ? FileType.image : FileType.any,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bạn chưa chọn tệp nào')));
        return;
      }

      int addedCount = 0;
      final failedFiles = <String>[];

      setState(() {
        for (final file in result.files) {
          final bytes = file.bytes;
          if (bytes == null || bytes.isEmpty) {
            failedFiles.add(file.name);
            continue;
          }

          if (_attachments.any(
            (item) =>
                item.displayName == file.name && item.sizeBytes == bytes.length,
          )) {
            continue;
          }

          final payload = jsonEncode({
            'name': file.name,
            'size': bytes.length,
            'ext': file.extension,
            'data': base64Encode(bytes),
          });

          _attachments.add(
            _AttachmentItem(
              value: payload,
              displayName: file.name,
              sizeBytes: bytes.length,
            ),
          );
          addedCount++;
        }
      });

      if (addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tải lên $addedCount tệp đính kèm')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có tệp mới để tải lên hoặc tệp không hợp lệ'),
          ),
        );
      }

      if (failedFiles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải lên: ${failedFiles.join(', ')}'),
          ),
        );
      }
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở trình chọn tệp, vui lòng thử lại'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi khi chọn tệp đính kèm')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingAttachment = false);
      }
    }
  }

  Widget _buildExpenseOtherInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin chi tiêu khác',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _otherExpenseController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung chi tiêu khác...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _promptOtherExpenseDetail() async {
    final rootContext = context;
    final result = await showDialog<String>(
      context: rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nhập thông tin chi tiêu khác'),
          content: TextField(
            controller: _otherExpenseController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Mua đồ gia dụng phát sinh',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = _otherExpenseController.text.trim();
                if (value.isEmpty) {
                  final messenger = ScaffoldMessenger.maybeOf(rootContext);
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập thông tin chi tiêu'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return false;
    }

    _otherExpenseController.text = result.trim();
    return true;
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
    setState(() => _showValidationErrors = true);

    final isValidAmount = _formKey.currentState?.validate() ?? false;
    final validationMessage = _validateForm();
    if (!isValidAmount || validationMessage != null) {
      await _focusFirstInvalidField();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(validationMessage ?? 'Vui lòng kiểm tra dữ liệu nhập')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final normalizedAmountText = _amountController.text.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final amount = double.tryParse(normalizedAmountText);

      if (amount == null || amount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Số tiền không hợp lệ')));
        }
        return;
      }

      final transaction = Transaction(
        id: const Uuid().v4(),
        userId: 'user1',
        walletId: _selectedWalletId!,
        categoryId: _selectedCategoryId!,
        type: _transactionType,
        amount: amount,
        note: _buildTransactionNote(),
        attachments: _attachments.map((item) => item.value).toList(),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _focusFirstInvalidField() async {
    if (_hasAmountError) {
      _amountFocusNode.requestFocus();
      return;
    }

    if (_hasOtherExpenseError) {
      await _promptOtherExpenseDetail();
    }
  }

  bool get _hasAmountError {
    final normalizedAmountText = _amountController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    if (normalizedAmountText.isEmpty) {
      return true;
    }

    final amount = double.tryParse(normalizedAmountText);
    return amount == null || amount <= 0;
  }

  bool get _hasCategoryError =>
      _selectedCategoryId == null || _selectedCategoryId == 'add_new';

  bool get _hasWalletError => _selectedWalletId == null;

  bool get _hasDateError => _selectedDate == null;

  bool get _hasExpenseOptionError =>
      _transactionType == TransactionType.expense &&
      _selectedCategoryId != null &&
      (_selectedExpenseOption == null || _selectedExpenseOption!.trim().isEmpty);

  bool get _hasIncomeOptionError {
    if (_transactionType != TransactionType.income || _selectedCategoryId == null) {
      return false;
    }

    final options = _incomeCategoryOptions[_selectedCategoryId!] ?? const <String>[];
    if (options.isEmpty) {
      return false;
    }

    return _selectedIncomeOption == null || _selectedIncomeOption!.trim().isEmpty;
  }

  bool get _hasOtherExpenseError =>
      _isOtherExpenseSelected && _otherExpenseController.text.trim().isEmpty;

  String? _validateAmountField(String? _) {
    final normalizedAmountText = _amountController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    if (normalizedAmountText.isEmpty) {
      return 'Vui lòng nhập số tiền';
    }

    final amount = double.tryParse(normalizedAmountText);
    if (amount == null || amount <= 0) {
      return 'Số tiền không hợp lệ';
    }

    return null;
  }

  Widget _buildValidationErrorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  String? _validateForm() {
    if (_hasAmountError) {
      return _validateAmountField(_amountController.text);
    }

    if (_hasCategoryError) {
      return 'Vui lòng chọn danh mục';
    }

    if (_hasWalletError) {
      return 'Vui lòng chọn ví';
    }

    if (_hasDateError) {
      return 'Vui lòng chọn ngày giao dịch';
    }

    if (_hasExpenseOptionError) {
      return 'Vui lòng chọn chi tiết danh mục chi tiêu';
    }

    if (_hasIncomeOptionError) {
      return 'Vui lòng chọn chi tiết danh mục thu nhập';
    }

    if (_hasOtherExpenseError) {
      return 'Vui lòng nhập thông tin chi tiêu';
    }

    return null;
  }

  String _buildTransactionNote() {
    final rawNote = _noteController.text.trim();
    final otherExpenseDetail = _otherExpenseController.text.trim();
    if (_transactionType == TransactionType.income) {
      if (_selectedIncomeOption == null || _selectedIncomeOption!.isEmpty) {
        return rawNote;
      }

      if (rawNote.isEmpty) {
        return _selectedIncomeOption!;
      }

      return '${_selectedIncomeOption!} - $rawNote';
    }

    if (_selectedExpenseOption == null || _selectedExpenseOption!.isEmpty) {
      return rawNote;
    }

    if (_selectedExpenseOption == 'Khác') {
      if (rawNote.isEmpty) {
        return 'Khác - $otherExpenseDetail';
      }
      return 'Khác - $otherExpenseDetail - $rawNote';
    }

    if (rawNote.isEmpty) {
      return _selectedExpenseOption!;
    }

    return '${_selectedExpenseOption!} - $rawNote';
  }

  void _showAddCategoryDialog() {
    final rootContext = context;
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
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon selector
                Text(
                  'Biểu tượng',
                  style: Theme.of(dialogContext).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: commonIcons
                      .map(
                        (icon) => GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedIcon == icon
                                    ? Theme.of(dialogContext).primaryColor
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
                  style: Theme.of(dialogContext).textTheme.titleSmall,
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
                Text('Loại', style: Theme.of(dialogContext).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogTypeButton(
                        'Thu nhập',
                        TransactionType.income,
                        Colors.green,
                        selectedType,
                        () => setDialogState(
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
                        () => setDialogState(
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading || nameController.text.isEmpty
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final newCategory = Category(
                          id: const Uuid().v4(),
                          userId: 'user1', // Current user
                          name: nameController.text.trim(),
                          icon: selectedIcon,
                          type: selectedType,
                          createdAt: DateTime.now(),
                        );

                        rootContext.read<CategoryNotifier>().addCategory(
                          newCategory,
                        );

                        if (mounted) {
                          setState(
                            () => _selectedCategoryId = newCategory.id,
                          );
                          Navigator.pop(dialogContext);
                          // Show success message
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('Danh mục đã được thêm'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            rootContext,
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
