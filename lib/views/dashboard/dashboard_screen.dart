import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Services
import '../../services/transaction_service.dart';
import '../../services/realtime_data_service.dart';

// Models
import '../../models/transaction_model.dart' as models;

// Widgets
import '../../widgets/error_widget.dart' as app_error;
import 'package:financeflow_app/views/dashboard/widgets/dashboard_financial_summary.dart';
import 'package:financeflow_app/views/dashboard/widgets/financial_summary_card.dart';
import 'package:financeflow_app/views/dashboard/widgets/spending_trend_chart.dart';
import 'package:financeflow_app/views/dashboard/widgets/upcoming_bills_card.dart';
import './widgets/quick_actions_panel.dart';
import '../../widgets/animated_button.dart';

// Theme
import '../../themes/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import './widgets/visualizations/animated_pie_chart.dart';
import '../../constants/app_constants.dart';

/// Dashboard screen showing financial overview, recent transactions, and quick actions
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TransactionService _transactionService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final AnimationController _animationController;
  bool _isRefreshing = false;
  bool _isLoading = true;
  bool _isError = false;
  
  // Dashboard data
  double _income = 0.0;
  double _expenses = 0.0;
  double _balance = 0.0;
  Map<String, double> _categoryTotals = {};
  List<models.Transaction> _recentTransactions = [];
  int _selectedMonthIndex = DateTime.now().month - 1;
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  List<String> _frequentPayees = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Load initial data and set up real-time listeners
    _loadDashboardData();
    
    // Start entrance animation
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _transactionService = Provider.of<TransactionService>(context, listen: false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Load real-time dashboard data from Firestore
  Future<void> _loadDashboardData() async {
    // Allow refresh even if already loading, but ensure isLoading is set correctly.
    if (!mounted) return; // Check if the widget is still in the tree

    setState(() {
      _isLoading = true; // Set loading to true at the start of data fetching
      _isError = false;
    });

    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) { // Added mounted check here for consistency
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch frequent payees (once per load/refresh)
      final fetchedPayees = await _transactionService.getFrequentPayees(limit: 3);
      if (mounted) {
        setState(() {
          _frequentPayees = fetchedPayees;
        });
      }

      // Get current month for filtering
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, _selectedMonthIndex + 1);

      // Listen for transaction changes for the selected month
      _transactionService.getTransactionsByMonth(currentMonth)
          .listen((transactions) {
            if (!mounted) return;
            
            // Calculate financial summary
            double income = 0.0;
            double expenses = 0.0;
            Map<String, double> categoryTotals = {};

            for (final transaction in transactions) {
              if (!transaction.isExpense) {
                income += transaction.amount.abs();
              } else {
                expenses += transaction.amount.abs();
              }

              // Update category totals
              final category = transaction.category;
              if (transaction.isExpense) {
                categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount.abs();
              }
            }

            // Sort transactions by date (newest first)
            transactions.sort((a, b) => b.date.compareTo(a.date));
            // Take the 5 most recent
            final recentTransactions = transactions.take(5).toList();

            // Update state with calculated values
            setState(() {
              _income = income;
              _expenses = expenses;
              _balance = income - expenses;
              _categoryTotals = categoryTotals;
              _recentTransactions = recentTransactions;
              _isLoading = false;
            });
          }, onError: (error) {
            if (!mounted) return;
            setState(() {
              _isError = true;
              _isLoading = false;
            });
          });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  /// Refresh dashboard data with animation
  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadDashboardData();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access RealtimeDataService for real-time updates when needed
    Provider.of<RealtimeDataService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: 0, // Changed currentIndex to selectedIndex
        onItemSelected: (index) {
          String? routeName;
          switch (index) {
            case 0: // Dashboard
              routeName = AppConstants.dashboardRoute; // Note: Dashboard route in AppConstants is '/dashboard', but '/' is typical for home.
                                                  // Assuming '/' is correct for the main dashboard screen as per previous logic.
              if (ModalRoute.of(context)?.settings.name == AppConstants.dashboardRoute) {
                routeName = null; // Avoid navigation if already on /dashboard
              } else if (ModalRoute.of(context)?.settings.name == '/') {
                routeName = null; // Avoid navigation if already on /
              } else {
                routeName = '/'; // Default to '/' if not on /dashboard or /
              }
              break;
            case 1: // Expenses
              routeName = AppConstants.expensesRoute;
              break;
            case 2: // Goals
              routeName = AppConstants.goalsRoute; // Corrected from '/enhanced-goals' to use constant
              break;
            case 3: // Reports
              routeName = AppConstants.reportsRoute;
              break;
            case 4: // Family
              routeName = AppConstants.familyRoute;
              break;
            case 5: // Settings
              routeName = AppConstants.settingsRoute;
              break;
            case 6: // Income
              routeName = AppConstants.incomeRoute;
              break;
            case 7: // Budgets
              routeName = AppConstants.budgetsRoute;
              break;
            case 8: // Loans
              routeName = AppConstants.loansRoute;
              break;
            case 9: // AI Insights
              routeName = AppConstants.insightsRoute;
              break;
            case 10: // Spending Heatmap
              routeName = AppConstants.spendingHeatmapRoute;
              break;
            case 11: // Challenges
              routeName = AppConstants.spendingChallengesRoute;
              break;
            case 12: // Profile
              routeName = AppConstants.profileRoute;
              break;
            default:
              break;
          }

          if (routeName != null && routeName != ModalRoute.of(context)?.settings.name) {
            Navigator.pushReplacementNamed(context, routeName);
          } else if (routeName != null) {
            Navigator.pop(context); // Close drawer if already on the page
          }
        },
      ),
      body: _buildBody(context),
      // bottomNavigationBar: _buildBottomNavigationBar(context), // Removed
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return Center(
        child: app_error.ErrorWidget(
          errorMessage: 'Failed to load dashboard data',
          onRetry: _refreshDashboard,
        ),
      );
    }

    // Main body animation is now handled by flutter_animate on SingleChildScrollView

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 16),
            // Financial summary showing income, expenses, and balance
            DashboardFinancialSummary(
              income: _income,
              expenses: _expenses,
              savings: _balance > 0 ? _balance : 0,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 24),
            // Financial summary card with chart visualization
            FinancialSummaryCard(
              income: _income,
              expenses: _expenses,
              balance: _balance,
              categoryTotals: _categoryTotals,
              isRefreshing: _isRefreshing,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 24),
            // Recent transactions
            _buildRecentTransactionsSection(), // This already has its own .animate().fadeIn()
            const SizedBox(height: 24),
            // Quick action buttons
            QuickActionsPanel(
                recentPayees: _frequentPayees, // Use dynamic payees
                onActionSelected: (action) {
                  switch (action) {
                    case 'add_expense':
                    case 'add_income':
                      Navigator.pushNamed(context, '/add_transaction');
                      break;
                    case 'new_bill':
                      Navigator.pushNamed(context, '/add_bill');
                      break;
                    case 'new_goal':
                      Navigator.pushNamed(context, '/add_goal');
                      break;
                    default:
                      break;
                  }
                },
                onPayeeSelected: (payee) {
                  // Navigate to add transaction with pre-filled payee
                  Navigator.pushNamed(
                    context, 
                    '/add_transaction',
                    arguments: {'payee': payee}
                  );
                },
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms), // Keep existing item animation
            const SizedBox(height: 24),
            // Spending by category
            const SpendingTrendChart().animate().fadeIn(delay: 600.ms, duration: 500.ms),
            const UpcomingBillsCard().animate().fadeIn(delay: 700.ms, duration: 500.ms),
            _buildSpendingByCategory().animate().fadeIn(delay: 800.ms, duration: 500.ms),
            const SizedBox(height: 70), // Space for FAB
          ],
        ),
      ).animate(controller: _animationController) // Apply the controller here
          .slideY(begin: 0.1, end: 0.0, duration: 500.ms, curve: Curves.easeOut)
          .fadeIn(duration: 500.ms, curve: Curves.easeInOut),
    );
  }

  Widget _buildMonthSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedMonthIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_months[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMonthIndex = index;
                  });
                  _loadDashboardData();
                }
              },
              backgroundColor: Colors.grey.withValues(alpha: 0.1 * 255),
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2 * 255),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 50.ms, duration: 400.ms);
  }

  // Removed _buildBottomNavigationBar method as it's no longer used
  /*
  Widget _buildBottomNavigationBar(BuildContext context) {
    // ... (original content of _buildBottomNavigationBar)
  }
  */

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/transactions');
              },
              child: Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentTransactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  AnimatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add_transaction');
                    },
                    text: 'Add Your First Transaction',
                    color: AppTheme.primaryColor,
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _recentTransactions[index];
              return _buildTransactionCard(transaction, index);
            },
          ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildTransactionCard(models.Transaction transaction, int index) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isExpense = transaction.isExpense;
    final backgroundColor = isExpense
        ? Colors.red.withValues(alpha: 0.1 * 255)
        : Colors.green.withValues(alpha: 0.1 * 255);
    final textColor = isExpense ? Colors.red : Colors.green;
    final iconData = isExpense ? Icons.arrow_downward : Icons.arrow_upward;
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(iconData, color: textColor),
        ),
        title: Text(transaction.title),
        subtitle: Text(
          '${transaction.category} • ${DateFormat.yMMMd().format(transaction.date)}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Text(
          currencyFormat.format(transaction.amount.abs()),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        onTap: () {
          // Show transaction details safely
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(
                context,
                '/transaction_details',
                arguments: transaction,
              );
            });
          }
        },
      ),
    ).animate().fadeIn(delay: (100 * index).ms, duration: 400.ms);
  }

  Widget _buildSpendingByCategory() {
    if (_categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert to list of entries for the chart
    final entries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 5 categories
    final topCategories = entries.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending by Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: AnimatedPieChart(
            data: Map.fromEntries(topCategories.map((entry) => 
              MapEntry(entry.key, entry.value)
            )),
          ),
        ),
        const SizedBox(height: 16),
        ...topCategories.map((entry) => _buildCategoryItem(entry.key, entry.value)),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  Widget _buildCategoryItem(String category, double amount) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final percentage = _expenses > 0 ? (amount / _expenses * 100) : 0;
    
    // Generate a color based on the category name using a hash code
    final categoryColor = Colors.primaries[category.hashCode % Colors.primaries.length];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            category,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '(${percentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Local AppNavigationDrawer class definition removed.