import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../models/budget_model.dart';

class BudgetTimelineChart extends StatefulWidget {
  final List<Budget> budgets;
  final List<Map<String, dynamic>> spendingHistory; // [{date: DateTime, category: String, amount: double}]
  final String selectedPeriod; // 'weekly', 'monthly', 'yearly'
  final Function(String) onPeriodChanged;
  final String selectedCategory; // 'all' or specific category
  final Function(String) onCategoryChanged;

  const BudgetTimelineChart({
    super.key,
    required this.budgets,
    required this.spendingHistory,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<BudgetTimelineChart> createState() => _BudgetTimelineChartState();
}

class _BudgetTimelineChartState extends State<BudgetTimelineChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  List<String> _availableCategories = [];
  int _touchedIndex = -1;
  
  // For the time filter buttons
  final List<String> _timeFilters = ['weekly', 'monthly', 'yearly'];
  
  // For the gradient colors
  final List<Color> _budgetGradientColors = [
    Colors.cyan,
    Colors.blue,
  ];
  
  final List<Color> _actualGradientColors = [
    Colors.orangeAccent,
    Colors.redAccent,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scrollController = ScrollController();
    _loadCategories();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    final categories = <String>{};
    categories.add('all');
    
    for (final budget in widget.budgets) {
      categories.add(budget.category);
    }
    
    setState(() {
      _availableCategories = categories.toList();
    });
  }

  @override
  void didUpdateWidget(BudgetTimelineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgets != widget.budgets) {
      _loadCategories();
    }
    
    // Animate when data changes
    if (oldWidget.selectedPeriod != widget.selectedPeriod ||
        oldWidget.spendingHistory != widget.spendingHistory) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  List<FlSpot> _getBudgetSpots() {
    if (widget.budgets.isEmpty) return [];
    
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    // Generate time points based on selected period
    final timePoints = _generateTimePoints(now);
    
    for (int i = 0; i < timePoints.length; i++) {
      final date = timePoints[i];
      double budgetAmount = 0;
      
      if (widget.selectedCategory == 'all') {
        // Sum all budgets for the date
        for (final budget in widget.budgets) {
          if (date.isAfter(budget.startDate) && date.isBefore(budget.endDate)) {
            // Calculate prorated budget amount based on period
            budgetAmount += _getProratedBudget(budget, date, widget.selectedPeriod);
          }
        }
      } else {
        // Get specific category budget
        final categoryBudget = widget.budgets.firstWhere(
          (budget) => budget.category == widget.selectedCategory,
          orElse: () => Budget(
            category: widget.selectedCategory,
            amount: 0,
            startDate: now.subtract(const Duration(days: 30)),
            endDate: now,
          ),
        );
        
        if (date.isAfter(categoryBudget.startDate) && date.isBefore(categoryBudget.endDate)) {
          budgetAmount = _getProratedBudget(categoryBudget, date, widget.selectedPeriod);
        }
      }
      
      spots.add(FlSpot(i.toDouble(), budgetAmount));
    }
    
    return spots;
  }

  List<FlSpot> _getActualSpots() {
    if (widget.spendingHistory.isEmpty) return [];
    
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    // Generate time points based on selected period
    final timePoints = _generateTimePoints(now);
    
    for (int i = 0; i < timePoints.length; i++) {
      final date = timePoints[i];
      final nextDate = i < timePoints.length - 1 ? timePoints[i + 1] : date.add(const Duration(days: 1));
      
      double actualAmount = 0;
      
      // Sum spending for the period
      for (final spending in widget.spendingHistory) {
        final spendingDate = spending['date'] as DateTime;
        
        if (spendingDate.isAfter(date) && spendingDate.isBefore(nextDate)) {
          if (widget.selectedCategory == 'all' || spending['category'] == widget.selectedCategory) {
            actualAmount += spending['amount'] as double;
          }
        }
      }
      
      spots.add(FlSpot(i.toDouble(), actualAmount));
    }
    
    return spots;
  }

  List<DateTime> _generateTimePoints(DateTime endDate) {
    final timePoints = <DateTime>[];
    DateTime startDate;
    
    switch (widget.selectedPeriod) {
      case 'weekly':
        startDate = endDate.subtract(const Duration(days: 7));
        for (int i = 0; i <= 7; i++) {
          timePoints.add(startDate.add(Duration(days: i)));
        }
        break;
      case 'monthly':
        startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
        for (int i = 0; i <= 30; i += 3) { // Every 3 days for a month
          timePoints.add(startDate.add(Duration(days: i)));
        }
        break;
      case 'yearly':
        startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
        for (int i = 0; i < 12; i++) {
          timePoints.add(DateTime(startDate.year, startDate.month + i, 1));
        }
        break;
      default:
        startDate = endDate.subtract(const Duration(days: 7));
        for (int i = 0; i <= 7; i++) {
          timePoints.add(startDate.add(Duration(days: i)));
        }
    }
    
    return timePoints;
  }

  double _getProratedBudget(Budget budget, DateTime date, String period) {
    final totalDays = budget.endDate.difference(budget.startDate).inDays;
    if (totalDays <= 0) return 0;
    
    final dailyBudget = budget.amount / totalDays;
    
    switch (period) {
      case 'weekly':
        return dailyBudget * 7;
      case 'monthly':
        return dailyBudget * 30;
      case 'yearly':
        return budget.amount; // Assuming the budget is annual
      default:
        return dailyBudget * 7;
    }
  }

  String _getBottomTitle(double value, List<DateTime> timePoints) {
    final index = value.toInt();
    if (index < 0 || index >= timePoints.length) return '';
    
    final date = timePoints[index];
    
    switch (widget.selectedPeriod) {
      case 'weekly':
        return DateFormat('E').format(date); // Day of week
      case 'monthly':
        return DateFormat('d').format(date); // Day of month
      case 'yearly':
        return DateFormat('MMM').format(date); // Month
      default:
        return DateFormat('E').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timePoints = _generateTimePoints(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Timeline',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
        ),
        // Category selector
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableCategories.length,
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (context, index) {
              final category = _availableCategories[index];
              final isSelected = category == widget.selectedCategory;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category.toUpperCase()),
                  selected: isSelected,
                  onSelected: (_) => widget.onCategoryChanged(category),
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.black54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        // Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade800.withValues(alpha: 0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        final formatter = NumberFormat.currency(symbol: r'$');
                        
                        return LineTooltipItem(
                          formatter.format(flSpot.y),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    setState(() {
                      if (event is FlPanEndEvent || event is FlTapUpEvent || touchResponse == null || touchResponse.lineBarSpots == null) {
                        _touchedIndex = -1;
                      } else {
                        _touchedIndex = touchResponse.lineBarSpots![0].x.toInt();
                      }
                    });
                  },
                  handleBuiltInTouches: true,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8.0,
                          child: Text(
                            _getBottomTitle(value, timePoints),
                            style: TextStyle(
                              color: _touchedIndex == value.toInt() ? 
                                Theme.of(context).primaryColor : 
                                Colors.grey.shade600,
                              fontWeight: _touchedIndex == value.toInt() ? 
                                FontWeight.bold : 
                                FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final formatter = NumberFormat.compactCurrency(symbol: r'$');
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8.0,
                          child: Text(
                            formatter.format(value),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: timePoints.length.toDouble() - 1,
                minY: 0,
                lineBarsData: [
                  // Budget line
                  LineChartBarData(
                    spots: _getBudgetSpots(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: _budgetGradientColors,
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: _touchedIndex != -1,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: _touchedIndex == index ? 5 : 3,
                          color: _budgetGradientColors[1],
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: _budgetGradientColors
                            .map((color) => color.withValues(alpha: 0.3))
                            .toList(),
                      ),
                    ),
                  ),
                   
                  // Actual spending line
                  LineChartBarData(
                    spots: _getActualSpots(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: _actualGradientColors,
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: _touchedIndex != -1,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: _touchedIndex == index ? 5 : 3,
                          color: _actualGradientColors[1],
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: _actualGradientColors
                            .map((color) => color.withValues(alpha: 0.3))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Budget', _budgetGradientColors[1]),
              const SizedBox(width: 20),
              _buildLegendItem('Actual', _actualGradientColors[1]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: _timeFilters.map((filter) {
        String label;
        switch (filter) {
          case 'weekly':
            label = 'Week';
            break;
          case 'monthly':
            label = 'Month';
            break;
          case 'yearly':
            label = 'Year';
            break;
          default:
            label = filter;
        }
        
        return ButtonSegment<String>(
          value: filter,
          label: Text(label),
        );
      }).toList(),
      selected: {widget.selectedPeriod},
      onSelectionChanged: (selected) {
        widget.onPeriodChanged(selected.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).primaryColor;
            }
            return null;
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.black54;
          },
        ),
      ),
    );
  }
}
