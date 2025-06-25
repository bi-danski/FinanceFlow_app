import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../viewmodels/family_viewmodel.dart';

import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../themes/app_theme.dart';
import 'widgets/family_member_card.dart';
import 'widgets/add_family_member_button.dart';
import 'widgets/interactive_budget_chart.dart';
import 'widgets/family_goals_tracker.dart';
import 'widgets/family_spending_trends.dart';
import 'widgets/family_member_comparison.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  int _selectedIndex = 4; // Family tab selected

  @override
  void initState() {
    super.initState();
    final familyViewModel = Provider.of<FamilyViewModel>(context, listen: false);
    familyViewModel.loadFamilyMembers();
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
    final familyViewModel = Provider.of<FamilyViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to family settings
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: _buildContent(familyViewModel),
      floatingActionButton: AddFamilyMemberButton(
        onPressed: () {
          _showAddFamilyMemberDialog();
        },
      ),
    );
  }

  Widget _buildContent(FamilyViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.familyMembers.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFamilySummary(viewModel),
            const SizedBox(height: 16),
            _buildFamilyMemberList(viewModel.familyMembers),
            const SizedBox(height: 24),
            _buildInteractiveBudgetChart()
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 100))
              .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            const FamilySpendingTrends()
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200))
              .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            const FamilyMemberComparison()
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 700), delay: const Duration(milliseconds: 300))
              .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            const FamilyGoalsTracker()
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 800), delay: const Duration(milliseconds: 400))
              .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 40),
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
            Icons.people,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No family members added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first family member by tapping the + button',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySummary(FamilyViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final totalBudget = viewModel.getTotalFamilyBudget();
    final totalSpent = viewModel.getTotalFamilySpent();
    final remaining = viewModel.getRemainingFamilyBudget();
    final percentUsed = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Family Budget Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              'Budget Usage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentUsed / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentUsed.toDouble())),
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
                  color: _getProgressColor(percentUsed.toDouble()),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
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

  Widget _buildFamilyMemberList(List<dynamic> familyMembers) {
    String getProp(dynamic member, String key) {
      if (member is Map) return member[key]?.toString() ?? '';
      try {
        final value = member.toJson()[key];
        return value?.toString() ?? '';
      } catch (_) {
        try {
          return member?.$key?.toString() ?? '';
        } catch (_) {
          return '';
        }
      }
    }
    double getNumProp(dynamic member, String key) {
      if (member is Map) return (member[key] ?? 0).toDouble();
      try {
        final value = member.toJson()[key];
        return (value ?? 0).toDouble();
      } catch (_) {
        try {
          return (member?.$key ?? 0).toDouble();
        } catch (_) {
          return 0.0;
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Members',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...familyMembers.map((member) => FamilyMemberCard(
          name: getProp(member, 'name'),
          budget: getNumProp(member, 'budget'),
          spent: getNumProp(member, 'spent'),
          avatarPath: getProp(member, 'avatarPath'),
          onTap: () {},
          onAddExpense: () {
            _showAddExpenseDialog(getProp(member, 'name'));
          },
        )),
      ],
    );
  }

  Widget _buildInteractiveBudgetChart() {
    return const InteractiveBudgetChart();
  }

  void _showAddFamilyMemberDialog() {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Family Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget',
                  prefixText: '\$',
                ),
              ),
            ],
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
                // Add family member
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseDialog(String memberName) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Expense for $memberName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ],
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
                // Add expense
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
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
