import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';

class FamilyBudgetCard extends StatelessWidget {
  FamilyBudgetCard({super.key});

  // Mock data for initial UI
  final List<Map<String, dynamic>> _mockFamilyMembers = [
    {
      'name': 'John',
      'budget': 1850.0,
      'spent': 1350.0,
      'avatarPath': null,
    },
    {
      'name': 'Sarah',
      'budget': 1650.0,
      'spent': 850.0,
      'avatarPath': null,
    },
    {
      'name': 'Kids',
      'budget': 550.0,
      'spent': 350.0,
      'avatarPath': null,
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
                  'Family Budget',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _mockFamilyMembers
                  .map((member) => _buildFamilyMemberItem(context, member))
                  .toList(),
            ),
            const SizedBox(height: 24),
            _buildFamilyBudgetChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberItem(BuildContext context, Map<String, dynamic> member) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withAlpha(25),
          child: Text(
            member['name'][0],
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          member['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(member['budget']),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyBudgetChart() {
    return SizedBox(
      height: 150,
      child: Image.asset(
        'assets/images/family_budget_chart.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Family Budget Chart',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
