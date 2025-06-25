import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/budget_viewmodel.dart';

import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import '../../services/navigation_service.dart';
import 'budget_form_screen.dart';
import 'widgets/budget_card.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  int _selectedIndex = 1; 
  late BudgetViewModel _budgetViewModel;

  @override
  void initState() {
    super.initState();
    _budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
    _budgetViewModel.loadBudgets();
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Map index to route
    String? route;
    switch (index) {
      case 0: route = '/dashboard'; break;
      case 1: route = '/expenses'; break;
      case 2: route = '/enhanced-goals'; break;
      case 3: route = '/reports'; break;
      case 4: route = '/family'; break;
      case 5: route = '/settings'; break;
      case 6: route = '/income'; break;
      case 7: route = '/budgets'; break;
      case 8: route = '/loans'; break;
      case 9: route = '/insights'; break;
      case 10: route = '/spending-heatmap'; break;
      case 11: route = '/spending-challenges'; break;
      case 12: route = '/profile'; break;
      default: route = '/dashboard';
    }
    // Always close the drawer
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    // Only navigate if not already on the target route
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        onRefresh: () => _budgetViewModel.loadBudgets(),
        child: _budgetViewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(_budgetViewModel),
      ),
      floatingActionButton: Builder(
        builder: (localContext) {
          return FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                localContext,
                MaterialPageRoute(
                  builder: (context) => const BudgetFormScreen(),
                ),
              );
              if (!localContext.mounted) return;
              if (result == true) {
                Provider.of<BudgetViewModel>(localContext, listen: false).loadBudgets();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Budget'),
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildContent(BudgetViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
            // Display real budgets
            ...viewModel.budgets.map((budget) => BudgetCard(
              budget: budget,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BudgetFormScreen(budget: budget),
                  ),
                );
                if (result == true || result == 'deleted') {
                  viewModel.loadBudgets();
                }
              },
            )),
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
              if (!mounted) return;
              if (result == true) {
                Provider.of<BudgetViewModel>(context, listen: false).loadBudgets();
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
