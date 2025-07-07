import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../viewmodels/income_viewmodel.dart';
import '../../models/income_source_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../services/navigation_service.dart';
import 'income_form_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  int _selectedIndex = 7; // Income tab selected
  bool _isLoading = false;
  final String _selectedFilter = 'All';
  final ValueNotifier<DateTime> _selectedMonthNotifier = ValueNotifier(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadIncomeSources();
  }

  @override
  void dispose() {
    _selectedMonthNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadIncomeSources() async {
    setState(() => _isLoading = true);

    try {
      final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
      await incomeViewModel.loadIncomeSources();
    } catch (e) {
      if (e.toString().contains('index')) {
        // Handle index creation error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Index creation in progress...'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          // Try again after a short delay
          Future.delayed(const Duration(seconds: 5), _loadIncomeSources);
        }
      } else {
        // Handle other errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading income sources: $e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final String route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
      ),
      body: Consumer<IncomeViewModel>(
        builder: (context, viewModel, child) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Select Month:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: _selectedMonthNotifier,
                      builder: (context, selectedMonth, child) {
                        return DropdownButton<DateTime>(
                          value: selectedMonth,
                          items: _buildMonthDropdownItems(),
                          onChanged: (DateTime? newValue) {
                            if (newValue != null) {
                              _selectedMonthNotifier.value = newValue;
                              _loadIncomeSources();
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildContent(viewModel),
              ),
            ],
          );
        },
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IncomeFormScreen(),
            ),
          );
          if (result == true) {
            _loadIncomeSources();
          }
        },
        backgroundColor: AppTheme.incomeColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Income Source',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<DropdownMenuItem<DateTime>> _buildMonthDropdownItems() {
    final List<DropdownMenuItem<DateTime>> items = [];
    
    // Generate items for the last 12 months including current month
    DateTime currentDate = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(currentDate.year, currentDate.month - i, 1);
      items.add(
        DropdownMenuItem(
          value: month,
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    return items;
  }

  Widget _buildContent(IncomeViewModel viewModel) {
    List<IncomeSource> filteredSources;
    
    if (_selectedFilter == 'All') {
      filteredSources = viewModel.incomeSources;
    } else if (_selectedFilter == 'Recurring') {
      filteredSources = viewModel.getRecurringIncome();
    } else {
      filteredSources = viewModel.getIncomeByType(_selectedFilter);
    }
    
    if (filteredSources.isEmpty) {
      return _buildEmptyState();
    }
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIncomeSummary(viewModel),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFilter == 'All' 
                      ? 'All Income Sources' 
                      : _selectedFilter == 'Recurring'
                          ? 'Recurring Income'
                          : '$_selectedFilter Income',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${filteredSources.length} ${filteredSources.length == 1 ? 'source' : 'sources'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...filteredSources.map((source) => _buildIncomeSourceCard(source)),
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
            Icons.account_balance_wallet,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All' 
                ? 'No income sources added yet' 
                : _selectedFilter == 'Recurring'
                    ? 'No recurring income sources'
                    : 'No $_selectedFilter income sources',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your income by adding your income sources',
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
                  builder: (context) => const IncomeFormScreen(),
                ),
              );
              
              if (result == true) {
                // Refresh the list if an income source was added
                _loadIncomeSources();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Income Source'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.incomeColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSummary(IncomeViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final totalIncome = viewModel.getTotalIncome();
    final recurringIncome = viewModel.getRecurringIncome()
        .fold(0.0, (sum, source) => sum + source.amount);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Income Summary',
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
                  'Total Income',
                  currencyFormat.format(totalIncome),
                  AppTheme.incomeColor,
                ),
                _buildSummaryItem(
                  'Recurring Income',
                  currencyFormat.format(recurringIncome),
                  AppTheme.primaryColor,
                ),
                _buildSummaryItem(
                  'One-time Income',
                  currencyFormat.format(totalIncome - recurringIncome),
                  AppTheme.accentColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Income Distribution',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildIncomeDistribution(viewModel),
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

  Widget _buildIncomeDistribution(IncomeViewModel viewModel) {
    final distribution = viewModel.getIncomeDistribution();
    final totalIncome = viewModel.getTotalIncome();
    
    if (distribution.isEmpty || totalIncome == 0) {
      return const Text(
        'No income data to display',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Column(
      children: distribution.entries.map((entry) {
        final percentage = (entry.value / totalIncome) * 100;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: entry.value / totalIncome,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_getIncomeTypeColor(entry.key)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncomeSourceCard(IncomeSource source) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat(AppConstants.dateFormat);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncomeFormScreen(incomeSource: source),
            ),
          );
          
          if (result == true || result == 'deleted') {
            // Refresh the list if an income source was updated or deleted
            _loadIncomeSources();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIncomeTypeIcon(source.type),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          source.type,
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
                        currencyFormat.format(source.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.incomeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(source.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (source.isRecurring)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recurring (${source.frequency})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              if (source.notes != null && source.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    source.notes!,
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
      ),
    );
  }

  Widget _buildIncomeTypeIcon(String type) {
    IconData iconData;
    
    switch (type) {
      case 'Salary':
        iconData = FontAwesomeIcons.briefcase;
        break;
      case 'Side Hustle':
        iconData = FontAwesomeIcons.laptop;
        break;
      case 'Loan':
        iconData = FontAwesomeIcons.handHoldingDollar;
        break;
      case 'Grant':
        iconData = FontAwesomeIcons.award;
        break;
      case 'Family Contribution':
        iconData = FontAwesomeIcons.users;
        break;
      case 'Business':
        iconData = FontAwesomeIcons.store;
        break;
      case 'Dividend':
        iconData = FontAwesomeIcons.chartLine;
        break;
      case 'Investment':
        iconData = FontAwesomeIcons.moneyBillTrendUp;
        break;
      case 'Gift':
        iconData = FontAwesomeIcons.gift;
        break;
      default:
        iconData = FontAwesomeIcons.moneyBill;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getIncomeTypeColor(type).withValues(alpha:0.1),
        shape: BoxShape.circle,
      ),
      child: FaIcon(
        iconData,
        color: _getIncomeTypeColor(type),
        size: 24,
      ),
    );
  }

  Color _getIncomeTypeColor(String type) {
    switch (type) {
      case 'Salary':
        return Colors.blue;
      case 'Side Hustle':
        return Colors.purple;
      case 'Loan':
        return Colors.orange;
      case 'Grant':
        return Colors.teal;
      case 'Family Contribution':
        return Colors.pink;
      case 'Business':
        return Colors.indigo;
      case 'Dividend':
        return Colors.green;
      case 'Investment':
        return Colors.amber.shade700;
      case 'Gift':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
