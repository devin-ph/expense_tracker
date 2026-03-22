import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/index.dart';
import '../../providers/index.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê'), elevation: 0),
      body: Consumer2<TransactionNotifier, CategoryNotifier>(
        builder: (context, transactionNotifier, categoryNotifier, _) {
          final monthlyTransactions = _transactionsInMonth(
            transactionNotifier.transactions,
            _selectedYear,
            _selectedMonth,
          );
          final snapshot = _buildSnapshot(monthlyTransactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildSummarySection(snapshot),
                const SizedBox(height: AppSpacing.lg),
                _buildIncomeExpenseBarChart(
                  transactionNotifier.transactions,
                  year: _selectedYear,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildCategoryPieChart(monthlyTransactions, categoryNotifier),
                const SizedBox(height: AppSpacing.lg),
                _buildHeatmapChart(
                  monthlyTransactions,
                  year: _selectedYear,
                  month: _selectedMonth,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(_StatsSnapshot snapshot) {
    final cards = [
      _SummaryMetric(
        'Thu nhập',
        AppCurrency.format(snapshot.income),
        Colors.green,
      ),
      _SummaryMetric(
        'Chi tiêu',
        AppCurrency.format(snapshot.expense),
        Colors.red,
      ),
    ];

    return _buildSectionCard(
      title: 'Tổng quan - Tháng $_selectedMonth/$_selectedYear',
      child: GridView.builder(
        itemCount: cards.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.8,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemBuilder: (context, index) {
          final metric = cards[index];
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(color: metric.color.withValues(alpha: 0.3)),
              color: metric.color.withValues(alpha: 0.08),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  metric.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: metric.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIncomeExpenseBarChart(
    List<Transaction> transactions, {
    required int year,
  }) {
    final income = List<double>.filled(12, 0);
    final expense = List<double>.filled(12, 0);

    for (final tx in transactions) {
      if (tx.date.year != year) continue;

      final month = tx.date.month - 1;
      if (tx.type == TransactionType.income) {
        income[month] += tx.amount;
      } else {
        expense[month] += tx.amount;
      }
    }

    final maxY = math.max(
      1.0,
      math.max(income.reduce(math.max), expense.reduce(math.max)),
    );

    return _buildSectionCard(
      title: 'Thu / Chi theo từng tháng - Năm $year',
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions) {
                  return;
                }
                final index = response?.spot?.touchedBarGroupIndex;
                if (index == null) {
                  return;
                }
                final month = index + 1;
                if (month == _selectedMonth) {
                  return;
                }
                setState(() {
                  _selectedMonth = month;
                });
              },
            ),
            minY: 0,
            maxY: maxY * 1.2,
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.spaceAround,
            barGroups: List.generate(12, (i) {
              final isSelected = (i + 1) == _selectedMonth;
              return BarChartGroupData(
                x: i,
                barsSpace: 3,
                barRods: [
                  BarChartRodData(
                    toY: income[i],
                    width: 7,
                    color: isSelected
                        ? Colors.green
                        : Colors.green.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: expense[i],
                    width: 7,
                    color: isSelected
                        ? Colors.red
                        : Colors.red.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: math.max(1, maxY / 4),
                  getTitlesWidget: (value, _) => Text(_compactAmount(value)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) => Text('T${value.toInt() + 1}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(
    List<Transaction> transactions,
    CategoryNotifier categoryNotifier,
  ) {
    final categoryMap = <String, double>{};
    final expenseTx = transactions.where(
      (t) => t.type == TransactionType.expense,
    );
    for (final tx in expenseTx) {
      final name =
          categoryNotifier.getCategoryById(tx.categoryId)?.name ?? 'Khác';
      categoryMap[name] = (categoryMap[name] ?? 0) + tx.amount;
    }

    final total = categoryMap.values.fold<double>(0, (sum, item) => sum + item);
    final colorPalette = <Color>[
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.teal,
    ];

    return _buildSectionCard(
      title: 'Chi tiêu theo danh mục - Tháng $_selectedMonth/$_selectedYear',
      child: categoryMap.isEmpty
          ? const Text('Không có dữ liệu chi tiêu trong tháng đã chọn.')
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 34,
                      sections: categoryMap.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final percent = total == 0
                                ? 0
                                : (item.value / total) * 100;
                            return PieChartSectionData(
                              value: item.value,
                              title: '${percent.toStringAsFixed(0)}%',
                              color: colorPalette[idx % colorPalette.length],
                              radius: 56,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...categoryMap.entries.toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final percent = total == 0 ? 0 : (item.value / total) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorPalette[idx % colorPalette.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(item.key)),
                        Text('${percent.toStringAsFixed(1)}%'),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildHeatmapChart(
    List<Transaction> transactions, {
    required int year,
    required int month,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final days = monthEnd.day;
    final netByDay = List<double>.filled(days, 0);

    for (final tx in transactions) {
      if (tx.date.month != monthStart.month ||
          tx.date.year != monthStart.year) {
        continue;
      }
      final index = tx.date.day - 1;
      if (tx.type == TransactionType.income) {
        netByDay[index] += tx.amount;
      } else {
        netByDay[index] -= tx.amount;
      }
    }

    final maxAbsNet = netByDay.isEmpty
        ? 1.0
        : math.max(1.0, netByDay.map((value) => value.abs()).reduce(math.max));

    return _buildSectionCard(
      title: 'Mức độ thu/chi - Tháng $month/$year',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tháng ${monthStart.month}/${monthStart.year}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(days, (index) {
              final net = netByDay[index];
              final intensity = ((net.abs() / maxAbsNet).clamp(
                0.0,
                1.0,
              )).toDouble();
              final cellColor = _heatmapColor(net, intensity, isDark: isDark);
              return Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _heatmapTextColor(cellColor),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _heatmapColor(double net, double intensity, {required bool isDark}) {
    final positiveLight = isDark
        ? const Color(0xFF14532D)
        : const Color(0xFFDCFCE7);
    final positiveMid = isDark
        ? const Color(0xFF16A34A)
        : const Color(0xFF86EFAC);
    final positiveDark = isDark
        ? const Color(0xFF22C55E)
        : const Color(0xFF15803D);
    final negativeLight = isDark
        ? const Color(0xFF7F1D1D)
        : const Color(0xFFFEE2E2);
    final negativeMid = isDark
        ? const Color(0xFFDC2626)
        : const Color(0xFFFCA5A5);
    final negativeDark = isDark
        ? const Color(0xFFEF4444)
        : const Color(0xFFB91C1C);
    final neutral = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    if (net == 0) {
      return neutral;
    }

    if (net > 0) {
      if (intensity <= 0.5) {
        return Color.lerp(positiveLight, positiveMid, intensity / 0.5) ??
            positiveMid;
      }
      return Color.lerp(positiveMid, positiveDark, (intensity - 0.5) / 0.5) ??
          positiveDark;
    }

    if (intensity <= 0.5) {
      return Color.lerp(negativeLight, negativeMid, intensity / 0.5) ??
          negativeMid;
    }
    return Color.lerp(negativeMid, negativeDark, (intensity - 0.5) / 0.5) ??
        negativeDark;
  }

  Color _heatmapTextColor(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  Widget _heatmapLegendItem({required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }

  List<Transaction> _transactionsInMonth(
    List<Transaction> transactions,
    int year,
    int month,
  ) {
    return transactions.where((tx) {
      return tx.date.year == year && tx.date.month == month;
    }).toList();
  }

  _StatsSnapshot _buildSnapshot(List<Transaction> current) {
    final income = _sumByType(current, TransactionType.income);
    final expense = _sumByType(current, TransactionType.expense);

    return _StatsSnapshot(income: income, expense: expense);
  }

  double _sumByType(List<Transaction> tx, TransactionType type) {
    return tx
        .where((e) => e.type == type)
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  String _compactAmount(double value) {
    final absValue = value.abs();
    if (absValue >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (absValue >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _SummaryMetric {
  _SummaryMetric(this.title, this.value, this.color);

  final String title;
  final String value;
  final Color color;
}

class _StatsSnapshot {
  _StatsSnapshot({required this.income, required this.expense});

  final double income;
  final double expense;
}
