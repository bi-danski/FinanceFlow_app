import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/spending_heatmap_model.dart';
import '../../themes/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../widgets/analytics/enhanced_filter_dialog.dart';

class SpendingHeatmapScreen extends StatefulWidget {
  const SpendingHeatmapScreen({super.key});

  @override
  State<SpendingHeatmapScreen> createState() => _SpendingHeatmapScreenState();
}

class _SpendingHeatmapScreenState extends State<SpendingHeatmapScreen> {
  int _selectedIndex = 10; // Heatmap index in the drawer
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Mock data - in a real app, this would come from a provider or repository
  late Map<DateTime, SpendingHeatmapData> _spendingData;
  late double _maxDailySpending;
  
  @override
  void initState() {
    super.initState();
    _generateMockData();
  }
  
  void _generateMockData() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 2, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);
    
    _spendingData = {};
    double maxSpending = 0;
    
    // Generate random spending data for each day
    for (DateTime date = startDate; date.isBefore(endDate); date = date.add(const Duration(days: 1))) {
      // Generate more realistic spending patterns
      double amount = 0;
      
      // Weekends tend to have higher spending
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        amount = 50 + (200 * _randomDouble());
      } 
      // Beginning and end of month might have higher spending (bills, rent)
      else if (date.day <= 5 || date.day >= 25) {
        amount = 100 + (300 * _randomDouble());
      }
      // Regular weekdays
      else {
        amount = 20 + (100 * _randomDouble());
      }
      
      // Some days might have no spending
      if (_randomDouble() < 0.2) {
        amount = 0;
      }
      
      // Round to 2 decimal places
      amount = double.parse(amount.toStringAsFixed(2));
      
      if (amount > maxSpending) {
        maxSpending = amount;
      }
      
      final transactions = _generateMockTransactions(date, amount);
      
      _spendingData[date] = SpendingHeatmapData(
        date: date,
        amount: amount,
        transactions: transactions,
      );
    }
    
    _maxDailySpending = maxSpending;
  }
  
  List<SpendingTransaction> _generateMockTransactions(DateTime date, double totalAmount) {
    if (totalAmount <= 0) return [];
    
    final transactions = <SpendingTransaction>[];
    double remainingAmount = totalAmount;
    
    // Categories with their associated icons
    final categories = [
      {'name': 'Food', 'icon': Icons.restaurant},
      {'name': 'Transport', 'icon': Icons.directions_car},
      {'name': 'Shopping', 'icon': Icons.shopping_bag},
      {'name': 'Entertainment', 'icon': Icons.movie},
      {'name': 'Utilities', 'icon': Icons.power},
      {'name': 'Health', 'icon': Icons.medical_services},
    ];
    
    // Generate 1-4 transactions for the day
    final transactionCount = 1 + (3 * _randomDouble()).round();
    
    for (int i = 0; i < transactionCount; i++) {
      // Last transaction gets the remaining amount
      double amount;
      if (i == transactionCount - 1) {
        amount = remainingAmount;
      } else {
        // Random portion of the remaining amount
        amount = remainingAmount * (0.3 + (0.5 * _randomDouble()));
        remainingAmount -= amount;
      }
      
      // Round to 2 decimal places
      amount = double.parse(amount.toStringAsFixed(2));
      
      // Random category
      final categoryIndex = (categories.length * _randomDouble()).floor();
      final category = categories[categoryIndex];
      
      // Transaction titles based on category
      final titles = _getTransactionTitles(category['name'] as String);
      final titleIndex = (titles.length * _randomDouble()).floor();
      
      transactions.add(
        SpendingTransaction(
          id: 'tx_${date.millisecondsSinceEpoch}_$i',
          title: titles[titleIndex],
          amount: amount,
          date: date,
          category: category['name'] as String,
          icon: category['icon'] as IconData,
        ),
      );
    }
    
    return transactions;
  }
  
  List<String> _getTransactionTitles(String category) {
    switch (category) {
      case 'Food':
        return ['Grocery Store', 'Restaurant', 'Coffee Shop', 'Fast Food', 'Bakery'];
      case 'Transport':
        return ['Gas Station', 'Uber', 'Public Transit', 'Parking', 'Car Service'];
      case 'Shopping':
        return ['Clothing Store', 'Electronics', 'Home Goods', 'Online Shopping', 'Department Store'];
      case 'Entertainment':
        return ['Movie Theater', 'Concert Tickets', 'Streaming Service', 'Game Store', 'Bar'];
      case 'Utilities':
        return ['Electricity Bill', 'Water Bill', 'Internet Service', 'Phone Bill', 'Gas Bill'];
      case 'Health':
        return ['Pharmacy', 'Doctor Visit', 'Gym Membership', 'Health Insurance', 'Dental Care'];
      default:
        return ['Miscellaneous'];
    }
  }
  
  double _randomDouble() {
    return DateTime.now().millisecondsSinceEpoch % 100 / 100;
  }
  
  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final String route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Heatmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info about the heatmap
              _showInfoDialog();
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const Divider(height: 1),
          _buildSelectedDayDetails(),
          const Divider(height: 1),
          _buildSpendingInsights(),
        ],
      ),
    );
  }
  
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2025, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        // Customize the calendar appearance
        markersMaxCount: 0, // We'll use our own marker system
        weekendTextStyle: const TextStyle(color: Colors.red),
        holidayTextStyle: const TextStyle(color: Colors.red),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          return _buildCalendarDay(date);
        },
        selectedBuilder: (context, date, _) {
          return _buildCalendarDay(date, isSelected: true);
        },
        todayBuilder: (context, date, _) {
          return _buildCalendarDay(date, isToday: true);
        },
        markerBuilder: (context, date, events) {
          return null; // We'll handle markers in our day builder
        },
      ),
    );
  }
  
  Widget _buildCalendarDay(DateTime date, {bool isSelected = false, bool isToday = false}) {
    final spendingData = _spendingData[DateTime(date.year, date.month, date.day)];
    final hasSpending = spendingData != null && spendingData.amount > 0;
    
    // Determine heat color based on spending intensity
    Color backgroundColor = Colors.transparent;
    Color textColor = isToday ? AppTheme.primaryColor : Colors.black;
    
    if (hasSpending) {
      final intensity = spendingData.getIntensityLevel(_maxDailySpending);
      backgroundColor = spendingData.getHeatColor(intensity).withAlpha(isSelected ? 255 : 180);
      
      // For high intensity levels, use white text for better contrast
      if (intensity >= 4) {
        textColor = Colors.white;
      }
    }
    
    // Selected day styling
    if (isSelected) {
      if (!hasSpending) {
        backgroundColor = AppTheme.primaryColor.withAlpha(50);
      }
      textColor = hasSpending ? textColor : AppTheme.primaryColor;
    }
    
    // Today styling
    if (isToday && !isSelected) {
      textColor = AppTheme.primaryColor;
    }
    
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday || isSelected
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected || isToday ? FontWeight.bold : null,
              ),
            ),
            if (hasSpending)
              Text(
                '\$${spendingData.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSelectedDayDetails() {
    final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final spendingData = _spendingData[selectedDate];
    
    if (spendingData == null || spendingData.amount <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                'No spending on ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Great job keeping your expenses down!',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Total: \$${spendingData.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: spendingData.transactions.length,
            itemBuilder: (context, index) {
              final transaction = spendingData.transactions[index];
              return _buildTransactionItem(transaction).animate()
                .fadeIn(duration: const Duration(milliseconds: 300), delay: Duration(milliseconds: 50 * index))
                .slideX(begin: 0.2, end: 0);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionItem(SpendingTransaction transaction) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.categoryColors[transaction.category] ?? Colors.grey.shade200,
        child: Icon(
          transaction.icon,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        transaction.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        transaction.category,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Text(
        '\$${transaction.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildSpendingInsights() {
    // Get data for the selected month
    final selectedMonth = DateTime(_selectedDay.year, _selectedDay.month, 1);
    final daysInMonth = DateTime(_selectedDay.year, _selectedDay.month + 1, 0).day;
    
    // Collect all spending data for the month
    final monthData = <SpendingHeatmapData>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedDay.year, _selectedDay.month, day);
      final data = _spendingData[date];
      if (data != null) {
        monthData.add(data);
      }
    }
    
    // Calculate monthly insights
    final totalSpending = monthData.fold(0.0, (sum, data) => sum + data.amount);
    final avgDailySpending = monthData.isEmpty ? 0.0 : totalSpending / monthData.length;
    final daysWithSpending = monthData.where((data) => data.amount > 0).length;
    final daysWithoutSpending = daysInMonth - daysWithSpending;
    
    // Find highest spending day
    SpendingHeatmapData? highestDay;
    if (monthData.isNotEmpty) {
      highestDay = monthData.reduce((a, b) => a.amount > b.amount ? a : b);
    }
    
    // Calculate weekday vs weekend spending
    double weekdayTotal = 0;
    double weekendTotal = 0;
    int weekdayCount = 0;
    int weekendCount = 0;
    
    for (final data in monthData) {
      if (data.isWeekend()) {
        weekendTotal += data.amount;
        weekendCount++;
      } else {
        weekdayTotal += data.amount;
        weekdayCount++;
      }
    }
    
    final weekdayAvg = weekdayCount > 0 ? (weekdayTotal / weekdayCount).toDouble() : 0.0;
    final weekendAvg = weekendCount > 0 ? (weekendTotal / weekendCount).toDouble() : 0.0;
    
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights for ${DateFormat('MMMM yyyy').format(selectedMonth)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInsightCard(
                  'Total Spending',
                  '\$${totalSpending.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildInsightCard(
                  'Avg. Daily',
                  '\$${avgDailySpending.toStringAsFixed(2)}',
                  Icons.calendar_today,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInsightCard(
                  'Days with Spending',
                  '$daysWithSpending days',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildInsightCard(
                  'No-Spend Days',
                  '$daysWithoutSpending days',
                  Icons.savings,
                  Colors.purple,
                ),
              ],
            ),
            if (highestDay != null) ...[
              const SizedBox(height: 16),
              _buildHighestSpendingDayCard(highestDay),
            ],
            const SizedBox(height: 16),
            _buildWeekdayVsWeekendCard(weekdayAvg, weekendAvg),
            const SizedBox(height: 16),
            _buildHeatmapLegend(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 300))
      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad);
  }
  
  Widget _buildHighestSpendingDayCard(SpendingHeatmapData highestDay) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.shade100,
            child: Text(
              highestDay.date.day.toString(),
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highest Spending Day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(highestDay.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${highestDay.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeekdayVsWeekendCard(double weekdayAvg, double weekendAvg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekday vs Weekend Spending',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Weekday Avg.',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${weekdayAvg.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.blue.shade200,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Weekend Avg.',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${weekendAvg.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            weekendAvg > weekdayAvg
                ? 'You spend ${(weekendAvg / weekdayAvg).toStringAsFixed(1)}x more on weekends!'
                : 'Your spending is fairly consistent throughout the week.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeatmapLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Heatmap Legend',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i <= 5; i++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: SpendingHeatmapData(
                      date: DateTime.now(),
                      amount: 0,
                      transactions: [],
                    ).getHeatColor(i),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      i == 0 ? 'None' : i == 5 ? 'High' : '',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: i >= 4 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'The color intensity indicates your spending level for each day.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  // Filter options for the spending heatmap
  FilterOptions _filterOptions = const FilterOptions();
  final List<String> _availableCategories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Utilities', 'Health'];

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedFilterDialog(
        initialFilters: _filterOptions,
        availableCategories: _availableCategories,
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _filterOptions = result;
          // Apply filters to the heatmap data
          _applyFilters();
        });
      }
    });
  }

  void _applyFilters() {
    // This would filter the actual data in a real implementation
    // For now, we'll just show a snackbar indicating filters were applied
    int activeFilterCount = 0;
    if (_filterOptions.dateRange != null) activeFilterCount++;
    if (_filterOptions.selectedCategories.isNotEmpty) activeFilterCount++;
    if (_filterOptions.minAmount != null || _filterOptions.maxAmount != null) activeFilterCount++;
    if (_filterOptions.showOnlyHighSpending) activeFilterCount++;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied $activeFilterCount filters'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Show details of applied filters (would be implemented in a real app)
          },
        ),
      ),
    );
  }
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Spending Heatmap'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The Spending Heatmap helps you visualize your daily spending patterns. '
              'Darker colors indicate higher spending days.',
            ),
            SizedBox(height: 12),
            Text(
              'Use this tool to identify spending trends and make better financial decisions.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
