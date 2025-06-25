import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';

/// Dashboard recent transactions widget
class DashboardTransactions extends StatelessWidget {
  final List<Transaction> transactions;
  final int maxItems;
  final Function(Transaction)? onTransactionTap;

  const DashboardTransactions({
    super.key,
    required this.transactions,
    this.maxItems = 5,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final recentTransactions = transactions.isEmpty 
        ? [] 
        : transactions
            .take(maxItems)
            .toList();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1 * 255),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/transactions');
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentTransactions.isEmpty)
              _buildEmptyState()
            else
              ...recentTransactions.asMap().entries.map(
                (entry) => _buildTransactionItem(
                  context,
                  entry.value,
                  delay: 100.ms + (entry.key * 50).ms,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget when no transactions are available
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No recent transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to see it here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  /// Build a transaction item in the list
  Widget _buildTransactionItem(
    BuildContext context, 
    Transaction transaction,
    {required Duration delay}
  ) {
    final dateFormat = DateFormat('MMM d');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return InkWell(
      onTap: () {
        if (onTransactionTap != null) {
          onTransactionTap!(transaction);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getCategoryColor(transaction.category).withValues(alpha: 0.1 * 255),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(transaction.category),
                color: _getCategoryColor(transaction.category),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.category} • ${dateFormat.format(transaction.date)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              currencyFormat.format(transaction.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: transaction.isExpense ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay, duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  /// Get color for transaction category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Colors.orange;
      case 'transport':
      case 'transportation':
      case 'travel':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'utilities':
      case 'bills':
        return Colors.teal;
      case 'housing':
      case 'rent':
      case 'mortgage':
        return Colors.brown;
      case 'entertainment':
        return Colors.deepPurple;
      case 'health':
      case 'medical':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'salary':
      case 'income':
      case 'wage':
        return Colors.green;
      case 'investment':
        return Colors.lightBlue;
      case 'gift':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }

  /// Get icon for transaction category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
      case 'travel':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
      case 'bills':
        return Icons.receipt_long;
      case 'housing':
      case 'rent':
      case 'mortgage':
        return Icons.home;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'salary':
      case 'income':
      case 'wage':
        return Icons.monetization_on;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }
}
