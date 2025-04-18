import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';

class FamilyMemberCard extends StatelessWidget {
  final String name;
  final double budget;
  final double spent;
  final String? avatarPath;
  final VoidCallback onTap;
  final VoidCallback onAddExpense;

  const FamilyMemberCard({
    super.key,
    required this.name,
    required this.budget,
    required this.spent,
    this.avatarPath,
    required this.onTap,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final remaining = budget - spent;
    final percentUsed = (spent / budget) * 100;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Budget: ${currencyFormat.format(budget)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Spent: ${currencyFormat.format(spent)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining: ${currencyFormat.format(remaining)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: remaining >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Budget Usage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percentUsed.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getProgressColor(percentUsed),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: spent / budget,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentUsed)),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: onAddExpense,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (avatarPath != null) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: AssetImage(avatarPath!),
      );
    }
    
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Text(
        name[0],
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
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
