import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';
import '../../../models/transaction_model.dart' as models;
import '../../../views/transactions/transaction_details_screen.dart';

class ExpenseListItem extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime date;
  final String category;

  const ExpenseListItem({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd');
    
    // Create a Transaction object from the provided data
    final transaction = models.Transaction(
      title: title,
      amount: -amount, // Make it negative for expense
      date: date,
      category: category,
      id: '',
      type: models.TransactionType.expense,
      status: models.TransactionStatus.completed,
      userId: '',
    );
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailsScreen(
                transaction: transaction,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildCategoryIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.expenseColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: _getCategoryColor(),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildCategoryIcon() {
    IconData iconData;
    
    switch (category) {
      case 'Food':
        iconData = Icons.restaurant;
        break;
      case 'Transport':
        iconData = Icons.directions_car;
        break;
      case 'Shopping':
        iconData = Icons.shopping_bag;
        break;
      case 'Bills':
        iconData = Icons.receipt;
        break;
      case 'Entertainment':
        iconData = Icons.movie;
        break;
      case 'Health':
        iconData = Icons.medical_services;
        break;
      case 'Housing':
        iconData = Icons.home;
        break;
      default:
        iconData = Icons.category;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: _getCategoryColor(),
        size: 24,
      ),
    );
  }

  Color _getCategoryColor() {
    if (AppTheme.categoryColors.containsKey(category)) {
      return AppTheme.categoryColors[category]!;
    }
    return AppTheme.categoryColors['Other']!;
  }
}
