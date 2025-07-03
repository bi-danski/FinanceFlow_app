import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/navigation_service.dart';
import '../../constants/app_constants.dart';

import '../../viewmodels/goal_viewmodel.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import 'widgets/goal_card.dart';
import 'add_goal_screen.dart';
import 'goal_details_screen.dart';
import '../../models/goal_model.dart';
import 'widgets/add_goal_button.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final int _selectedIndex = 2; // Goals tab selected

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goalViewModel = Provider.of<GoalViewModel>(context, listen: false);
    await goalViewModel.loadGoals();
  }

  void _onItemSelected(int index) {
    Navigator.of(context).pop(); // close drawer
    switch (index) {
      case 0:
        NavigationService.navigateTo(AppConstants.dashboardRoute);
        break;
      case 1:
        NavigationService.navigateTo(AppConstants.expensesRoute);
        break;
      case 6:
        NavigationService.navigateTo(AppConstants.incomeRoute);
        break;
      case 7:
        NavigationService.navigateTo('/budgets');
        break;
      case 8:
        NavigationService.navigateTo(AppConstants.loansRoute);
        break;
      case 3:
        NavigationService.navigateTo(AppConstants.reportsRoute);
        break;
      case 9:
        NavigationService.navigateTo(AppConstants.insightsRoute);
        break;
      case 4:
        NavigationService.navigateTo(AppConstants.familyRoute);
        break;
      case 5:
        NavigationService.navigateTo(AppConstants.settingsRoute);
        break;
      case 10:
        NavigationService.navigateTo(AppConstants.profileRoute);
        break;
      default:
        // already on Goals (index 2) or unknown
        break;
    }

  }

  @override
  Widget build(BuildContext context) {
    final goalViewModel = Provider.of<GoalViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Show sorting options
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
          _buildSummaryCard(goalViewModel),
          Expanded(
            child: _buildGoalsList(goalViewModel),
          ),
        ],
      ),
      floatingActionButton: AddGoalButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddGoalScreen(),
            ),
          );
          if (added == true) {
            _loadGoals();
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard(GoalViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final totalGoals = viewModel.getTotalSavingsGoals();
    final currentSavings = viewModel.getTotalCurrentSavings();
    final progress = viewModel.getOverallProgress();
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Savings Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormat.format(currentSavings),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'of ${currencyFormat.format(totalGoals)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList(GoalViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (viewModel.goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No savings goals yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first goal by tapping the + button',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    final goals = viewModel.goals;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return GoalCard(
          name: goal.name,
          currentAmount: goal.currentAmount,
          targetAmount: goal.targetAmount,
          targetDate: goal.targetDate ?? DateTime.now(),
          category: goal.category ?? 'General',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GoalDetailsScreen(goal: goal),
              ),
            );
          },
          onAddFunds: () {
            _showAddFundsDialog(goal);
          },
        );
      },
    );
  }

  void _showAddFundsDialog(Goal goal) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add funds to ${goal.name}'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount != null && amount > 0) {
                  final vm = Provider.of<GoalViewModel>(context, listen: false);
                  vm.updateGoalProgress(goal, amount);
                }
                Navigator.pop(context);
              },
              child: const Text('Add Funds'),
            ),
          ],
        );
      },
    );
  }
}
