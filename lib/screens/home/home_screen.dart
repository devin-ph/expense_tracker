import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';
import '../../config/constants.dart';

/// Home Screen - Main dashboard showing wallet info, limits, and today's transactions
/// Implemented by: Lê Tiến Minh
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletNotifier>();
      context.read<TransactionNotifier>();
      context.read<CategoryNotifier>();
      context.read<SpendingLimitNotifier>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
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
    return AppBar(
      title: const Text('Trang chủ'),
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Số dư',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppCurrency.format(selectedWallet.balance),
                          style: textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    // Wallet switch button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
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
                    _buildMonthlyStats(
                      'Thu nhập',
                      monthIncome,
                      Colors.green.shade200,
                      textTheme,
                    ),
                    _buildMonthlyStats(
                      'Chi tiêu',
                      monthExpense,
                      Colors.red.shade200,
                      textTheme,
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

  Widget _buildMonthlyStats(
    String label,
    double amount,
    Color bgColor,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppCurrency.format(amount),
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
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
                  // Navigate to add limit
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
                onPressed: () {
                  _showAllTodayTransactionsModal(context);
                },
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

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = todayTransactions[index];
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
                    );
                  },
                );
              },
        ),
      ],
    );
  }

  void _showAllTodayTransactionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppBorderRadius.xl),
              topRight: Radius.circular(AppBorderRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Giao dịch hôm nay',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              // Transaction list
              Expanded(
                child:
                    Consumer3<
                      TransactionNotifier,
                      CategoryNotifier,
                      WalletNotifier
                    >(
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
                              return Center(
                                child: Text(
                                  'Chưa có giao dịch nào hôm nay',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: scrollController,
                              itemCount: todayTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = todayTransactions[index];
                                final category = categoryNotifier
                                    .getCategoryById(transaction.categoryId);
                                if (category == null) return const SizedBox();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: TransactionCard(
                                    categoryName: category.name,
                                    categoryIcon: category.icon,
                                    amount: transaction.amount,
                                    note: transaction.note,
                                    dateTime: transaction.date,
                                    isIncome:
                                        transaction.type ==
                                        TransactionType.income,
                                  ),
                                );
                              },
                            );
                          },
                    ),
              ),
            ],
          ),
        ),
      ),
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
