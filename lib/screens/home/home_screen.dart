import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';
import '../../config/constants.dart';

/// Home Screen - Main dashboard showing wallet info, limits, and today's transactions
/// Implemented by: Lê Tiến Minh
class HomeScreen extends StatefulWidget {
  final VoidCallback? onAvatarTap;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onAllTransactionsTap;

  const HomeScreen({
    Key? key,
    this.onAvatarTap,
    this.onBalanceTap,
    this.onAllTransactionsTap,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _AddLimitPayload {
  final String categoryId;
  final double amount;

  _AddLimitPayload({required this.categoryId, required this.amount});
}

enum _LimitActionType { reset, delete, update }

class _LimitActionPayload {
  final _LimitActionType action;
  final double? amount;

  _LimitActionPayload({required this.action, this.amount});
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;
  bool _isBalanceHovered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletNotifier>();
      context.read<TransactionNotifier>();
      context.read<CategoryNotifier>();
      context.read<SpendingLimitNotifier>();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final isCollapsed =
        _scrollController.hasClients && _scrollController.offset > 12;
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
    }
  }

  Future<void> _showAddSpendingLimitDialog(BuildContext context) async {
    final rootContext = context;
    final expenseCategories = rootContext
        .read<CategoryNotifier>()
        .getCategoriesByType(TransactionType.expense);
    final limitNotifier = rootContext.read<SpendingLimitNotifier>();
    final currentUserId =
        rootContext.read<AuthNotifier>().currentUser?.id ?? 'user1';
    final availableCategories = expenseCategories
        .where(
          (category) => limitNotifier.getLimitByCategoryId(category.id) == null,
        )
        .toList();

    if (availableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tất cả danh mục chi tiêu đã có hạn mức')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? selectedCategoryId;
    String amountText = '';

    final result = await showDialog<_AddLimitPayload>(
      context: rootContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            final canSave =
                selectedCategoryId != null && amountText.trim().isNotEmpty;

            return AlertDialog(
              title: const Text('Thêm hạn mức chi tiêu'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                        ),
                        items: availableCategories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(
                                  '${category.icon} ${category.name}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn danh mục';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Hạn mức',
                          hintText: 'Nhập hạn mức',
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            amountText = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập hạn mức';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Hạn mức không hợp lệ';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: canSave
                      ? () {
                          if (!(formKey.currentState?.validate() ?? false) ||
                              selectedCategoryId == null) {
                            return;
                          }

                          Navigator.pop(
                            dialogContext,
                            _AddLimitPayload(
                              categoryId: selectedCategoryId!,
                              amount: double.parse(amountText.trim()),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    final now = DateTime.now();

    limitNotifier.addLimit(
      SpendingLimit(
        id: 'limit_${now.millisecondsSinceEpoch}',
        userId: currentUserId,
        categoryId: result.categoryId,
        limitAmount: result.amount,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Không'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Có'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _showInfoDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLimitDetailDialog(
    BuildContext context,
    SpendingLimit limit,
    Category category,
  ) async {
    final limitNotifier = context.read<SpendingLimitNotifier>();
    final amountController = TextEditingController(
      text: limit.limitAmount.toStringAsFixed(0),
    );
    final amountFocusNode = FocusNode();
    bool isEditing = false;

    final result = await showDialog<_LimitActionPayload>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveChangeAndClose() async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hạn mức không hợp lệ')),
                );
                return;
              }

              Navigator.pop(
                dialogContext,
                _LimitActionPayload(
                  action: _LimitActionType.update,
                  amount: amount,
                ),
              );
            }

            return WillPopScope(
              onWillPop: () async {
                if (!isEditing) return true;
                await saveChangeAndClose();
                return false;
              },
              child: AlertDialog(
                title: const Text('Chi tiết hạn mức'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        enabled: false,
                        initialValue: '${category.icon} ${category.name}',
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: amountController,
                        focusNode: amountFocusNode,
                        enabled: isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(labelText: 'Hạn mức'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isEditing
                        ? null
                        : () async {
                            final confirmed = await _showConfirmDialog(
                              context,
                              'Reset hạn mức',
                              'Bạn có muốn reset lại hạn mức cho danh mục: ${category.name}?',
                            );
                            if (!confirmed || !context.mounted) return;
                            Navigator.pop(
                              dialogContext,
                              _LimitActionPayload(
                                action: _LimitActionType.reset,
                              ),
                            );
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isEditing
                        ? null
                        : () async {
                            final confirmed = await _showConfirmDialog(
                              context,
                              'Xóa hạn mức',
                              'Bạn có chắc chắn muốn xóa hạn mức này?',
                            );
                            if (!confirmed || !context.mounted) return;
                            Navigator.pop(
                              dialogContext,
                              _LimitActionPayload(
                                action: _LimitActionType.delete,
                              ),
                            );
                          },
                    child: const Text('Xóa'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      if (!isEditing) {
                        setDialogState(() {
                          isEditing = true;
                        });
                        await Future<void>.delayed(Duration.zero);
                        amountFocusNode.requestFocus();
                        return;
                      }

                      await saveChangeAndClose();
                    },
                    child: Text(isEditing ? 'Lưu thay đổi' : 'Thay đổi'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    amountFocusNode.dispose();

    if (!mounted || result == null) return;

    final now = DateTime.now();
    switch (result.action) {
      case _LimitActionType.reset:
        limitNotifier.updateLimit(
          limit.copyWith(limitAmount: 0, updatedAt: now),
        );
        break;
      case _LimitActionType.delete:
        limitNotifier.deleteLimit(limit.id);
        break;
      case _LimitActionType.update:
        limitNotifier.updateLimit(
          limit.copyWith(
            limitAmount: result.amount ?? limit.limitAmount,
            updatedAt: now,
          ),
        );
        await _showInfoDialog(
          context,
          'Đã thay đổi hạn mức',
          'Đã thay đổi hạn mức của danh mục ${category.name}.',
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletCard(context),
            const SizedBox(height: AppSpacing.lg),
            _buildLimitsSection(context),
            const SizedBox(height: AppSpacing.lg),
            _buildTodayTransactionsSection(context),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final headerBgColor = _isHeaderCollapsed
        ? theme.primaryColor
        : const Color(0xFFF8F9FA);
    final headerTextColor = _isHeaderCollapsed
        ? Colors.white
        : const Color(0xFF333333);
    final avatarBgColor = _isHeaderCollapsed
        ? Colors.white.withOpacity(0.2)
        : theme.primaryColor.withOpacity(0.12);

    return AppBar(
      toolbarHeight: 88,
      titleSpacing: AppSpacing.lg,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Consumer<AuthNotifier>(
        builder: (context, authNotifier, _) {
          final user = authNotifier.currentUser;
          final userName = user?.name ?? 'Người dùng';
          final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: _isHeaderCollapsed
                    ? Colors.transparent
                    : const Color(0xFFE9ECEF),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onAvatarTap,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarBgColor,
                    backgroundImage: hasPhoto
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: hasPhoto
                        ? null
                        : Icon(Icons.person, size: 20, color: headerTextColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xin chào, $userName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: headerTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            size: 14,
                            color: headerTextColor,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Hãy lưu lại các giao dịch của bạn trong ngày nhé',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: headerTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: _isHeaderCollapsed ? theme.primaryColor : headerTextColor,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const walletTextPrimary = Color(0xFF333333);
    const walletTextSecondary = Color(0xFF5C5C5C);

    return Consumer<WalletNotifier>(
      builder: (context, walletNotifier, _) {
        final selectedWallet = walletNotifier.selectedWallet;
        if (selectedWallet == null) {
          return const SizedBox();
        }

        final transactionNotifier = context.read<TransactionNotifier>();
        final walletTransactions = transactionNotifier.getTransactionsByWallet(
          selectedWallet.id,
        );
        final monthStart = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          1,
        );
        final monthEnd = DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          0,
        );

        final monthTransactions = walletTransactions.where((t) {
          return t.date.isAfter(monthStart) &&
              t.date.isBefore(monthEnd.add(const Duration(days: 1)));
        }).toList();

        final monthIncome = monthTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final monthExpense = monthTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

        return Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A65).withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet name and balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedWallet.name,
                          style: textTheme.titleLarge?.copyWith(
                            color: walletTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Số dư',
                          style: textTheme.bodySmall?.copyWith(
                            color: walletTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _isBalanceHovered = true),
                          onExit: (_) =>
                              setState(() => _isBalanceHovered = false),
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: widget.onBalanceTap,
                            child: Text(
                              AppCurrency.format(selectedWallet.balance),
                              style: textTheme.displaySmall?.copyWith(
                                color: walletTextPrimary,
                                fontWeight: FontWeight.w700,
                                decoration: _isBalanceHovered
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Wallet switch button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: walletTextPrimary,
                        ),
                        onPressed: () {
                          _showWalletSelector(context, walletNotifier.wallets);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // Monthly income and expense
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMonthlyStats('Thu nhập', monthIncome, textTheme),
                    _buildMonthlyStats('Chi tiêu', monthExpense, textTheme),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyStats(String label, double amount, TextTheme textTheme) {
    const walletTextPrimary = Color(0xFF333333);
    const walletTextSecondary = Color(0xFF5C5C5C);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: walletTextSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppCurrency.format(amount),
            style: textTheme.titleMedium?.copyWith(
              color: walletTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hạn mức chi tiêu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  _showAddSpendingLimitDialog(context);
                },
                child: const Text('+ Thêm'),
              ),
            ],
          ),
        ),
        Consumer3<SpendingLimitNotifier, TransactionNotifier, CategoryNotifier>(
          builder:
              (
                context,
                limitNotifier,
                transactionNotifier,
                categoryNotifier,
                _,
              ) {
                final limits = limitNotifier.limits;
                if (limits.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      'Chưa có hạn mức nào',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: limits.length,
                  itemBuilder: (context, index) {
                    final limit = limits[index];
                    final category = categoryNotifier.getCategoryById(
                      limit.categoryId,
                    );
                    if (category == null) return const SizedBox();

                    final walletId = context
                        .read<WalletNotifier>()
                        .selectedWallet
                        ?.id;
                    final spent = transactionNotifier
                        .getTransactionsByDateRange(
                          DateTime.now().copyWith(day: 1),
                          DateTime.now().copyWith(
                            month: DateTime.now().month + 1,
                            day: 0,
                          ),
                          walletId: walletId,
                        )
                        .where(
                          (t) =>
                              t.categoryId == limit.categoryId &&
                              t.type == TransactionType.expense,
                        )
                        .fold(0.0, (sum, t) => sum + t.amount);

                    return SpendingProgressBar(
                      categoryName: category.name,
                      categoryIcon: category.icon,
                      spent: spent,
                      limit: limit.limitAmount,
                      onTap: () {
                        _showLimitDetailDialog(context, limit, category);
                      },
                    );
                  },
                );
              },
        ),
      ],
    );
  }

  Widget _buildTodayTransactionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giao dịch hôm nay',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: widget.onAllTransactionsTap,
                child: const Text('Tất cả'),
              ),
            ],
          ),
        ),
        Consumer3<TransactionNotifier, CategoryNotifier, WalletNotifier>(
          builder:
              (
                context,
                transactionNotifier,
                categoryNotifier,
                walletNotifier,
                _,
              ) {
                final walletId = walletNotifier.selectedWallet?.id;
                final todayTransactions = transactionNotifier
                    .getTodayTransactions(walletId: walletId);

                if (todayTransactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      'Chưa có giao dịch nào hôm nay',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final displayedTransactions = todayTransactions
                    .take(5)
                    .toList();
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = displayedTransactions[index];
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
                    );
                  },
                );
              },
        ),
      ],
    );
  }

  void _showWalletSelector(BuildContext context, List<Wallet> wallets) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chọn ví', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            ...wallets.map((wallet) {
              return ListTile(
                title: Text(wallet.name),
                subtitle: Text(AppCurrency.format(wallet.balance)),
                onTap: () {
                  context.read<WalletNotifier>().selectWallet(wallet);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
