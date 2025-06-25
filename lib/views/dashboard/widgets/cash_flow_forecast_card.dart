import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CashFlowPoint {
  final DateTime date;
  final double balance;
  final double income;
  final double expenses;

  CashFlowPoint({
    required this.date,
    required this.balance,
    required this.income,
    required this.expenses,
  });
}

class CashFlowForecastCard extends StatefulWidget {
  final List<CashFlowPoint> historicalData;
  final List<CashFlowPoint> forecastData;
  final bool isLoading;
  final Function() onViewDetails;

  const CashFlowForecastCard({
    super.key,
    required this.historicalData,
    required this.forecastData,
    this.isLoading = false,
    required this.onViewDetails,
  });

  @override
  State<CashFlowForecastCard> createState() => _CashFlowForecastCardState();
}

class _CashFlowForecastCardState extends State<CashFlowForecastCard> {
  bool _showIncome = true;
  bool _showExpenses = true;
  bool _showBalance = true;
  
  @override
  Widget build(BuildContext context) {
    // Combine historical and forecast data
    final allData = [...widget.historicalData, ...widget.forecastData];
    
    // Find min and max values for the chart
    double minY = 0;
    double maxY = 0;
    
    for (final point in allData) {
      if (_showBalance) {
        minY = min(minY, point.balance);
        maxY = max(maxY, point.balance);
      }
      if (_showIncome) {
        maxY = max(maxY, point.income);
      }
      if (_showExpenses) {
        minY = min(minY, -point.expenses);
      }
    }
    
    // Add some padding to the min/max values
    final padding = (maxY - minY) * 0.1;
    minY -= padding;
    maxY += padding;
    
    // Format for date display
    final dateFormat = DateFormat.MMMd();
    
    // Calculate potential cash flow issues
    final List<CashFlowPoint> cashFlowIssues = [];
    for (final point in widget.forecastData) {
      if (point.balance < 0) {
        cashFlowIssues.add(point);
      }
    }
    
    // Check for potential low balance days
    final List<CashFlowPoint> lowBalanceDays = [];
    for (final point in widget.forecastData) {
      if (point.balance > 0 && point.balance < 100) {
        lowBalanceDays.add(point);
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cash Flow Forecast',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.insights),
                  label: const Text('Details'),
                  onPressed: widget.onViewDetails,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Chart legend
            Wrap(
              spacing: 16,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showBalance = !_showBalance;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _showBalance ? Colors.blue : Colors.blue.withValues(alpha: 77),  // 0.3 * 255 = 77
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Balance',
                        style: TextStyle(
                          color: _showBalance ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showIncome = !_showIncome;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _showIncome ? Colors.green : Colors.green.withValues(alpha: 77),  // 0.3 * 255 = 77
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Income',
                        style: TextStyle(
                          color: _showIncome ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showExpenses = !_showExpenses;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _showExpenses ? Colors.red : Colors.red.withValues(alpha: 77),  // 0.3 * 255 = 77
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expenses',
                        style: TextStyle(
                          color: _showExpenses ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (widget.isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: allData.length.toDouble() - 1,
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: (maxY - minY) / 5,
                      verticalInterval: 7,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            // Show dates for every 7 days
                            if (value.toInt() % 7 == 0 && value.toInt() < allData.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8,
                                child: Text(
                                  dateFormat.format(allData[value.toInt()].date),
                                  style: const TextStyle(fontSize: 10),
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
                          interval: (maxY - minY) / 5,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                '\$${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: const Color(0xff37434d), width: 1),
                    ),
                    lineBarsData: [
                      // Balance line
                      if (_showBalance)
                        LineChartBarData(
                          spots: List.generate(
                            allData.length, 
                            (index) => FlSpot(index.toDouble(), allData[index].balance),
                          ),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 26),  // 0.1 * 255 = 26
                          ),
                        ),
                      
                      // Income line
                      if (_showIncome)
                        LineChartBarData(
                          spots: List.generate(
                            allData.length, 
                            (index) => FlSpot(index.toDouble(), allData[index].income),
                          ),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          dashArray: [5, 5],
                        ),
                      
                      // Expenses line
                      if (_showExpenses)
                        LineChartBarData(
                          spots: List.generate(
                            allData.length, 
                            (index) => FlSpot(index.toDouble(), -allData[index].expenses),
                          ),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          dashArray: [5, 5],
                        ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.withValues(alpha: 204),  // 0.8 * 255 = 204
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.x.toInt();
                            final data = allData[index];
                            final date = dateFormat.format(data.date);
                            
                            String text;
                            Color color;
                            
                            if (spot.barIndex == 0 && _showBalance) {
                              text = 'Balance: \$${data.balance.toStringAsFixed(2)}';
                              color = Colors.blue;
                            } else if (spot.barIndex == 1 || (!_showBalance && spot.barIndex == 0) && _showIncome) {
                              text = 'Income: \$${data.income.toStringAsFixed(2)}';
                              color = Colors.green;
                            } else {
                              text = 'Expenses: \$${data.expenses.toStringAsFixed(2)}';
                              color = Colors.red;
                            }
                            
                            return LineTooltipItem(
                              '$date\n$text',
                              TextStyle(color: color, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 800)),
                
            const SizedBox(height: 16),
            
            // Cash flow issues warning
            if (cashFlowIssues.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 26),  // 0.1 * 255 = 26
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 128)),  // 0.5 * 255 = 128
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Potential Cash Flow Issues',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your account may go negative on ${dateFormat.format(cashFlowIssues.first.date)}. '
                      'Consider adjusting your spending or adding funds before this date.',
                      style: TextStyle(
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(delay: const Duration(milliseconds: 500))
                .slideY(begin: 0.2, end: 0)
            else if (lowBalanceDays.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 26),  // 0.1 * 255 = 26
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 128)),  // 0.5 * 255 = 128
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Low Balance Warning',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your balance may drop below \$100 on ${dateFormat.format(lowBalanceDays.first.date)}. '
                      'Consider adjusting your budget to avoid potential issues.',
                      style: TextStyle(
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(delay: const Duration(milliseconds: 500))
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.1, end: 0);
  }
  
  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
}
