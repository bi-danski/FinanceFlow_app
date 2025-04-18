import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import 'transaction_form_screen.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction.amount < 0;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat(AppConstants.dateFormat);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionFormScreen(
                    transaction: widget.transaction,
                    isExpense: isExpense,
                  ),
                ),
              );
              if (!context.mounted) return;
              if (result == true) {
                // Refresh and return to previous screen
                Navigator.pop(context, true);
              } else if (result == 'deleted') {
                // Handle deletion
                Navigator.pop(context, 'deleted');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isExpense),
            const SizedBox(height: 24),
            _buildDetailsCard(context, isExpense, currencyFormat, dateFormat),
            if (widget.transaction.description != null && widget.transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDescriptionCard(context),
            ],
            const SizedBox(height: 16),
            _buildActionsCard(context, isExpense),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isExpense) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isExpense 
                  ? AppTheme.expenseColor.withAlpha((0.1 * 255).toInt())
                  : AppTheme.incomeColor.withAlpha((0.1 * 255).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline,
              size: 48,
              color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.transaction.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(widget.transaction.amount.abs()),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getCategoryColor(widget.transaction.category).withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.transaction.category,
              style: TextStyle(
                color: _getCategoryColor(widget.transaction.category),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context, 
    bool isExpense, 
    NumberFormat currencyFormat, 
    DateFormat dateFormat
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Transaction Type',
              isExpense ? 'Expense' : 'Income',
              isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Amount',
              currencyFormat.format(widget.transaction.amount.abs()),
              null,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Date',
              dateFormat.format(widget.transaction.date),
              null,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Category',
              widget.transaction.category,
              _getCategoryColor(widget.transaction.category),
            ),
            if (widget.transaction.paymentMethod != null) ...[
              const Divider(),
              _buildDetailRow(
                context,
                'Payment Method',
                widget.transaction.paymentMethod!,
                null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    Color? valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.transaction.description!,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, bool isExpense) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  context,
                  'Edit',
                  Icons.edit,
                  AppTheme.primaryColor,
                  () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionFormScreen(
                          transaction: widget.transaction,
                          isExpense: isExpense,
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    if (result == true) {
                      // Refresh and return to previous screen
                      Navigator.pop(context, true);
                    } else if (result == 'deleted') {
                      // Handle deletion
                      Navigator.pop(context, 'deleted');
                    }
                  },
                ),
                _buildActionButton(
                  context,
                  'Delete',
                  Icons.delete,
                  AppTheme.errorColor,
                  () {
                    _showDeleteConfirmationDialog(context);
                  },
                ),
                _buildActionButton(
                  context,
                  'Duplicate',
                  Icons.content_copy,
                  Colors.grey,
                  () {
                    // Duplicate transaction logic
                    _duplicateTransaction(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.',
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
                // Handle delete transaction
                _deleteTransaction(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTransaction(BuildContext context) {
    // In a real app, you would call the viewmodel to delete the transaction
    // For now, we'll just simulate it
    if (!context.mounted) return;
    Navigator.pop(context); // Close dialog
    Navigator.pop(context, 'deleted'); // Return to previous screen with result
  }

  void _duplicateTransaction(BuildContext context) {
    // Create a new transaction with the same details but a new date
    final duplicatedTransaction = Transaction(
      title: widget.transaction.title,
      amount: widget.transaction.amount,
      date: DateTime.now(), // Use current date for the duplicate
      category: widget.transaction.category,
      description: widget.transaction.description,
      paymentMethod: widget.transaction.paymentMethod,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          transaction: duplicatedTransaction,
          isExpense: widget.transaction.amount < 0,
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
