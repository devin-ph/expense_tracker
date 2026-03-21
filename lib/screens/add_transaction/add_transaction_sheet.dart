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

  late TransactionType _transactionType;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _otherExpenseController;
  DateTime? _selectedDate;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  String? _selectedExpenseOption;
  String? _expandedExpenseGroupId;
  final List<_AttachmentItem> _attachments = [];
  bool _isPickingAttachment = false;
  bool _isLoading = false;

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
    _otherExpenseController.dispose();
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
                if (type == TransactionType.income) {
                  _selectedExpenseOption = null;
                  _expandedExpenseGroupId = null;
                  _otherExpenseController.clear();
                }
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
            children: _buildZeroExpandedSuggestions(
              currentAmount,
            ).map(_buildQuickAmountChip).toList(),
          ),
      ],
    );
  }

  List<int> _buildZeroExpandedSuggestions(int baseAmount) {
    final multipliers = [10, 100, 1000, 10000, 100000];
    final suggestions = <int>{};

    for (final multiplier in multipliers) {
      suggestions.add(baseAmount * multiplier);
    }

    return suggestions.toList()..sort();
  }

  Widget _buildQuickAmountChip(int amount) {
    return FilterChip(
      label: Text(
        AppCurrency.format(amount.toDouble()),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Danh mục', style: Theme.of(context).textTheme.titleMedium),
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

        final selectedCategory = categories.where(
          (c) => c.id == _selectedCategoryId,
        );
        if (_selectedCategoryId == null || selectedCategory.isEmpty) {
          final firstCategoryId = categories.first.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedCategoryId = firstCategoryId;
              _selectedExpenseOption =
                  _expenseCategoryOptions[firstCategoryId]?.first;
            });
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Danh mục', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Column(
                children: categories.map((category) {
                  final isExpanded = _expandedExpenseGroupId == category.id;
                  final isSelected = _selectedCategoryId == category.id;
                  final options =
                      _expenseCategoryOptions[category.id] ?? const <String>[];

                  return ExpansionTile(
                    initiallyExpanded: isExpanded,
                    leading: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(category.name),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedExpenseGroupId = expanded ? category.id : null;
                      });
                    },
                    children: options.map((option) {
                      final optionSelected =
                          isSelected && _selectedExpenseOption == option;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        title: Text(option),
                        trailing: optionSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 18,
                              )
                            : null,
                        onTap: () async {
                          if (option == 'Khác') {
                            final confirmed = await _promptOtherExpenseDetail();
                            if (!confirmed || !mounted) return;
                          }

                          setState(() {
                            _selectedCategoryId = category.id;
                            _selectedExpenseOption = option;
                            _expandedExpenseGroupId = null;
                            if (option != 'Khác') {
                              _otherExpenseController.clear();
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
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
    final result = await showDialog<String>(
      context: context,
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
                  ScaffoldMessenger.of(context).showSnackBar(
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

    if (_transactionType == TransactionType.expense &&
        (_selectedExpenseOption == null || _selectedExpenseOption!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn chi tiết danh mục chi tiêu'),
        ),
      );
      return;
    }

    if (_isOtherExpenseSelected &&
        _otherExpenseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập thông tin chi tiêu')),
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
      setState(() => _isLoading = false);
    }
  }

  String _buildTransactionNote() {
    final rawNote = _noteController.text.trim();
    final otherExpenseDetail = _otherExpenseController.text.trim();
    if (_transactionType != TransactionType.expense ||
        _selectedExpenseOption == null ||
        _selectedExpenseOption!.isEmpty) {
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
