import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

import '../../services/mpesa_sms_service.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/error_widget.dart' as app_error;

class MpesaImportScreen extends StatefulWidget {
  const MpesaImportScreen({super.key});

  @override
  State<MpesaImportScreen> createState() => _MpesaImportScreenState();
}

class _MpesaImportScreenState extends State<MpesaImportScreen> {
  final Logger _logger = Logger('MpesaImportScreen');
  final MpesaSmsService _mpesaService = MpesaSmsService.instance;
  
  bool _isLoading = false;
  bool _permissionGranted = false;
  bool _hasCheckedPermission = false;
  List<Transaction> _previewTransactions = [];
  List<Transaction> _importedTransactions = [];
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _checkPermission();
  }
  
  Future<void> _checkPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final hasPermission = await _mpesaService.requestSmsPermission();
      
      setState(() {
        _permissionGranted = hasPermission;
        _hasCheckedPermission = true;
        _isLoading = false;
      });
      
      if (hasPermission) {
        _loadPreviewTransactions();
      }
    } catch (e) {
      _logger.severe('Error checking permission: $e');
      setState(() {
        _errorMessage = 'Could not check SMS permission: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadPreviewTransactions() async {
    if (!_permissionGranted) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final transactions = await _mpesaService.previewMpesaTransactions();
      
      setState(() {
        _previewTransactions = transactions;
        _isLoading = false;
      });
      
      _logger.info('Loaded ${transactions.length} preview transactions');
    } catch (e) {
      _logger.severe('Error loading preview transactions: $e');
      setState(() {
        _errorMessage = 'Could not load M-Pesa transactions: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _importTransactions() async {
    if (!_permissionGranted || _previewTransactions.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final transactions = await _mpesaService.importAllMpesaTransactions();
      
      setState(() {
        _importedTransactions = transactions;
        _isLoading = false;
      });
      
      // Refresh transaction viewmodel
      if (mounted) {
        final viewModel = Provider.of<TransactionViewModel>(context, listen: false);
        viewModel.loadTransactionsByMonth(DateTime.now());
      }
      
      _logger.info('Imported ${transactions.length} transactions');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${transactions.length} transactions'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error importing transactions: $e');
      setState(() {
        _errorMessage = 'Error importing transactions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import M-Pesa Transactions'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    if (!_hasCheckedPermission || !_permissionGranted) {
      return _buildPermissionRequest();
    }
    
    if (_importedTransactions.isNotEmpty) {
      return _buildImportedTransactionsView();
    }
    
    return _buildTransactionPreview();
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator().animate().scale(),
          const SizedBox(height: 16),
          const Text('Processing M-Pesa transactions...')
              .animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return app_error.ErrorWidget(
      errorMessage: _errorMessage,
      onRetry: _checkPermission,
    );
  }
  
  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message,
              size: 80,
              color: Theme.of(context).primaryColor,
            ).animate().scale(),
            const SizedBox(height: 24),
            Text(
              'SMS Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            Text(
              'To import your M-Pesa transactions, we need permission to read your SMS messages. '
              'We will only read messages from M-Pesa.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            AnimatedButton(
              onPressed: _checkPermission,
              text: 'Grant Permission',
              color: Theme.of(context).primaryColor,
              icon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionPreview() {
    if (_previewTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'No M-Pesa SMS Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'We couldn\'t find any M-Pesa transaction messages in your SMS inbox.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              AnimatedButton(
                onPressed: _loadPreviewTransactions,
                text: 'Refresh',
                color: Theme.of(context).primaryColor,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found ${_previewTransactions.length} M-Pesa Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'These transactions will be imported into your FinanceFlow app. '
                'Review them below before importing.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AnimatedButton(
                onPressed: _importTransactions,
                text: 'Import All Transactions',
                color: Theme.of(context).primaryColor,
                icon: Icons.download,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _previewTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _previewTransactions[index];
              return AnimatedListItem(
                index: index,
                child: _buildTransactionItem(transaction),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildImportedTransactionsView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Import Complete!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Successfully imported ${_importedTransactions.length} transactions from M-Pesa.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AnimatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                text: 'Return to Dashboard',
                color: Theme.of(context).primaryColor,
                icon: Icons.home,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _importedTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _importedTransactions[index];
              return AnimatedListItem(
                index: index,
                child: _buildTransactionItem(transaction),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionItem(Transaction transaction) {
    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'KES ${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: transaction.isExpense ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.category,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${dateFormatter.format(transaction.date)} ${timeFormatter.format(transaction.date)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (transaction.notes != null && transaction.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  transaction.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
