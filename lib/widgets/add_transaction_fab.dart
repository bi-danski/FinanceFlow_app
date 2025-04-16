import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../views/transactions/transaction_form_screen.dart';

class AddTransactionFAB extends StatelessWidget {
  final Function? onTransactionAdded;

  const AddTransactionFAB({
    Key? key,
    this.onTransactionAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _showAddTransactionOptions(context);
      },
      backgroundColor: AppTheme.accentColor,
      child: const Icon(Icons.add),
    );
  }

  void _showAddTransactionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Transaction',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.expenseColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: AppTheme.expenseColor,
                  ),
                ),
                title: const Text('Add Expense'),
                subtitle: const Text('Record money going out'),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionFormScreen(
                        isExpense: true,
                      ),
                    ),
                  );
                  
                  if (result == true && onTransactionAdded != null) {
                    onTransactionAdded!();
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.incomeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.incomeColor,
                  ),
                ),
                title: const Text('Add Income'),
                subtitle: const Text('Record money coming in'),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionFormScreen(
                        isExpense: false,
                      ),
                    ),
                  );
                  
                  if (result == true && onTransactionAdded != null) {
                    onTransactionAdded!();
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: Colors.grey,
                  ),
                ),
                title: const Text('Transfer'),
                subtitle: const Text('Move money between accounts'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to transfer screen (to be implemented)
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
