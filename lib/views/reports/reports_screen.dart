import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../models/transaction_model.dart' as app_models;
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../themes/app_theme.dart';
import '../../viewmodels/budget_viewmodel.dart';
import 'widgets/report_card.dart';
import 'widgets/report_period_selector.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedIndex = 3; // Reports tab selected
  String _selectedPeriod = 'Monthly';
  // Month selection notifier (first day of the month)
  final ValueNotifier<DateTime> _selectedMonthNotifier = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month, 1),
  );
  
  @override
  void initState() {
    super.initState();
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    transactionViewModel.loadTransactionsByMonth(_selectedMonthNotifier.value);
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final String route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
  }

  @override
  void dispose() {
    _selectedMonthNotifier.dispose();
    super.dispose();
  }

  Widget _buildMonthSelector() {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _selectedMonthNotifier,
      builder: (context, selectedMonth, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Month:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                DropdownButton<DateTime>(
                  value: selectedMonth,
                  items: _buildMonthDropdownItems(),
                  onChanged: (DateTime? newValue) {
                    if (newValue == null) return;
                    _selectedMonthNotifier.value = newValue;
                    // Reload transactions for selected month
                    final txnVM = Provider.of<TransactionViewModel>(context, listen: false);
                    txnVM.loadTransactionsByMonth(newValue);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<DropdownMenuItem<DateTime>> _buildMonthDropdownItems() {
    final List<DropdownMenuItem<DateTime>> items = [];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      items.add(
        DropdownMenuItem(
          value: month,
          child: Text(DateFormat('MMMM yyyy').format(month)),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share reports
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportPeriodSelector(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: _onPeriodChanged,
            ),
            const SizedBox(height: 16),
            _buildMonthSelector(),
            const SizedBox(height: 16),
            _buildIncomeVsExpensesCard(),
            const SizedBox(height: 16),
            _buildCategoryBreakdownCard(),
            const SizedBox(height: 16),
            _buildMonthlyTrendCard(),
            const SizedBox(height: 16),
            _buildBudgetPerformanceCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeVsExpensesCard() {
    return Consumer<TransactionViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const ReportCard(
            title: 'Income vs Expenses',
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        double income = 0;
        double expenses = 0;
        for (final tx in viewModel.transactions) {
          if (tx.type == app_models.TransactionType.income) {
            income += tx.amount;
          } else if (tx.type == app_models.TransactionType.expense) {
            expenses += tx.amount;
          }
        }
        final balance = income - expenses;

        // Empty-state
        if (income == 0 && expenses == 0) {
          return const ReportCard(
            title: 'Income vs Expenses',
            child: SizedBox(
              height: 120,
              child: Center(child: Text('No transactions for selected period.')),
            ),
          );
        }

        return ReportCard(
          title: 'Income vs Expenses',
          child: SizedBox(
            height: 250,
            child: _buildIncomeExpensesChart(income, expenses, balance),
          ),
        );
      },
    );
  }

  Widget _buildIncomeExpensesChart(double income, double expenses, double balance) {
    final _ = NumberFormat.currency(symbol: '\$');
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: income > expenses ? income * 1.2 : expenses * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      if (value == 0) {
                        text = 'Income';
                      } else if (value == 1) {
                        text = 'Expenses';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: income,
                      color: AppTheme.incomeColor,
                      width: 40,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: expenses,
                      color: AppTheme.expenseColor,
                      width: 40,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryItem('Income', income, AppTheme.incomeColor),
              const SizedBox(height: 16),
              _buildSummaryItem('Expenses', expenses, AppTheme.expenseColor),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildSummaryItem('Balance', balance, AppTheme.primaryColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard() {
    return Consumer<TransactionViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const ReportCard(
            title: 'Spending by Category',
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Aggregate expense totals by category
        final Map<String, double> categoryTotals = {};
        for (final tx in viewModel.transactions) {
          if (tx.type == app_models.TransactionType.expense) {
            categoryTotals.update(tx.category, (value) => value + tx.amount, ifAbsent: () => tx.amount);
          }
        }

        if (categoryTotals.isEmpty) {
          return const ReportCard(
            title: 'Spending by Category',
            child: SizedBox(
              height: 120,
              child: Center(child: Text('No expense data for selected period.')),
            ),
          );
        }

        return ReportCard(
          title: 'Spending by Category',
          child: SizedBox(
            height: 250,
            child: _buildCategoryChart(categoryTotals),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChart(Map<String, double> categoryData) {

    
    final totalSpending = categoryData.values.fold(0.0, (sum, value) => sum + value);
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: categoryData.entries.map((entry) {
                final category = entry.key;
                final value = entry.value;
                final percentage = (value / totalSpending) * 100;
                
                return PieChartSectionData(
                  color: _getCategoryColor(category),
                  value: value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categoryData.entries.map((entry) {
              final category = entry.key;
              final amount = entry.value;
              final percentage = (amount / totalSpending) * 100;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendCard() {
    return Consumer<TransactionViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const ReportCard(
            title: 'Monthly Trend',
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Group transactions by day-of-month
        final Map<int, double> incomeByDay = {};
        final Map<int, double> expenseByDay = {};
        for (final tx in viewModel.transactions) {
          final day = tx.date.day;
          if (tx.type == app_models.TransactionType.income) {
            incomeByDay.update(day, (v) => v + tx.amount, ifAbsent: () => tx.amount);
          } else if (tx.type == app_models.TransactionType.expense) {
            expenseByDay.update(day, (v) => v + tx.amount, ifAbsent: () => tx.amount);
          }
        }

        if (incomeByDay.isEmpty && expenseByDay.isEmpty) {
          return const ReportCard(
            title: 'Monthly Trend',
            child: SizedBox(
              height: 120,
              child: Center(child: Text('No data for selected month.')),
            ),
          );
        }

        // Convert to FlSpot sorted by day
        final incomeSpots = incomeByDay.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));
        final expenseSpots = expenseByDay.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));

        return ReportCard(
          title: 'Monthly Trend',
          child: SizedBox(
            height: 250,
            child: _buildMonthlyTrendChart(incomeSpots, expenseSpots),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTrendChart(List<FlSpot> incomeSpots, List<FlSpot> expenseSpots) {

    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                const months = ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'];
                if (value >= 0 && value < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[value.toInt()],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 6000,
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: AppTheme.incomeColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.incomeColor.withAlpha((0.1 * 255).toInt()),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: AppTheme.expenseColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.expenseColor.withAlpha((0.1 * 255).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPerformanceCard() {
    return Consumer2<TransactionViewModel, BudgetViewModel>(
      builder: (context, txVm, budgetVm, _) {
        if (txVm.isLoading || budgetVm.isLoading) {
          return const ReportCard(
            title: 'Budget Performance',
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Map category -> spent
        final Map<String, double> spentByCategory = {};
        for (final tx in txVm.transactions) {
          if (tx.type == app_models.TransactionType.expense) {
            spentByCategory.update(tx.category, (v) => v + tx.amount, ifAbsent: () => tx.amount);
          }
        }

        // Build data combining with budgets
        final Map<String, List<double>> budgetData = {};
        for (final budget in budgetVm.budgets) {
          final spent = spentByCategory[budget.category] ?? 0.0;
          budgetData[budget.category] = [spent, budget.amount];
        }

        if (budgetData.isEmpty) {
          return const ReportCard(
            title: 'Budget Performance',
            child: SizedBox(
              height: 120,
              child: Center(child: Text('No budgets set.')),
            ),
          );
        }

        return ReportCard(
          title: 'Budget Performance',
          child: SizedBox(
            height: 250,
            child: _buildBudgetPerformanceChart(budgetData),
          ),
        );
      },
    );
  }

  Widget _buildBudgetPerformanceChart(Map<String, List<double>> budgetData) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 600,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final categories = budgetData.keys.toList();
                if (value >= 0 && value < categories.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      categories[value.toInt()],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(budgetData.length, (index) {
          final category = budgetData.keys.elementAt(index);
          final spent = budgetData[category]![0];
          final budget = budgetData[category]![1];
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: spent,
                color: AppTheme.expenseColor,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              BarChartRodData(
                toY: budget,
                color: AppTheme.primaryColor.withAlpha((0.5 * 255).toInt()),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (AppTheme.categoryColors.containsKey(category)) {
      return AppTheme.categoryColors[category]!.withAlpha((0.7 * 255).toInt());
    }
    return AppTheme.categoryColors['Other']!.withAlpha((0.7 * 255).toInt());
  }
}
