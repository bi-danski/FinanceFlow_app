import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';

class SavingsGoalsCard extends StatelessWidget {
  SavingsGoalsCard({super.key});

  // Mock data for initial UI
  final List<Map<String, dynamic>> _mockGoals = [
    {
      'name': 'Vacation Fund',
      'currentAmount': 1400.0,
      'targetAmount': 3000.0,
    },
    {
      'name': 'Emergency Fund',
      'currentAmount': 4200.0,
      'targetAmount': 10000.0,
    },
    {
      'name': 'New Laptop',
      'currentAmount': 600.0,
      'targetAmount': 1200.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Savings Goals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Show more options
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._mockGoals.map((goal) => _buildGoalItem(context, goal)),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to goals screen
                },
                child: const Text('View All Goals'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, Map<String, dynamic> goal) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final progress = goal['currentAmount'] / goal['targetAmount'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currencyFormat.format(goal['currentAmount'])} / ${currencyFormat.format(goal['targetAmount'])}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return AppTheme.errorColor;
    } else if (progress < 0.7) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.successColor;
    }
  }
}
