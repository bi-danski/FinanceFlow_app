import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../models/dashboard_widget_config.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../constants/app_constants.dart';
import '../../widgets/add_transaction_fab.dart';
import 'widgets/financial_summary_card.dart';
import 'widgets/dashboard_widget_container.dart';
import 'widgets/dashboard_widget_factory.dart';
// All imports above are used; none removed as all are required for dashboard functionality.
// If any become unused, remove them to resolve lint errors.

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  DateTime _selectedMonth = DateTime.now();
  bool _isEditMode = false;
  final DashboardWidgetFactory _widgetFactory = DashboardWidgetFactory();
  late DashboardConfig _dashboardConfig;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeDashboard();
  }
  
  void _initializeDashboard() {
    // In a real app, this would be loaded from storage
    _dashboardConfig = DashboardConfig(
      widgets: [
        DashboardWidgetConfig(
          id: _uuid.v4(),
          name: 'Spending by Category',
          type: WidgetType.spendingPieChart,
          title: 'Spending by Category',
          settings: {
            'period': 'month',
            'showLegend': true,
            'showPercentages': true,
            'maxCategories': 5,
          },
          position: 0,
        ),
        DashboardWidgetConfig(
          id: _uuid.v4(),
          name: 'Monthly Spending Trend',
          type: WidgetType.monthlySpendingTrend,
          title: 'Monthly Spending Trend',
          settings: {
            'months': 6,
            'showAverage': true,
          },
                    position: 1,
        ),
        DashboardWidgetConfig(
          id: _uuid.v4(),
          name: 'Spending Heat Map',
          type: WidgetType.spendingHeatMap,
          title: 'Spending Heat Map',
          settings: {
            'period': 'month',
            'type': 'category',
          },
                    position: 2,
        ),
      ], name: '',
    );
  }

  Future<void> _loadData() async {
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
    final goalViewModel = Provider.of<GoalViewModel>(context, listen: false);

    await transactionViewModel.loadTransactions();
    await budgetViewModel.loadBudgets();
    await goalViewModel.loadGoals();
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation would be handled here
  }
  
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }
  
  void _addWidget(WidgetType type) {
    final newWidget = DashboardWidgetConfig(
      id: _uuid.v4(),
      type: type,
      name: _getDefaultWidgetTitle(type),
      title: _getDefaultWidgetTitle(type),
      settings: _getDefaultWidgetSettings(type),
      position: _dashboardConfig.widgets.length,
    );
    
    setState(() {
      _dashboardConfig.widgets.add(newWidget);
    });
    
    // In a real app, save the updated config to storage
  }
  
  void _removeWidget(String id) {
    setState(() {
      _dashboardConfig.widgets.removeWhere((widget) => widget.id == id);
    });
    
    // In a real app, save the updated config to storage
  }
  
  void _editWidget(DashboardWidgetConfig oldConfig, DashboardWidgetConfig newConfig) {
    setState(() {
      final index = _dashboardConfig.widgets.indexWhere((widget) => widget.id == oldConfig.id);
      if (index != -1) {
        _dashboardConfig.widgets[index] = newConfig;
      }
    });
    
    // In a real app, save the updated config to storage
  }
  
  String _getDefaultWidgetTitle(WidgetType type) {
    switch (type) {
      case WidgetType.spendingPieChart:
        return 'Spending by Category';
      case WidgetType.budgetProgressBar:
        return 'Budget Progress';
      case WidgetType.savingsGoalTracker:
        return 'Savings Goals';
      case WidgetType.recentTransactions:
        return 'Recent Transactions';
      case WidgetType.monthlySpendingTrend:
        return 'Monthly Spending Trend';
      case WidgetType.categoryComparison:
        return 'Category Comparison';
      case WidgetType.spendingHeatMap:
        return 'Spending Heat Map';
    }
  }
  
  Map<String, dynamic> _getDefaultWidgetSettings(WidgetType type) {
    switch (type) {
      case WidgetType.spendingPieChart:
        return {
          'period': 'month',
          'showLegend': true,
          'showPercentages': true,
          'maxCategories': 5,
        };
      case WidgetType.budgetProgressBar:
        return {
          'period': 'month',
          'showRemaining': true,
        };
      case WidgetType.savingsGoalTracker:
        return {
          'showAllGoals': true,
          'sortBy': 'progress',
        };
      case WidgetType.recentTransactions:
        return {
          'limit': 5,
          'showAmount': true,
        };
      case WidgetType.monthlySpendingTrend:
        return {
          'months': 6,
          'showAverage': true,
        };
      case WidgetType.categoryComparison:
        return {
          'periods': ['current_month', 'previous_month'],
        };
      case WidgetType.spendingHeatMap:
        return {
          'period': 'month',
          'type': 'category',
        };
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard')
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 500)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.edit_off : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: _isEditMode ? 'Exit Edit Mode' : 'Edit Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), 
                      duration: const Duration(seconds: 2)),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector()
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 400))
                    .slideX(begin: -0.1, end: 0),
                const SizedBox(height: 16),
                const FinancialSummaryCard()
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                
                // Custom dashboard section
                _buildDashboardHeader(),
                const SizedBox(height: 16),
                ..._buildDashboardWidgets(),
                if (_isEditMode) _buildAddWidgetButton(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AddTransactionFAB(
        onTransactionAdded: () {
          _loadData();
        },
      )
          .animate()
          .scale(begin: const Offset(0, 0), end: const Offset(1, 1), 
                curve: Curves.elasticOut, duration: const Duration(milliseconds: 800)),
    );
  }
  
  Widget _buildDashboardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Analytics Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
          .slideX(begin: -0.2, end: 0),
        if (_isEditMode)
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Widget'),
            onPressed: () => _showAddWidgetDialog(context),
          ).animate()
            .fadeIn(duration: const Duration(milliseconds: 500))
            .slideX(begin: 0.2, end: 0),
      ],
    );
  }
  
  List<Widget> _buildDashboardWidgets() {
    if (_dashboardConfig.widgets.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(
                  Icons.dashboard_customize,
                  size: 64,
                  color: Colors.grey.withAlpha(150),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your dashboard is empty',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.withAlpha(200),
                  ),
                ),
                if (_isEditMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Widget'),
                      onPressed: () => _showAddWidgetDialog(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ];
    }
    
    return _dashboardConfig.widgets.map((config) {
      return DashboardWidgetContainer(
        config: config,
        onEdit: _isEditMode ? () => _showEditWidgetDialog(context, config) : null,
        onRemove: _isEditMode ? () => _removeWidget(config.id) : null,
        child: _widgetFactory.createWidget(config),
      );
    }).toList();
  }
  
  Widget _buildAddWidgetButton() {
    return DashboardEmptySlot(
      onAddWidget: () => _showAddWidgetDialog(context),
    );
  }
  
  void _showAddWidgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Widget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWidgetTypeOption(
                  context,
                  'Spending Pie Chart',
                  Icons.pie_chart,
                  WidgetType.spendingPieChart,
                ),
                _buildWidgetTypeOption(
                  context,
                  'Budget Progress',
                  Icons.show_chart,
                  WidgetType.budgetProgressBar,
                ),
                _buildWidgetTypeOption(
                  context,
                  'Savings Goals',
                  Icons.savings,
                  WidgetType.savingsGoalTracker,
                ),
                _buildWidgetTypeOption(
                  context,
                  'Recent Transactions',
                  Icons.receipt_long,
                  WidgetType.recentTransactions,
                ),
                _buildWidgetTypeOption(
                  context,
                  'Monthly Spending Trend',
                  Icons.trending_up,
                  WidgetType.monthlySpendingTrend,
                ),
                _buildWidgetTypeOption(
                  context,
                  'Category Comparison',
                  Icons.compare_arrows,
                  WidgetType.categoryComparison,
                ),
                _buildWidgetTypeOption(
                  context,
                  'Spending Heat Map',
                  Icons.grid_on,
                  WidgetType.spendingHeatMap,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildWidgetTypeOption(
    BuildContext context,
    String title,
    IconData icon,
    WidgetType type,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: () {
        _addWidget(type);
        Navigator.of(context).pop();
      },
    );
  }
  
  void _showEditWidgetDialog(BuildContext context, DashboardWidgetConfig config) {
    showDialog(
      context: context,
      builder: (context) {
        return WidgetSettingsDialog(config: config);
      },
    ).then((updatedConfig) {
      if (updatedConfig != null) {
        _editWidget(config, updatedConfig as DashboardWidgetConfig);
      }
    });
  }

  Widget _buildMonthSelector() {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.primary.withAlpha(30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                DateFormat(AppConstants.monthYearFormat).format(_selectedMonth),
                key: ValueKey<DateTime>(_selectedMonth),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
