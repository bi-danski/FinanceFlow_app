import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/transaction_viewmodel.dart';
import '../../models/transaction_model.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../services/navigation_service.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction; // Null for new transaction, non-null for edit
  final bool isExpense; // Default to expense form

  const TransactionFormScreen({
    Key? key,
    this.transaction,
    this.isExpense = true,
  }) : super(key: key);

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = '';
  String _selectedPaymentMethod = AppConstants.paymentMethods.first;
  bool _isExpense = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.isExpense;
    
    // Set initial category based on transaction type
    _selectedCategory = _isExpense 
        ? AppConstants.expenseCategories.first 
        : AppConstants.incomeCategories.first;
    
    // If editing an existing transaction, populate the form
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.abs().toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _selectedDate = widget.transaction!.date;
      _selectedCategory = widget.transaction!.category;
      _selectedPaymentMethod = widget.transaction!.paymentMethod ?? AppConstants.paymentMethods.first;
      _isExpense = widget.transaction!.amount < 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleTransactionType() {
    setState(() {
      _isExpense = !_isExpense;
      // Reset category when switching transaction type
      _selectedCategory = _isExpense 
          ? AppConstants.expenseCategories.first 
          : AppConstants.incomeCategories.first;
    });
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
        
        // Parse amount and apply sign based on transaction type
        double amount = double.parse(_amountController.text);
        if (_isExpense) {
          amount = -amount; // Make negative for expenses
        }
        
        final transaction = Transaction(
          id: widget.transaction?.id, // Will be null for new transactions
          title: _titleController.text,
          amount: amount,
          date: _selectedDate,
          category: _selectedCategory,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          paymentMethod: _selectedPaymentMethod,
        );
        
        final success = await transactionViewModel.addTransaction(transaction);
        
        if (success) {
          if (mounted) {
            Navigator.pop(context, true); // Return success
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save transaction')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    final title = isEditing 
        ? 'Edit ${_isExpense ? 'Expense' : 'Income'}'
        : 'Add ${_isExpense ? 'Expense' : 'Income'}';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Handle delete transaction
                _showDeleteConfirmationDialog();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditing) _buildTransactionTypeToggle(),
                    const SizedBox(height: 16),
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildDatePicker(),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildPaymentMethodDropdown(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTransactionTypeToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Text(
              'Transaction Type:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ToggleButtons(
              isSelected: [_isExpense, !_isExpense],
              onPressed: (index) {
                setState(() {
                  _isExpense = index == 0;
                  // Reset category when switching transaction type
                  _selectedCategory = _isExpense 
                      ? AppConstants.expenseCategories.first 
                      : AppConstants.incomeCategories.first;
                });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: _isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Expense'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Income'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'E.g., Grocery Shopping',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: 'E.g., 50.00',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.attach_money),
        prefixText: '\$ ',
        suffixText: _isExpense ? 'Expense' : 'Income',
        suffixStyle: TextStyle(
          color: _isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        try {
          final amount = double.parse(value);
          if (amount <= 0) {
            return 'Amount must be greater than zero';
          }
        } catch (e) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat(AppConstants.dateFormat).format(_selectedDate),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _isExpense 
        ? AppConstants.expenseCategories 
        : AppConstants.incomeCategories;
    
    return DropdownButtonFormField<String>(
      value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: const InputDecoration(
        labelText: 'Payment Method',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payment),
      ),
      items: AppConstants.paymentMethods.map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPaymentMethod = value!;
        });
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Add notes about this transaction',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
          foregroundColor: Colors.white,
        ),
        child: Text(
          widget.transaction != null ? 'Update' : 'Save',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
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
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, 'deleted'); // Return to previous screen with result
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
}
