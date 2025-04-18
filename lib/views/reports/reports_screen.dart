import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../viewmodels/transaction_viewmodel.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
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
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    await transactionViewModel.loadTransactions();
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation would be handled here
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadData();
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
    return ReportCard(
      title: 'Income vs Expenses',
      child: SizedBox(
        height: 250,
        child: _buildIncomeExpensesChart(),
      ),
    );
  }

  Widget _buildIncomeExpensesChart() {
    // Mock data for the chart
    final income = 4850.0;
    final expenses = 3210.0;
    final balance = income - expenses;
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
    return ReportCard(
      title: 'Spending by Category',
      child: SizedBox(
        height: 250,
        child: _buildCategoryChart(),
      ),
    );
  }

  Widget _buildCategoryChart() {
    // Mock data for the chart
    final Map<String, double> categoryData = {
      'Food': 450.0,
      'Transport': 180.0,
      'Shopping': 320.0,
      'Bills': 550.0,
      'Entertainment': 200.0,
      'Other': 100.0,
    };
    
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
    return ReportCard(
      title: 'Monthly Trend',
      child: SizedBox(
        height: 250,
        child: _buildMonthlyTrendChart(),
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    // Mock data for the chart
    final List<FlSpot> incomeSpots = [
      FlSpot(0, 4200),
      FlSpot(1, 4500),
      FlSpot(2, 4300),
      FlSpot(3, 4800),
      FlSpot(4, 4600),
      FlSpot(5, 4850),
    ];
    
    final List<FlSpot> expenseSpots = [
      FlSpot(0, 3100),
      FlSpot(1, 3400),
      FlSpot(2, 3200),
      FlSpot(3, 3500),
      FlSpot(4, 3300),
      FlSpot(5, 3210),
    ];
    
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
    return ReportCard(
      title: 'Budget Performance',
      child: SizedBox(
        height: 250,
        child: _buildBudgetPerformanceChart(),
      ),
    );
  }

  Widget _buildBudgetPerformanceChart() {
    // Mock data for the chart
    final Map<String, List<double>> budgetData = {
      'Food': [450.0, 500.0],
      'Transport': [180.0, 250.0],
      'Shopping': [320.0, 300.0],
      'Bills': [550.0, 600.0],
      'Entertainment': [200.0, 150.0],
      'Other': [100.0, 200.0],
    };
    
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
