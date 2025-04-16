import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';
import '../../../models/transaction_model.dart';
import '../../../views/transactions/transaction_details_screen.dart';

class RecentTransactionsCard extends StatelessWidget {
  RecentTransactionsCard({Key? key}) : super(key: key);

  // Mock data for initial UI
  final List<Map<String, dynamic>> _mockTransactions = [
    {
      'title': 'Grocery Store',
      'amount': -120.0,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'category': 'Food',
    },
    {
      'title': 'Gas Station',
      'amount': -45.0,
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'category': 'Transport',
    },
    {
      'title': 'Water Bill',
      'amount': -35.0,
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'category': 'Bills',
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
                  'Recent Transactions',
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
            const SizedBox(height: 8),
            _buildTransactionsList(context),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to transactions screen
                  Navigator.pushNamed(context, '/expenses');
                },
                child: const Text('View All Transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Column(
      children: [
        _buildTransactionHeader(),
        const Divider(),
        ..._mockTransactions.map((transaction) => _buildTransactionItem(context, transaction)).toList(),
      ],
    );
  }

  Widget _buildTransactionHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd');
    
    final isExpense = transaction['amount'] < 0;
    final amountColor = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final amountPrefix = isExpense ? '' : '+';
    
    // Create a Transaction object from the mock data
    final transactionObj = Transaction(
      title: transaction['title'],
      amount: transaction['amount'],
      date: transaction['date'],
      category: transaction['category'],
    );
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              transaction: transactionObj,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                transaction['title'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(transaction['category']).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction['category'],
                  style: TextStyle(
                    color: _getCategoryColor(transaction['category']),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$amountPrefix${currencyFormat.format(transaction['amount'].abs())}',
                style: TextStyle(
                  fontSize: 14,
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                dateFormat.format(transaction['date']),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (AppTheme.categoryColors.containsKey(category)) {
      return AppTheme.categoryColors[category]!;
    }
    return AppTheme.categoryColors['Other']!;
  }
}
