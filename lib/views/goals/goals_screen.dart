import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/goal_viewmodel.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import 'widgets/goal_card.dart';
import 'widgets/add_goal_button.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  int _selectedIndex = 2; // Goals tab selected

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
    setState(() {
      _selectedIndex = index;
    });
    // Navigation would be handled here
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
        onPressed: () {
          // Navigate to add goal screen
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
    
    // For demo purposes, we'll use mock data
    final mockGoals = [
      {
        'name': 'Vacation Fund',
        'currentAmount': 1400.0,
        'targetAmount': 3000.0,
        'targetDate': DateTime.now().add(const Duration(days: 120)),
        'category': 'Vacation',
      },
      {
        'name': 'Emergency Fund',
        'currentAmount': 4200.0,
        'targetAmount': 10000.0,
        'targetDate': DateTime.now().add(const Duration(days: 365)),
        'category': 'Emergency Fund',
      },
      {
        'name': 'New Laptop',
        'currentAmount': 600.0,
        'targetAmount': 1200.0,
        'targetDate': DateTime.now().add(const Duration(days: 60)),
        'category': 'Electronics',
      },
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: mockGoals.length,
      itemBuilder: (context, index) {
        final goal = mockGoals[index];
        return GoalCard(
          name: goal['name'] as String,
          currentAmount: goal['currentAmount'] as double,
          targetAmount: goal['targetAmount'] as double,
          targetDate: goal['targetDate'] as DateTime,
          category: goal['category'] as String,
          onTap: () {
            // Navigate to goal details
          },
          onAddFunds: () {
            _showAddFundsDialog(goal['name'] as String);
          },
        );
      },
    );
  }

  void _showAddFundsDialog(String goalName) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add funds to $goalName'),
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
                // Add funds to goal
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
