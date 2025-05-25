import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

import '../../services/connectivity_service.dart';
import '../../widgets/sync_status_indicator.dart';
import '../../widgets/add_transaction_fab.dart';

import '../../viewmodels/transaction_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../constants/app_constants.dart';
import '../../widgets/add_transaction_fab.dart';
import '../../models/dashboard_widget_config.dart';
import '../../utils/enhanced_animations.dart';
import '../../widgets/animated_financial_card.dart';
import '../../widgets/animated_financial_chart.dart';
import '../../widgets/animated_transaction_item.dart';
import '../../widgets/animated_buttons.dart';
import '../../widgets/dashboard/quick_actions_panel.dart';
import '../../widgets/dashboard/upcoming_payments_widget.dart';
import '../../widgets/dashboard/smart_insights_card.dart';
import '../../widgets/dashboard/budget_status_summary.dart';
import '../../widgets/dashboard/financial_health_score.dart';
import '../../widgets/dashboard/consolidated_financial_overview.dart';
import '../../widgets/dashboard/interactive_cash_flow_timeline.dart';
import '../../widgets/dashboard/money_distribution_visualization.dart';
import '../../widgets/dashboard/recurring_transactions_summary.dart';
import '../../widgets/dashboard/financial_goal_tracker.dart';
import '../../widgets/dashboard/unified_financial_management_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  DateTime _selectedMonth = DateTime.now();
  bool _isEditMode = false;
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
        DashboardWidgetConfig(
          id: _uuid.v4(),
          name: 'Budget Progress Bar',
          type: WidgetType.budgetProgressBar,
          title: 'Budget Progress',
          settings: {
            'budget': 2000.0,
            'spent': 1200.0,
          },
          position: 3,
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
  
  void _removeWidget(String id) {
    setState(() {
      _dashboardConfig.widgets.removeWhere((widget) => widget.id == id);
      
      // Update positions for remaining widgets
      for (int i = 0; i < _dashboardConfig.widgets.length; i++) {
        _dashboardConfig.widgets[i] = _dashboardConfig.widgets[i].copyWith(
          position: i,
        );
      }
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
  
  // Month navigation methods
  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final transactionViewModel = Provider.of<TransactionViewModel>(context);
    final budgetViewModel = Provider.of<BudgetViewModel>(context);
    final goalViewModel = Provider.of<GoalViewModel>(context);
    final connectivityService = ConnectivityService.instance;
    final bool isOnline = connectivityService.isOnline;
    final bool isSyncing = transactionViewModel.isLoading || budgetViewModel.isLoading || goalViewModel.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard')
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 500)),
        elevation: 0,
        actions: [
          // Sync status indicator
          SyncStatusIndicator(
            isSyncing: isSyncing,
            tooltip: isSyncing ? 'Syncing data...' : 'Data synced',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSyncing ? 'Syncing data with cloud...' : 'All data synced'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
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
            onPressed: () {},
            tooltip: 'Notifications',
          ),  
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Column(
        children: [
          // Offline banner at the top of the screen
          if (!isOnline)
            OfflineBanner(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trying to reconnect...')),
                );
              },
            ),
          Expanded(
            child: RefreshIndicator(
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
                      // Animated month selector with modern hover effect
                      EnhancedAnimations.modernHoverEffect(
                        child: _buildMonthSelector(),
                        scale: 1.02,
                        elevation: 3.5,
                        duration: const Duration(milliseconds: 150),
                      ).animate()
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 16),
                      
                      // Premium financial summary with animated data
                      _buildEnhancedFinancialSummary(),
                      const SizedBox(height: 24),
                      
                      // Recent transactions with animations
                      _buildRecentTransactions(),
                      const SizedBox(height: 24),
                      
                      // Enhanced Budget Navigation Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/enhanced_budget');
                          },
                          icon: const Icon(Icons.pie_chart),
                          label: const Text('Enhanced Budget Management'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            elevation: 4,
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ).animate()
                          .fadeIn(duration: const Duration(milliseconds: 600))
                          .slideY(begin: 0.2, end: 0),
                      ),
                      const SizedBox(height: 24),
                      
                      // Custom dashboard section with enhanced animations
                      EnhancedAnimations.cardEntrance(
                        _buildDashboardHeader(),
                        index: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Dashboard widgets with staggered animations
                      ...EnhancedAnimations.staggeredListEffects(_buildEnhancedDashboardWidgets()),
                      
                      // Add widget button with animation
                      if (_isEditMode) _buildAnimatedAddWidgetButton(),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Main add transaction button
          AddTransactionFAB(
            onTransactionAdded: () {
              // Refresh data when transaction is added
              _loadData();
            },
          ),
          // Enhanced Budget Button
          Positioned(
            bottom: 80,
            right: 0,
            child: FloatingActionButton.extended(
              heroTag: 'enhancedBudget',
              onPressed: () {
                Navigator.pushNamed(context, '/enhanced_budget');
              },
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              elevation: 4,
              label: const Text('Enhanced Budget'),
              icon: const Icon(Icons.pie_chart),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 800))
              .slideX(begin: 0.5, end: 0.0),
          ),
          // Original Add Transaction FAB
          AddTransactionFAB(
            onTransactionAdded: () {
              _loadData();
            },
          )
              .animate()
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1), 
                    curve: Curves.elasticOut, duration: const Duration(milliseconds: 800)),
        ],
      ),
    );
  }
  
  Widget _buildDashboardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Your Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_isEditMode)
          AnimatedPrimaryButton(
            text: 'Rearrange',
            icon: Icons.sort,
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              // Would implement rearranging in a real app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rearrange feature would be implemented here'),
                ),
              );
            },
          ),
      ],
    );
  }
  
  // Enhanced financial summary with animated components
  Widget _buildEnhancedFinancialSummary() {
    // Sample data for financial summary - using dummy data
    final totalIncome = 2500.0;  // Use actual method when implemented
    final totalExpenses = 1800.0; // Use actual method when implemented
    final balance = totalIncome - totalExpenses;
    final budgetProgress = 0.65;  // Use actual method when implemented
    
    // Create data points for the summary card
    final dataPoints = [
      FinancialDataPoint(
        label: 'Income',
        value: NumberFormat.currency(symbol: '\$').format(totalIncome),
        color: Colors.green.shade600,
      ),
      FinancialDataPoint(
        label: 'Expenses',
        value: NumberFormat.currency(symbol: '\$').format(totalExpenses),
        color: Colors.red.shade600,
      ),
      FinancialDataPoint(
        label: 'Savings',
        value: NumberFormat.currency(symbol: '\$').format(balance),
        color: Colors.blue.shade600,
      ),
    ];
    
    // Monthly spending data for line chart
    final spendingData = [1200.0, 1450.0, 980.0, 1380.0, 1800.0, 1560.0];
    
    return Column(
      children: [
        // Premium financial summary card
        PremiumFinancialSummaryCard(
          title: 'Monthly Summary',
          totalAmount: NumberFormat.currency(symbol: '\$').format(balance),
          periodText: DateFormat('MMMM yyyy').format(_selectedMonth),
          dataPoints: dataPoints,
          onViewDetails: () {
            // Navigate to detailed financial report
          },
        ),
        
        const SizedBox(height: 20),
        
        // Animated line chart for monthly spending
        AnimatedLineChart(
          dataPoints: spendingData,
          lineColor: Theme.of(context).colorScheme.primary,
          label: 'Monthly Spending Trend',
          height: 180,
        ),
        
        const SizedBox(height: 20),
        
        // Budget progress with circular chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AnimatedCircularChart(
              value: budgetProgress,
              label: 'Budget Progress',
              size: 120,
              color: budgetProgress > 0.8 
                ? Colors.red.shade600 
                : Theme.of(context).colorScheme.primary,
            ),
            AnimatedCircularChart(
              value: balance / totalIncome,
              label: 'Savings Rate',
              size: 120,
              color: Colors.green.shade600,
            ),
          ],
        ),
      ],
    );
  }
  
  // Recent transactions with animated list items
  Widget _buildRecentTransactions() {
    // Using sample transaction data directly since TransactionViewModel might not have recentTransactions property
    final sampleTransactions = [
      {'title': 'Grocery Shopping', 'amount': -128.45, 'date': DateTime.now().subtract(const Duration(days: 2)), 'category': 'Food'},
      {'title': 'Salary Deposit', 'amount': 2450.00, 'date': DateTime.now().subtract(const Duration(days: 5)), 'category': 'Income'},
      {'title': 'Electric Bill', 'amount': -85.20, 'date': DateTime.now().subtract(const Duration(days: 3)), 'category': 'Utilities'},
      {'title': 'Online Shopping', 'amount': -65.99, 'date': DateTime.now().subtract(const Duration(days: 1)), 'category': 'Shopping'},
    ];
    
    // Convert to animated transaction items
    final transactionItems = List.generate(
      sampleTransactions.length,
      (index) => AnimatedTransactionItem(
        title: sampleTransactions[index]['title'].toString(),
        date: DateFormat('MMM dd, yyyy').format(
          sampleTransactions[index]['date'] as DateTime? ?? DateTime.now()),
        amount: NumberFormat.currency(symbol: '\$').format(
          sampleTransactions[index]['amount'] as double? ?? 0.0),
        icon: _getCategoryIcon(sampleTransactions[index]['category'].toString()),
        color: (sampleTransactions[index]['amount'] as double? ?? 0.0) < 0 
          ? Colors.red.shade600 
          : Colors.green.shade600,
        isExpense: (sampleTransactions[index]['amount'] as double? ?? 0.0) < 0,
        onTap: () {
          // Navigate to transaction details
        },
        index: index,
      ),
    );
    
    return AnimatedTransactionList(
      transactions: transactionItems,
      title: 'Recent Transactions',
      subtitle: 'Last 30 days',
    );
  }
  
  // Get icon for transaction category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return FontAwesomeIcons.utensils;
      case 'income':
        return FontAwesomeIcons.moneyBillWave;
      case 'utilities':
        return FontAwesomeIcons.bolt;
      case 'shopping':
        return FontAwesomeIcons.bagShopping;
      case 'transportation':
        return FontAwesomeIcons.car;
      case 'entertainment':
        return FontAwesomeIcons.film;
      case 'health':
        return FontAwesomeIcons.heartPulse;
      default:
        return FontAwesomeIcons.receipt;
    }
  }
  
  // Enhanced dashboard widgets with new UI components
  List<Widget> _buildEnhancedDashboardWidgets() {
    // Collection of custom UI components to display
    final customWidgets = <Widget>[
      // Consolidated Financial Overview - NEW COMPONENT
      ConsolidatedFinancialOverview(
        balance: 12450.75,
        income: 5800.00,
        expenses: 3250.25,
        onViewDetails: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View financial details')),
          );
        },
        onPeriodChanged: (period) {
          HapticFeedback.lightImpact();
          // Period change logic would go here
        },
      ),

      const SizedBox(height: 16),

      // Quick Actions Panel with common financial tasks
      QuickActionsPanel(
        onPayBills: () {
          HapticFeedback.mediumImpact();
          // Navigate to bill payment screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pay Bills action tapped')),
          );
        },
        onTransferFunds: () {
          HapticFeedback.mediumImpact();
          // Navigate to funds transfer screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transfer action tapped')),
          );
        },
        onSetBudgetAlert: () {
          HapticFeedback.mediumImpact();
          // Open budget alerts configuration
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget Alert action tapped')),
          );
        },
        onSchedulePayment: () {
          HapticFeedback.mediumImpact();
          // Open payment scheduler
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule action tapped')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Upcoming Payments Widget
      UpcomingPaymentsWidget(
        payments: [
          UpcomingPayment(
            id: '1',
            name: 'Rent',
            amount: 1200.00,
            dueDate: DateTime.now().add(const Duration(days: 2)),
            category: 'Housing',
          ),
          UpcomingPayment(
            id: '2',
            name: 'Internet',
            amount: 79.99,
            dueDate: DateTime.now().add(const Duration(days: 5)),
            category: 'Utilities',
          ),
          UpcomingPayment(
            id: '3',
            name: 'Credit Card',
            amount: 450.00,
            dueDate: DateTime.now().subtract(const Duration(days: 1)),
            isPaid: false,
            category: 'Debt',
          ),
        ],
        onViewAll: () {
          // Navigate to all upcoming payments
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View all upcoming payments')),
          );
        },
        onPayNow: (payment) {
          // Handle payment action
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment action for ${payment.name}')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Interactive Cash Flow Timeline - NEW COMPONENT
      InteractiveCashFlowTimeline(
        events: [
          CashFlowEvent(
            id: '1',
            title: 'Salary',
            amount: 2800.00,
            date: DateTime.now().add(const Duration(days: 3)),
            isIncome: true,
            category: 'Income',
          ),
          CashFlowEvent(
            id: '2',
            title: 'Rent',
            amount: 1200.00,
            date: DateTime.now().add(const Duration(days: 5)),
            isIncome: false,
            category: 'Housing',
          ),
          CashFlowEvent(
            id: '3',
            title: 'Freelance',
            amount: 750.00,
            date: DateTime.now().add(const Duration(days: 7)),
            isIncome: true,
            category: 'Income',
          ),
          CashFlowEvent(
            id: '4',
            title: 'Internet',
            amount: 80.00,
            date: DateTime.now().add(const Duration(days: 9)),
            isIncome: false,
            category: 'Utilities',
          ),
        ],
        startDate: DateTime.now(),
        onEventTap: (event) {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cash flow event: ${event.title}')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Money Distribution Visualization - NEW COMPONENT
      MoneyDistributionVisualization(
        title: 'Spending Distribution',
        subtitle: 'How your money is allocated',
        categories: [
          SpendingCategory(
            id: '1',
            name: 'Housing',
            amount: 1450.00,
            color: Colors.blue.shade700,
            icon: Icons.home,
          ),
          SpendingCategory(
            id: '2',
            name: 'Food',
            amount: 650.00,
            color: Colors.green.shade700,
            icon: Icons.restaurant,
          ),
          SpendingCategory(
            id: '3',
            name: 'Transportation',
            amount: 320.00,
            color: Colors.orange.shade700,
            icon: Icons.directions_car,
          ),
          SpendingCategory(
            id: '4',
            name: 'Entertainment',
            amount: 280.00,
            color: Colors.purple.shade700,
            icon: Icons.movie,
          ),
          SpendingCategory(
            id: '5',
            name: 'Others',
            amount: 450.00,
            color: Colors.grey.shade700,
            icon: Icons.more_horiz,
          ),
        ],
        onCategoryTap: (category) {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category tapped: ${category.name}')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Recurring Transactions Summary - NEW COMPONENT
      RecurringTransactionsSummary(
        transactions: [
          RecurringTransaction(
            id: '1',
            name: 'Netflix',
            amount: 15.99,
            category: 'Entertainment',
            frequency: 'monthly',
            color: Colors.red.shade700,
            icon: Icons.movie,
            nextDueDate: DateTime.now().add(const Duration(days: 8)),
          ),
          RecurringTransaction(
            id: '2',
            name: 'Gym Membership',
            amount: 49.99,
            category: 'Health',
            frequency: 'monthly',
            color: Colors.green.shade700,
            icon: Icons.fitness_center,
            nextDueDate: DateTime.now().add(const Duration(days: 12)),
          ),
          RecurringTransaction(
            id: '3',
            name: 'Cloud Storage',
            amount: 9.99,
            category: 'Tech',
            frequency: 'monthly',
            color: Colors.blue.shade700,
            icon: Icons.cloud,
            nextDueDate: DateTime.now().add(const Duration(days: 15)),
          ),
          RecurringTransaction(
            id: '4',
            name: 'Phone Plan',
            amount: 65.00,
            category: 'Utilities',
            frequency: 'monthly',
            color: Colors.orange.shade700,
            icon: Icons.phone_android,
            nextDueDate: DateTime.now().add(const Duration(days: 3)),
            isEssential: true,
          ),
        ],
        monthlyIncome: 5800.00,
        onTransactionTap: (transaction) {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subscription: ${transaction.name}')),
          );
        },
        onViewAll: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View all recurring transactions')),
          );
        },
        onOptimize: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Optimize recurring expenses')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Financial Goal Tracker - NEW COMPONENT
      FinancialGoalTracker(
        goals: [
          FinancialGoal(
            id: '1',
            name: 'Emergency Fund',
            description: '6 months of expenses',
            targetAmount: 10000.00,
            currentAmount: 7500.00,
            monthlyContribution: 500.00,
            createdDate: DateTime.now().subtract(const Duration(days: 120)),
            color: Colors.blue.shade700,
            icon: Icons.shield,
            priority: 1,
          ),
          FinancialGoal(
            id: '2',
            name: 'Vacation',
            description: 'Trip to Bali',
            targetAmount: 3000.00,
            currentAmount: 1200.00,
            monthlyContribution: 300.00,
            createdDate: DateTime.now().subtract(const Duration(days: 60)),
            targetDate: DateTime.now().add(const Duration(days: 180)),
            color: Colors.orange.shade700,
            icon: Icons.beach_access,
            priority: 2,
          ),
          FinancialGoal(
            id: '3',
            name: 'New Laptop',
            targetAmount: 1500.00,
            currentAmount: 1500.00,
            monthlyContribution: 0.00,
            createdDate: DateTime.now().subtract(const Duration(days: 90)),
            color: Colors.green.shade700,
            icon: Icons.laptop_mac,
            priority: 3,
          ),
        ],
        onGoalTap: (goal) {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Goal tapped: ${goal.name}')),
          );
        },
        onAddGoal: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add new financial goal')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Unified Financial Management Panel - NEW COMPONENT
      // Removes redundancy in Income, Budget, and Loan sections
      UnifiedFinancialManagementPanel(
        sections: [
          // Income Section
          FinancialManagementSection(
            id: '1',
            name: 'Income',
            subtitle: 'Monthly income sources',
            totalAmount: 5800.00,
            icon: Icons.account_balance_wallet,
            color: Colors.green.shade700,
            emptyStateMessage: 'Add your income sources to track your monthly earnings',
            items: [
              FinancialManagementItem(
                id: '1',
                name: 'Primary Job',
                description: 'Software Developer',
                amount: 4200.00,
                period: 'Monthly',
                icon: Icons.work,
              ),
              FinancialManagementItem(
                id: '2',
                name: 'Freelance',
                description: 'UI/UX Design',
                amount: 1200.00,
                period: 'Monthly',
                icon: Icons.design_services,
              ),
              FinancialManagementItem(
                id: '3',
                name: 'Investments',
                description: 'Dividend Income',
                amount: 400.00,
                period: 'Monthly',
                icon: Icons.trending_up,
              ),
            ],
          ),
          
          // Budget Section
          FinancialManagementSection(
            id: '2',
            name: 'Budget',
            subtitle: 'Monthly spending allocations',
            totalAmount: 4500.00,
            icon: Icons.pie_chart,
            color: Colors.blue.shade700,
            emptyStateMessage: 'Create budget categories to manage your spending',
            items: [
              FinancialManagementItem(
                id: '1',
                name: 'Housing',
                description: 'Rent and utilities',
                amount: 1800.00,
                period: 'Monthly',
                icon: Icons.home,
              ),
              FinancialManagementItem(
                id: '2',
                name: 'Food',
                description: 'Groceries and dining',
                amount: 800.00,
                period: 'Monthly',
                icon: Icons.restaurant,
              ),
              FinancialManagementItem(
                id: '3',
                name: 'Transportation',
                description: 'Gas and public transit',
                amount: 350.00,
                period: 'Monthly',
                icon: Icons.directions_car,
              ),
              FinancialManagementItem(
                id: '4',
                name: 'Entertainment',
                description: 'Movies, games, and fun',
                amount: 400.00,
                period: 'Monthly',
                icon: Icons.movie,
              ),
              FinancialManagementItem(
                id: '5',
                name: 'Shopping',
                description: 'Clothing and general',
                amount: 450.00,
                period: 'Monthly',
                icon: Icons.shopping_bag,
              ),
              FinancialManagementItem(
                id: '6',
                name: 'Savings',
                description: 'Emergency fund',
                amount: 700.00,
                period: 'Monthly',
                icon: Icons.savings,
              ),
            ],
          ),
          
          // Loan Section
          FinancialManagementSection(
            id: '3',
            name: 'Loans',
            subtitle: 'Active loans and repayments',
            totalAmount: 1250.00,
            icon: Icons.account_balance,
            color: Colors.purple.shade700,
            emptyStateMessage: 'Track your loans and payment schedules',
            items: [
              FinancialManagementItem(
                id: '1',
                name: 'Student Loan',
                description: 'Education loan - 3.5% interest',
                amount: 450.00,
                period: 'Monthly',
                icon: Icons.school,
              ),
              FinancialManagementItem(
                id: '2',
                name: 'Car Loan',
                description: 'Auto loan - 4.2% interest',
                amount: 380.00,
                period: 'Monthly',
                icon: Icons.time_to_leave,
              ),
              FinancialManagementItem(
                id: '3',
                name: 'Personal Loan',
                description: 'Home renovation - 6.5% interest',
                amount: 420.00,
                period: 'Monthly',
                icon: Icons.home_repair_service,
              ),
            ],
          ),
        ],
        onItemTap: (section, item) {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${section.name} item: ${item.name}')),
          );
        },
        onAddItem: (section) {
          // The form dialogs are now handled directly in the UnifiedFinancialManagementPanel
          // We're just updating the UI after a new item is added
          HapticFeedback.mediumImpact();
          
          // In a real app, you'd refresh data from your data source here
          setState(() {
            // This would trigger a UI refresh when real data changes
          });
        },
        onViewAll: (section) {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View all ${section.name.toLowerCase()} items')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Smart Insights Card replacing empty heat map
      SmartInsightsCard(
        insights: [
          FinancialInsight(
            id: '1',
            title: 'Unusual spending in Shopping',
            description: 'Your shopping spending is 35% higher than last month. Consider reviewing recent purchases.',
            type: InsightType.warning,
            priority: 8,
            actionText: 'Review Transactions',
            category: 'Shopping',
            generatedDate: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          FinancialInsight(
            id: '2',
            title: 'You\'ve reached your saving goal!',
            description: 'Congratulations! You\'ve reached your Emergency Fund goal of \$5,000.',
            type: InsightType.positive,
            priority: 9,
            actionText: 'View Savings',
            category: 'Goals',
            generatedDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
          FinancialInsight(
            id: '3',
            title: 'Bill payment coming up',
            description: 'Your electricity bill of \$85 is due in 3 days. Ensure you have sufficient funds.',
            type: InsightType.alert,
            priority: 7,
            actionText: 'Schedule Payment',
            category: 'Bills',
            generatedDate: DateTime.now().subtract(const Duration(hours: 12)),
          ),
        ],
        onViewAllInsights: () {
          // Navigate to all insights
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View all insights')),
          );
        },
        onInsightAction: (insight) {
          // Handle insight action
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Insight action: ${insight.actionText}')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Budget Status Summary showing all categories
      BudgetStatusSummary(
        categories: [
          BudgetCategory(
            id: '1',
            name: 'Food & Dining',
            budgetAmount: 500,
            amountSpent: 450,
            trend: SpendingTrend.stable,
            color: Colors.green.shade700,
          ),
          BudgetCategory(
            id: '2',
            name: 'Entertainment',
            budgetAmount: 200,
            amountSpent: 210,
            trend: SpendingTrend.increasing,
            color: Colors.red.shade700,
          ),
          BudgetCategory(
            id: '3',
            name: 'Transportation',
            budgetAmount: 300,
            amountSpent: 220,
            trend: SpendingTrend.decreasing,
            color: Colors.blue.shade700,
          ),
          BudgetCategory(
            id: '4',
            name: 'Shopping',
            budgetAmount: 400,
            amountSpent: 380,
            trend: SpendingTrend.increasing,
            color: Colors.purple.shade700,
          ),
        ],
        onViewAll: () {
          // Navigate to all budgets
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View all budgets')),
          );
        },
        onAdjustBudget: (category) {
          // Navigate to budget adjustment
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Adjust budget for ${category.name}')),
          );
        },
      ),
      
      const SizedBox(height: 16),
      
      // Financial Health Score visualization
      FinancialHealthScoreCard(
        score: 78,
        previousScore: 72,
        contributingMetrics: [
          ScoreMetric(
            id: '1',
            name: 'Spending Habits',
            score: 65,
            previousScore: 60,
          ),
          ScoreMetric(
            id: '2',
            name: 'Debt Management',
            score: 85,
            previousScore: 80,
          ),
          ScoreMetric(
            id: '3',
            name: 'Savings Rate',
            score: 75,
            previousScore: 70,
          ),
          ScoreMetric(
            id: '4',
            name: 'Investment Growth',
            score: 82,
            previousScore: 78,
          ),
        ],
        onImproveScore: () {
          // Navigate to financial health improvement tips
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Improve financial health score')),
          );
        },
      ),
    ];
    
    // Add existing dashboard widgets after our custom components
    if (_dashboardConfig.widgets.isNotEmpty) {
      // Filter out duplicate monthly spending trend and empty heat map
      final filteredWidgets = _dashboardConfig.widgets.where((widget) => 
        widget.type != WidgetType.monthlySpendingTrend &&
        widget.type != WidgetType.spendingHeatMap
      ).toList();
      
      // Add remaining widgets with animations
      customWidgets.addAll(filteredWidgets.map((widgetConfig) {
        return EnhancedAnimations.cardEntrance(
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widgetConfig.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isEditMode)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editWidget(widgetConfig, widgetConfig),
                              splashRadius: 20,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _removeWidget(widgetConfig.id),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWidgetContent(widgetConfig),
                ],
              ),
            ),
          ),
          index: widgetConfig.position + customWidgets.length,
        );
      }));
    }
    
    return customWidgets;
  }
  
  // Build content for dashboard widgets based on type
  Widget _buildWidgetContent(DashboardWidgetConfig config) {
    switch (config.type) {
      case WidgetType.spendingPieChart:
        // Sample pie chart data
        return SizedBox(
          height: 200,
          child: AnimatedCircularChart(
            value: 0.7,
            label: 'Spending',
            size: 150,
            color: Colors.orange,
          ),
        );
        
      case WidgetType.monthlySpendingTrend:
        // Sample line chart data
        return AnimatedLineChart(
          dataPoints: [1200.0, 980.0, 1450.0, 1100.0, 1380.0, 1560.0],
          height: 180,
          label: 'Monthly Trend',
        );
        
      case WidgetType.budgetProgressBar:
        // Sample bar chart data
        final barData = [
          BarChartEntry(label: 'Food', value: 350.0, color: Colors.green.shade600),
          BarChartEntry(label: 'Transport', value: 250.0, color: Colors.blue.shade600),
          BarChartEntry(label: 'Bills', value: 500.0, color: Colors.red.shade600),
          BarChartEntry(label: 'Shopping', value: 320.0, color: Colors.purple.shade600),
        ];
        
        return AnimatedBarChart(
          data: barData,
          height: 200,
          label: 'Budget Categories',
        );
        
      case WidgetType.spendingHeatMap:
      case WidgetType.categoryComparison:
      default:
        // Placeholder for other widget types
        return Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              config.title,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        );
    }
  }
  
  // Animated add widget button
  Widget _buildAnimatedAddWidgetButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: AnimatedPrimaryButton(
          text: 'Add Widget',
          icon: Icons.add,
          color: Theme.of(context).colorScheme.secondary,
          onPressed: () {
            // Open widget type selection dialog
            if (_isEditMode) {
              showDialog(
                context: context,
                builder: (context) => _buildWidgetTypeSelectionDialog(),
              );
            }
          },
        ),
      ),
    );
  }
  
  // Dialog for selecting widget type to add to dashboard
  Widget _buildWidgetTypeSelectionDialog() {
    return AlertDialog(
      title: const Text('Add Widget'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the type of widget to add:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildWidgetTypeOption(
                  WidgetType.spendingPieChart,
                  'Spending Pie Chart',
                  Icons.pie_chart,
                  Colors.blue,
                ),
                _buildWidgetTypeOption(
                  WidgetType.monthlySpendingTrend,
                  'Monthly Trend',
                  Icons.show_chart,
                  Colors.green,
                ),
                _buildWidgetTypeOption(
                  WidgetType.budgetProgressBar,
                  'Budget Progress',
                  Icons.bar_chart,
                  Colors.orange,
                ),
                _buildWidgetTypeOption(
                  WidgetType.spendingHeatMap,
                  'Spending Heat Map',
                  Icons.calendar_view_month,
                  Colors.red,
                ),
                _buildWidgetTypeOption(
                  WidgetType.categoryComparison,
                  'Category Comparison',
                  Icons.compare_arrows,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            RouteSettings(name: 'widget_type_selection_dialog')
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
  
  // Widget type option for selection dialog
  Widget _buildWidgetTypeOption(
    WidgetType type,
    String title,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        // Create widget config with all required parameters
        final newWidget = DashboardWidgetConfig(
          id: const Uuid().v4(),
          title: title,
          name: title,  // Add required name parameter
          type: type,
          position: _dashboardConfig.widgets.length,
          settings: {  // Add required settings parameter
            'created': DateTime.now().toIso8601String(),
            'color': color.toARGB32().toString(),
          },
        );
        setState(() {
          _dashboardConfig.widgets.add(newWidget);
        });
        Navigator.of(context).pop(
          RouteSettings(name: 'widget_type_dialog')
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),  // Replace deprecated withOpacity
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(75)),  // Replace deprecated withOpacity
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: color.withAlpha(200), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget configuration is now handled through the settings screen
  
  Widget _buildMonthSelector() {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _previousMonth();
                // Add haptic feedback here if desired
              },
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
              onPressed: () {
                _nextMonth();
                // Add haptic feedback here if desired
              },
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
