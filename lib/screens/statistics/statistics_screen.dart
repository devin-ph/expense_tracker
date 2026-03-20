import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../config/constants.dart';

/// Statistics Screen - Shows transaction statistics with charts
/// Implemented by: Phạm Hoàng Thế Vinh
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedMonthIndex = DateTime.now().month - 1;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            // Year/Month selector
            _buildYearMonthSelector(),
            const SizedBox(height: AppSpacing.xl),
            // Statistics summary
            _buildSummary(),
            const SizedBox(height: AppSpacing.xl),
            // Line chart - Monthly transactions
            _buildLineChart(),
            const SizedBox(height: AppSpacing.xl),
            // Pie chart - Category breakdown
            _buildPieChart(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildYearMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Năm', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _selectedYear--),
                  icon: const Icon(Icons.chevron_left),
                  label: const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                _selectedYear.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedYear < DateTime.now().year) {
                      setState(() => _selectedYear++);
                    }
                  },
                  icon: const Icon(Icons.chevron_right),
                  label: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Tháng', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthName = 'T${index + 1}';
                final isSelected = _selectedMonthIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: FilterChip(
                    label: Text(monthName),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedMonthIndex = index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Consumer<TransactionNotifier>(
      builder: (context, transactionNotifier, _) {
        final selectedMonth = _selectedMonthIndex + 1;
        final transactions = transactionNotifier.transactions
            .where(
              (t) =>
                  t.date.month == selectedMonth && t.date.year == _selectedYear,
            )
            .toList();

        final income = transactions
            .where((t) => t.type == TransactionType.income)
            .fold<double>(0, (sum, t) => sum + t.amount);

        final expense = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold<double>(0, (sum, t) => sum + t.amount);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Thu nhập',
                  AppCurrency.format(income),
                  Colors.green,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildSummaryCard(
                  'Chi tiêu',
                  AppCurrency.format(expense),
                  Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
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
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Consumer<TransactionNotifier>(
      builder: (context, transactionNotifier, _) {
        final data = _getMonthlyChartData(transactionNotifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Chi tiêu theo tháng',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: data.isEmpty
                          ? 1
                          : data.reduce((a, b) => a > b ? a : b) / 4,
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < 12) {
                              return Text('T${value.toInt() + 1}');
                            }
                            return const SizedBox();
                          },
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value / 1000000).toStringAsFixed(1)}M',
                            );
                          },
                          reservedSize: 50,
                          interval: data.isEmpty
                              ? 1
                              : data.reduce((a, b) => a > b ? a : b) / 4,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          12,
                          (i) => FlSpot(i.toDouble(), data[i]),
                        ),
                        isCurved: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.red.withOpacity(0.2),
                        ),
                        color: Colors.red,
                        barWidth: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Không có dữ liệu cho tháng được chọn',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPieChart() {
    return Consumer2<TransactionNotifier, CategoryNotifier>(
      builder: (context, transactionNotifier, categoryNotifier, _) {
        final selectedMonth = _selectedMonthIndex + 1;
        final transactions = transactionNotifier.transactions
            .where(
              (t) =>
                  t.date.month == selectedMonth &&
                  t.date.year == _selectedYear &&
                  t.type == TransactionType.expense,
            )
            .toList();

        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Không có dữ liệu chi tiêu cho tháng này',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        // Group by category
        final categoryMap = <String, double>{};
        for (final transaction in transactions) {
          final category = categoryNotifier.getCategoryById(
            transaction.categoryId,
          );
          final categoryName = category?.name ?? 'Khác';
          categoryMap[categoryName] =
              (categoryMap[categoryName] ?? 0) + transaction.amount;
        }

        final total = categoryMap.values.fold<double>(
          0,
          (sum, amount) => sum + amount,
        );
        final colors = [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.blue,
          Colors.green,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Chi tiêu theo danh mục',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: List.generate(categoryMap.length, (i) {
                      final entry = categoryMap.entries.toList()[i];
                      final percentage = (entry.value / total) * 100;
                      return PieChartSectionData(
                        value: entry.value,
                        title: '${percentage.toStringAsFixed(0)}%',
                        color: colors[i % colors.length],
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categoryMap.entries.toList().asMap().entries.map((
                  entry,
                ) {
                  final i = entry.key;
                  final mapEntry = entry.value;
                  final percentage = (mapEntry.value / total) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(mapEntry.key)),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  List<double> _getMonthlyChartData(TransactionNotifier notifier) {
    return List.generate(12, (monthIndex) {
      return notifier.transactions
          .where(
            (t) =>
                t.date.month == monthIndex + 1 &&
                t.date.year == _selectedYear &&
                t.type == TransactionType.expense,
          )
          .fold<double>(0, (sum, t) => sum + t.amount);
    });
  }
}
