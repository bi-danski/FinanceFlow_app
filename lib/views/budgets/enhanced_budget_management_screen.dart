import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/budget_model.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../widgets/budget/interactive_budget_wheel.dart';
import '../../widgets/budget/budget_timeline_chart.dart';
import '../../widgets/budget/smart_budget_recommendations.dart';

class EnhancedBudgetManagementScreen extends StatefulWidget {
  const EnhancedBudgetManagementScreen({super.key});

  @override
  State<EnhancedBudgetManagementScreen> createState() => _EnhancedBudgetManagementScreenState();
}

class _EnhancedBudgetManagementScreenState extends State<EnhancedBudgetManagementScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 3; // Budget tab index
  late TabController _tabController;
  final List<String> _tabLabels = ['Dashboard', 'Timeline', 'Recommendations'];
  String _selectedPeriod = 'monthly';
  String _selectedCategory = 'all';
  bool _isLoading = false;
  
  // Mock total income (in real app, this would come from income data)
  final double _mockTotalIncome = 5000.0;
  
  // Mock spending history data (in real app, this would come from transactions)
  final List<Map<String, dynamic>> _mockSpendingHistory = [
    {
      'date': DateTime.now().subtract(const Duration(days: 25)),
      'category': 'Housing',
      'amount': 1500.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 20)),
      'category': 'Groceries',
      'amount': 350.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 18)),
      'category': 'Dining Out',
      'amount': 120.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 15)),
      'category': 'Transportation',
      'amount': 200.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 12)),
      'category': 'Entertainment',
      'amount': 80.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'category': 'Utilities',
      'amount': 180.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'category': 'Groceries',
      'amount': 210.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'category': 'Healthcare',
      'amount': 90.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'category': 'Entertainment',
      'amount': 65.0,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'category': 'Dining Out',
      'amount': 85.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    
    // Load budgets when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Helper method to handle navigation item selection
  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    String route = NavigationService.routeForDrawerIndex(index);

    // Close drawer if open
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Navigate only if not already on target route
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  Future<void> _loadBudgets() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Safely capture context before async gap
      final viewModel = Provider.of<BudgetViewModel>(context, listen: false);
      await viewModel.loadBudgets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading budgets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBudgetChange(String category, double newAmount) {
    final viewModel = Provider.of<BudgetViewModel>(context, listen: false);
    final existingBudget = viewModel.getBudgetByCategory(category);
    
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1); // First day of current month
    final endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
    
    if (existingBudget != null) {
      // Update existing budget
      final updatedBudget = Budget(
        id: existingBudget.id,
        category: category,
        amount: newAmount,
        startDate: existingBudget.startDate,
        endDate: existingBudget.endDate,
        spent: existingBudget.spent,
      );
      viewModel.addBudget(updatedBudget);
    } else {
      // Create new budget
      final newBudget = Budget(
        category: category,
        amount: newAmount,
        startDate: startDate,
        endDate: endDate,
      );
      viewModel.addBudget(newBudget);
    }
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category budget updated'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handlePeriodChange(String period) {
    setState(() {
      _selectedPeriod = period;
    });
  }

  void _handleCategoryChange(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _handleRecommendationApply(Budget budget) {
    final viewModel = Provider.of<BudgetViewModel>(context, listen: false);
    viewModel.addBudget(budget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Budget Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Consumer<BudgetViewModel>(
        builder: (context, viewModel, child) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final budgets = viewModel.budgets;
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Dashboard Tab with Interactive Budget Wheel
              _buildDashboardTab(budgets, viewModel),
              
              // Timeline Tab
              _buildTimelineTab(budgets),
              
              // Recommendations Tab
              _buildRecommendationsTab(budgets),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to budget creation/edit screen
          // Navigator.of(context).pushNamed('/budget_form');
        },
        tooltip: 'Add Budget',
        child: const Icon(Icons.add),
      ).animate()
        .scale(delay: const Duration(milliseconds: 300), duration: const Duration(milliseconds: 600)),
    );
  }

  Widget _buildDashboardTab(List<Budget> budgets, BudgetViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Budget Summary Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Budget Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total',
                          viewModel.getTotalBudget(),
                          Colors.blue.shade700,
                          Icons.account_balance_wallet,
                        ),
                        _buildSummaryItem(
                          'Spent',
                          viewModel.getTotalSpent(),
                          Colors.orange.shade700,
                          Icons.shopping_cart,
                        ),
                        _buildSummaryItem(
                          'Remaining',
                          viewModel.getRemainingBudget(),
                          Colors.green.shade700,
                          Icons.savings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: viewModel.getPercentUsed() / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        viewModel.getPercentUsed() > 90 ? Colors.red : 
                        viewModel.getPercentUsed() > 75 ? Colors.orange : 
                        Colors.green,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${viewModel.getPercentUsed().toStringAsFixed(1)}% Used',
                        style: TextStyle(
                          color: viewModel.getPercentUsed() > 90 ? Colors.red : 
                                viewModel.getPercentUsed() > 75 ? Colors.orange : 
                                Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600))
              .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 600)),
          ),
          
          const SizedBox(height: 20),
          
          // Interactive Budget Wheel
          if (budgets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 320,
                child: InteractiveBudgetWheel(
                  budgets: budgets,
                  totalBudget: viewModel.getTotalBudget(),
                  onBudgetChanged: _handleBudgetChange,
                ),
              ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 800), delay: const Duration(milliseconds: 300))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: const Duration(milliseconds: 800)),
              
          const SizedBox(height: 20),
          
          // Budget Categories List
          _buildCategoriesList(budgets),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, IconData icon) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList(List<Budget> budgets) {
    if (budgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No budgets set yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first budget to get started',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to budget creation screen
                  // Navigator.of(context).pushNamed('/budget_form');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Budget'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Budget Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            final percentUsed = budget.percentUsed;
            
            // Color based on usage
            final progressColor = percentUsed > 100 ? Colors.red : 
                            percentUsed > 80 ? Colors.orange : 
                            Colors.green;
            
            return Padding(
              padding: EdgeInsets.only(
                left: 20, 
                right: 20, 
                bottom: 8, 
                top: index == 0 ? 8 : 0,
              ),
              child: Card(
                elevation: 1,
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
                            budget.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${percentUsed.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: progressColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (percentUsed / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${budget.spent.toStringAsFixed(2)} spent',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '\$${budget.amount.toStringAsFixed(2)} budget',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ).animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index), duration: const Duration(milliseconds: 400))
              .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: 100 * index), duration: const Duration(milliseconds: 400));
          },
        ),
      ],
    );
  }

  Widget _buildTimelineTab(List<Budget> budgets) {
    return SizedBox(
      height: double.infinity,
      child: BudgetTimelineChart(
        budgets: budgets,
        spendingHistory: _mockSpendingHistory,
        selectedPeriod: _selectedPeriod,
        onPeriodChanged: _handlePeriodChange,
        selectedCategory: _selectedCategory,
        onCategoryChanged: _handleCategoryChange,
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.05, end: 0, duration: const Duration(milliseconds: 600));
  }

  Widget _buildRecommendationsTab(List<Budget> budgets) {
    return SmartBudgetRecommendations(
      budgets: budgets,
      totalIncome: _mockTotalIncome,
      onApplyRecommendation: _handleRecommendationApply,
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.05, end: 0, duration: const Duration(milliseconds: 600));
  }
}
