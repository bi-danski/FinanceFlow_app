import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/budget_viewmodel.dart';
import '../../models/budget_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import 'budget_form_screen.dart';
import 'widgets/budget_card.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({Key? key}) : super(key: key);

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  int _selectedIndex = 1; // Expenses tab selected (can be adjusted)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
      await budgetViewModel.loadBudgets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budgets: $e')),
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

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation would be handled here
  }

  @override
  Widget build(BuildContext context) {
    final budgetViewModel = Provider.of<BudgetViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              // Navigate to budget analytics
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBudgets,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(budgetViewModel),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BudgetFormScreen(),
            ),
          );
          
          if (result == true) {
            // Refresh the list if a budget was added
            _loadBudgets();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(BudgetViewModel viewModel) {
    if (viewModel.budgets.isEmpty) {
      return _buildEmptyState();
    }
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetSummary(viewModel),
            const SizedBox(height: 16),
            const Text(
              'Your Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // For demo purposes, we'll use mock data
            ..._buildMockBudgetCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No budgets created yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first budget by tapping the + button',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetFormScreen(),
                ),
              );
              
              if (result == true) {
                // Refresh the list if a budget was added
                _loadBudgets();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(BudgetViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final totalBudget = viewModel.getTotalBudget();
    final totalSpent = viewModel.getTotalSpent();
    final remaining = viewModel.getRemainingBudget();
    final percentUsed = viewModel.getPercentUsed();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Budget',
                  currencyFormat.format(totalBudget),
                  AppTheme.primaryColor,
                ),
                _buildSummaryItem(
                  'Total Spent',
                  currencyFormat.format(totalSpent),
                  AppTheme.expenseColor,
                ),
                _buildSummaryItem(
                  'Remaining',
                  currencyFormat.format(remaining),
                  AppTheme.incomeColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Overall Budget Usage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentUsed / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentUsed)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${percentUsed.toStringAsFixed(1)}% used',
                style: TextStyle(
                  fontSize: 12,
                  color: _getProgressColor(percentUsed),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMockBudgetCards() {
    // Mock data for initial UI
    final List<Map<String, dynamic>> mockBudgets = [
      {
        'category': 'Food',
        'amount': 500.0,
        'spent': 350.0,
        'startDate': DateTime.now().subtract(const Duration(days: 15)),
        'endDate': DateTime.now().add(const Duration(days: 15)),
      },
      {
        'category': 'Transport',
        'amount': 200.0,
        'spent': 120.0,
        'startDate': DateTime.now().subtract(const Duration(days: 15)),
        'endDate': DateTime.now().add(const Duration(days: 15)),
      },
      {
        'category': 'Entertainment',
        'amount': 150.0,
        'spent': 80.0,
        'startDate': DateTime.now().subtract(const Duration(days: 15)),
        'endDate': DateTime.now().add(const Duration(days: 15)),
      },
      {
        'category': 'Shopping',
        'amount': 300.0,
        'spent': 250.0,
        'startDate': DateTime.now().subtract(const Duration(days: 15)),
        'endDate': DateTime.now().add(const Duration(days: 15)),
      },
    ];
    
    return mockBudgets.map((budgetData) {
      final budget = Budget(
        category: budgetData['category'],
        amount: budgetData['amount'],
        spent: budgetData['spent'],
        startDate: budgetData['startDate'],
        endDate: budgetData['endDate'],
      );
      
      return BudgetCard(
        budget: budget,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetFormScreen(budget: budget),
            ),
          );
          
          if (result == true || result == 'deleted') {
            // Refresh the list if a budget was updated or deleted
            _loadBudgets();
          }
        },
      );
    }).toList();
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 50) {
      return AppTheme.successColor;
    } else if (percentage < 80) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }
}
