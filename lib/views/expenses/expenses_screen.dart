import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../viewmodels/transaction_viewmodel.dart';
import '../../models/transaction_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../views/transactions/transaction_form_screen.dart';
import 'widgets/expense_list_item.dart';
import 'widgets/expense_filter.dart';
import 'widgets/add_expense_button.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Expenses tab selected
  String _selectedFilter = 'All';
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    // Load transactions for the current month
    await transactionViewModel.loadTransactionsByMonth(transactionViewModel.selectedMonth);
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation would be handled here
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _previousMonth() {
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final newMonth = DateTime(
      transactionViewModel.selectedMonth.year, 
      transactionViewModel.selectedMonth.month - 1
    );
    transactionViewModel.setSelectedMonth(newMonth);
  }

  void _nextMonth() {
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final newMonth = DateTime(
      transactionViewModel.selectedMonth.year, 
      transactionViewModel.selectedMonth.month + 1
    );
    transactionViewModel.setSelectedMonth(newMonth);
  }

  Future<void> _processMonthlyCarryForward() async {
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    
    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Carry Forward Expenses'),
        content: const Text(
          'This will carry forward all unpaid expenses from this month to the next month. '
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldProceed) {
      final result = await transactionViewModel.processMonthlyCarryForward();
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expenses successfully carried forward to next month'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Move to the next month to see the carried forward expenses
        _nextMonth();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to carry forward expenses'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recordPayment(Transaction transaction) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _PaymentDialog(transaction: transaction),
    );
    
    if (result != null && result > 0) {
      final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
      final success = await transactionViewModel.recordPayment(transaction, result);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionViewModel = Provider.of<TransactionViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unpaid'),
            Tab(text: 'Carried Forward'),
          ],
        ),
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildSummaryCard(),
          ExpenseFilter(
            selectedFilter: _selectedFilter,
            onFilterChanged: _onFilterChanged,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesList(transactionViewModel, 'All'),
                _buildExpensesList(transactionViewModel, 'Unpaid'),
                _buildExpensesList(transactionViewModel, 'CarriedForward'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_tabController.index == 1) // Only show on Unpaid tab
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                heroTag: 'carry_forward',
                onPressed: _processMonthlyCarryForward,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Carry Forward'),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          FloatingActionButton.extended(
            heroTag: 'add_expense',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionFormScreen(isExpense: true),
                ),
              );
              
              if (result == true) {
                // Refresh the list if a transaction was added
                _loadTransactions();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final transactionViewModel = Provider.of<TransactionViewModel>(context);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            Text(
              transactionViewModel.getMonthYearString(transactionViewModel.selectedMonth),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final transactionViewModel = Provider.of<TransactionViewModel>(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final totalExpenses = transactionViewModel.getTotalExpenses();
    final totalUnpaid = transactionViewModel.getTotalUnpaid();
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(totalExpenses),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.expenseColor,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to reports or analytics
                  },
                  child: const Text('View Analytics'),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unpaid Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(totalUnpaid),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'These expenses can be carried forward',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(TransactionViewModel viewModel, String filter) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Filter transactions based on tab
    List<Transaction> expenses;
    
    if (filter == 'All') {
      expenses = viewModel.transactions
          .where((transaction) => transaction.amount < 0)
          .toList();
    } else if (filter == 'Unpaid') {
      expenses = viewModel.transactions
          .where((transaction) => 
            transaction.amount < 0 && 
            transaction.status != 'Paid')
          .toList();
    } else if (filter == 'CarriedForward') {
      expenses = viewModel.transactions
          .where((transaction) => 
            transaction.amount < 0 && 
            transaction.isCarriedForward)
          .toList();
    } else {
      expenses = viewModel.transactions
          .where((transaction) => 
            transaction.amount < 0 && 
            transaction.category == _selectedFilter)
          .toList();
    }
    
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              filter == 'All' 
                ? 'No expenses found'
                : filter == 'Unpaid'
                  ? 'No unpaid expenses'
                  : 'No carried forward expenses',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'All'
                ? 'Add your first expense by tapping the + button'
                : filter == 'Unpaid'
                  ? 'All your expenses are paid'
                  : 'No expenses have been carried forward yet',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildExpenseItem(expense);
      },
    );
  }

  Widget _buildExpenseItem(Transaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(transaction.category),
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (transaction.isCarriedForward)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Tooltip(
                  message: 'Carried forward from previous month',
                  child: Icon(
                    Icons.history,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat(AppConstants.dateFormat).format(transaction.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.status,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (transaction.isPartiallyPaid) ...[
                  const SizedBox(width: 4),
                  Text(
                    'Paid: ${currencyFormat.format(transaction.paidAmount)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(transaction.amount.abs()),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.expenseColor,
              ),
            ),
            if (transaction.status != 'Paid')
              TextButton(
                onPressed: () => _recordPayment(transaction),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(60, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Record Payment',
                  style: TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
        onTap: () {
          // Show transaction details
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.green;
      case 'Transport':
        return Colors.blue;
      case 'Shopping':
        return Colors.purple;
      case 'Bills':
        return Colors.orange;
      case 'Entertainment':
        return Colors.pink;
      case 'Health':
        return Colors.red;
      case 'Housing':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt;
      case 'Entertainment':
        return Icons.movie;
      case 'Health':
        return Icons.medical_services;
      case 'Housing':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterBottomSheet() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Expenses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Show date picker
                      },
                      child: const Text('Start Date'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Show date picker
                      },
                      child: const Text('End Date'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.expenseCategories.map((category) {
                  return FilterChip(
                    label: Text(category),
                    selected: _selectedFilter == category,
                    onSelected: (selected) {
                      _onFilterChanged(selected ? category : 'All');
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Apply filters
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final Transaction transaction;

  const _PaymentDialog({required this.transaction});

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _fullPayment = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.transaction.remainingAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.transaction.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ${currencyFormat.format(widget.transaction.amount)}',
            ),
            if (widget.transaction.paidAmount != null && widget.transaction.paidAmount! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Already Paid: ${currencyFormat.format(widget.transaction.paidAmount)}',
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Remaining: ${currencyFormat.format(widget.transaction.remainingAmount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Pay full remaining amount'),
              value: _fullPayment,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  _fullPayment = value ?? false;
                  if (_fullPayment) {
                    _amountController.text = widget.transaction.remainingAmount.toString();
                  }
                });
              },
            ),
            if (!_fullPayment)
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  hintText: 'Enter amount',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  if (amount > widget.transaction.remainingAmount) {
                    return 'Amount cannot exceed remaining balance';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text);
              Navigator.pop(context, amount);
            }
          },
          child: const Text('Record Payment'),
        ),
      ],
    );
  }
}
