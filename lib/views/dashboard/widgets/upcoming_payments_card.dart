import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';

class UpcomingPaymentsCard extends StatelessWidget {
  UpcomingPaymentsCard({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _mockUpcomingPayments = [
    {
      'name': 'Rent',
      'amount': 1200.0,
      'dueDate': DateTime.now().add(const Duration(days: 12)),
      'status': 'Upcoming',
    },
    {
      'name': 'Electricity',
      'amount': 85.0,
      'dueDate': DateTime.now().add(const Duration(days: 9)),
      'status': 'Urgent',
    },
    {
      'name': 'Internet',
      'amount': 60.0,
      'dueDate': DateTime.now().add(const Duration(days: 6)),
      'status': 'Paid',
    },
    {
      'name': 'Car Loan',
      'amount': 350.0,
      'dueDate': DateTime.now().add(const Duration(days: 14)),
      'status': 'Upcoming',
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
                  'Upcoming Payments',
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
            _buildPaymentsList(),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to see all payments
                },
                child: const Text('View All'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    return Column(
      children: [
        _buildPaymentHeader(),
        const Divider(),
        ..._mockUpcomingPayments.map((payment) => _buildPaymentItem(payment)).toList(),
      ],
    );
  }

  Widget _buildPaymentHeader() {
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
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Due Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd');
    
    Color statusColor;
    switch (payment['status']) {
      case 'Paid':
        statusColor = AppTheme.successColor;
        break;
      case 'Urgent':
        statusColor = AppTheme.errorColor;
        break;
      case 'Upcoming':
        statusColor = AppTheme.warningColor;
        break;
      default:
        statusColor = AppTheme.infoColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              payment['name'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(payment['amount']),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateFormat.format(payment['dueDate']),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payment['status'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
