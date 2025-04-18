import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../viewmodels/loan_viewmodel.dart';
import '../../models/loan_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import 'loan_form_screen.dart';
import 'loan_payment_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  int _selectedIndex = 8; // Loans tab selected
  bool _isLoading = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loanViewModel = Provider.of<LoanViewModel>(context, listen: false);
      await loanViewModel.loadLoans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading loans: $e')),
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

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation would be handled here
  }

  @override
  Widget build(BuildContext context) {
    final loanViewModel = Provider.of<LoanViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Management'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Text('All Loans'),
              ),
              ...AppConstants.loanStatusOptions.map((status) => 
                PopupMenuItem(
                  value: status,
                  child: Text('$status Loans'),
                )
              ),
              const PopupMenuItem(
                value: 'Overdue',
                child: Text('Overdue Loans'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLoans,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(loanViewModel),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoanFormScreen(),
            ),
          );
          
          if (result == true) {
            // Refresh the list if a loan was added
            _loadLoans();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(LoanViewModel viewModel) {
    List<Loan> filteredLoans;
    
    if (_selectedFilter == 'All') {
      filteredLoans = viewModel.loans;
    } else if (_selectedFilter == 'Overdue') {
      filteredLoans = viewModel.getOverdueLoans();
    } else {
      filteredLoans = viewModel.getLoansByStatus(_selectedFilter);
    }
    
    if (filteredLoans.isEmpty) {
      return _buildEmptyState();
    }
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoanSummary(viewModel),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFilter == 'All' 
                      ? 'All Loans' 
                      : '$_selectedFilter Loans',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${filteredLoans.length} ${filteredLoans.length == 1 ? 'loan' : 'loans'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...filteredLoans.map((loan) => _buildLoanCard(loan)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.handHoldingDollar,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All' 
                ? 'No loans added yet' 
                : 'No $_selectedFilter loans',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your loans by adding them here',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoanFormScreen(),
                ),
              );
              
              if (result == true) {
                // Refresh the list if a loan was added
                _loadLoans();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanSummary(LoanViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final totalLoanAmount = viewModel.getTotalLoanAmount();
    final totalRemainingAmount = viewModel.getTotalRemainingAmount();
    final totalAmountPaid = viewModel.getTotalAmountPaid();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loan Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Loan Amount',
                  currencyFormat.format(totalLoanAmount),
                  AppTheme.primaryColor,
                ),
                _buildSummaryItem(
                  'Amount Paid',
                  currencyFormat.format(totalAmountPaid),
                  AppTheme.incomeColor,
                ),
                _buildSummaryItem(
                  'Remaining',
                  currencyFormat.format(totalRemainingAmount),
                  totalRemainingAmount > 0 ? AppTheme.expenseColor : AppTheme.successColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Overall Payment Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalLoanAmount > 0 ? totalAmountPaid / totalLoanAmount : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                totalLoanAmount > 0 
                    ? '${((totalAmountPaid / totalLoanAmount) * 100).toStringAsFixed(1)}% paid' 
                    : '0% paid',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusCount(
                  'Active Loans',
                  viewModel.getLoansByStatus('Active').length.toString(),
                  Colors.blue,
                ),
                _buildStatusCount(
                  'Paid Loans',
                  viewModel.getLoansByStatus('Paid').length.toString(),
                  AppTheme.successColor,
                ),
                _buildStatusCount(
                  'Overdue Loans',
                  viewModel.getOverdueLoans().length.toString(),
                  AppTheme.errorColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCount(String title, String count, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withAlpha((0.2 * 255).toInt()),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanCard(Loan loan) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat(AppConstants.dateFormat);
    
    Color statusColor;
    switch (loan.status) {
      case 'Active':
        statusColor = loan.isOverdue ? AppTheme.errorColor : Colors.blue;
        break;
      case 'Paid':
        statusColor = AppTheme.successColor;
        break;
      case 'Defaulted':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoanFormScreen(loan: loan),
            ),
          );
          
          if (result == true || result == 'deleted') {
            // Refresh the list if a loan was updated or deleted
            _loadLoans();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: statusColor.withAlpha((0.1 * 255).toInt()),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha((0.2 * 255).toInt()),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          loan.isOverdue ? Icons.warning : Icons.check_circle,
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loan.isOverdue ? 'Overdue' : loan.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (loan.status == 'Active')
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoanPaymentScreen(loan: loan),
                          ),
                        );
                        
                        if (result == true) {
                          // Refresh the list if a payment was made
                          _loadLoans();
                        }
                      },
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Make Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lender: ${loan.lender}',
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
                            currencyFormat.format(loan.totalAmount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Interest: ${loan.interestRate}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid: ${currencyFormat.format(loan.amountPaid)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Remaining: ${currencyFormat.format(loan.remainingAmount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: loan.remainingAmount > 0 ? AppTheme.expenseColor : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                                  'Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${loan.percentPaid.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getProgressColor(loan.percentPaid),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: loan.amountPaid / loan.totalAmount,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(loan.percentPaid)),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            dateFormat.format(loan.startDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            dateFormat.format(loan.dueDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: loan.isOverdue ? AppTheme.errorColor : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Payment: ${currencyFormat.format(loan.installmentAmount)} (${loan.paymentFrequency})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (loan.notes != null && loan.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        loan.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 30) {
      return AppTheme.errorColor;
    } else if (percentage < 70) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.successColor;
    }
  }
}
