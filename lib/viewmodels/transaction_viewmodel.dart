import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/realtime_data_service.dart';
import '../constants/app_constants.dart';

class TransactionViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final RealtimeDataService _realtimeDataService = RealtimeDataService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();
  bool _useFirestore = false; // Flag to determine if we should use Firestore or SQLite
  StreamSubscription<List<Transaction>>? _transactionSubscription;
  final Logger logger = Logger('TransactionViewModel');

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  bool get useFirestore => _useFirestore;
  
  TransactionViewModel() {
    // Check if user is authenticated to determine data source
    _checkDataSource();
  }
  
  /// Check if we should use Firestore or SQLite
  void _checkDataSource() {
    final user = _auth.currentUser;
    _useFirestore = user != null;
    logger.info('Using Firestore: $_useFirestore');
    
    if (_useFirestore) {
      // Subscribe to real-time updates if using Firestore
      _subscribeToTransactions();
    } else {
      // Load from SQLite if not using Firestore
      loadTransactionsByMonth(_selectedMonth);
    }
  }

  /// Subscribe to real-time transaction updates from Firestore
  void _subscribeToTransactions() {
    logger.info('Subscribing to transaction updates');
    
    // Cancel any existing subscription
    _transactionSubscription?.cancel();
    
    // Start the transactions stream if not already started
    _realtimeDataService.startTransactionsStream();
    
    // Subscribe to the stream
    _transactionSubscription = _realtimeDataService.transactionsStream.listen(
      (transactions) {
        // Filter transactions by the selected month
        final filteredTransactions = transactions.where((transaction) {
          final transactionDate = transaction.date;
          return transactionDate.year == _selectedMonth.year && 
                 transactionDate.month == _selectedMonth.month;
        }).toList();
        
        _transactions = filteredTransactions;
        _isLoading = false;
        logger.info('Received ${_transactions.length} transactions for ${getMonthYearString(_selectedMonth)}');
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error in transaction stream: $error');
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    if (_useFirestore) {
      // For Firestore, we just need to update the filter criteria
      // The stream listener will handle updating the transactions
      logger.info('Updating selected month to ${getMonthYearString(month)}');
      notifyListeners();
    } else {
      // For SQLite, load from the database
      loadTransactionsByMonth(month);
    }
  }

  Future<void> loadTransactions() async {
    if (_useFirestore) {
      // For Firestore, we're already subscribed to real-time updates
      // Just update the loading state
      _isLoading = true;
      notifyListeners();
      
      // The stream listener will handle updating transactions
      // Just set a timeout to ensure we don't stay in loading state indefinitely
      Future.delayed(const Duration(seconds: 2), () {
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
      });
    } else {
      // For SQLite, load from the database
      _isLoading = true;
      notifyListeners();

      try {
        _transactions = await _databaseService.getTransactions();
      } catch (e) {
        logger.info('Error loading transactions: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadRecentTransactions(int limit) async {
    if (_useFirestore) {
      // For Firestore, we're already subscribed to real-time updates
      // Just update the loading state and filter the most recent transactions
      _isLoading = true;
      notifyListeners();
      
      // The stream will handle updating transactions, but we'll limit them
      // in the UI when displaying
      Future.delayed(const Duration(seconds: 2), () {
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
      });
    } else {
      // For SQLite, load from the database
      _isLoading = true;
      notifyListeners();

      try {
        _transactions = await _databaseService.getRecentTransactions(limit: limit);
      } catch (e) {
        logger.info('Error loading recent transactions: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadTransactionsByMonth(DateTime month) async {
    if (_useFirestore) {
      // For Firestore, we're already subscribed to real-time updates
      // The listener will filter by the selected month
      _isLoading = true;
      notifyListeners();
      
      // Just set a timeout to ensure we don't stay in loading state indefinitely
      Future.delayed(const Duration(seconds: 2), () {
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
      });
    } else {
      // For SQLite, load from the database
      _isLoading = true;
      notifyListeners();

      try {
        _transactions = await _databaseService.getTransactionsByMonth(month.year, month.month);
      } catch (e) {
        logger.info('Error loading transactions by month: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addTransaction(Transaction transaction) async {
    try {
      if (_useFirestore) {
        // For Firestore, save to cloud
        await _firestoreService.saveTransaction(transaction);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, save to local database
        await _databaseService.insertTransaction(transaction);
        await loadTransactionsByMonth(_selectedMonth);
      }
      return true;
    } catch (e) {
      logger.info('Error adding transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      if (_useFirestore) {
        // For Firestore, update in cloud
        await _firestoreService.saveTransaction(transaction);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, update in local database
        await _databaseService.updateTransaction(transaction);
        await loadTransactionsByMonth(_selectedMonth);
      }
      return true;
    } catch (e) {
      logger.warning('Error updating transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      if (_useFirestore) {
        // For Firestore, delete from cloud
        await _firestoreService.deleteTransaction(id.toString());
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, delete from local database
        await _databaseService.deleteTransaction(id);
        await loadTransactionsByMonth(_selectedMonth);
      }
      return true;
    } catch (e) {
      logger.warning('Error deleting transaction: $e');
      return false;
    }
  }

  Future<bool> recordPayment(Transaction transaction, double amount) async {
    try {
      // Calculate new status and paid amount
      double newPaidAmount = (transaction.paidAmount ?? 0) + amount;
      String newStatus;
      
      if (newPaidAmount >= transaction.amount) {
        newStatus = 'Paid';
        newPaidAmount = transaction.amount; // Cap at the total amount
      } else if (newPaidAmount > 0) {
        newStatus = 'Partial';
      } else {
        newStatus = 'Unpaid';
      }
      
      // Update the transaction
      final updatedTransaction = transaction.copyWith(
        status: newStatus,
        paidAmount: newPaidAmount,
      );
      
      await _databaseService.updateTransaction(updatedTransaction);
      await loadTransactionsByMonth(_selectedMonth);
      return true;
    } catch (e) {
      logger.info('Error recording payment: $e');
      return false;
    }
  }

  Future<bool> processMonthlyCarryForward() async {
    try {
      // Process the carry forward
      await _databaseService.processMonthlyCarryForward();
      
      // Reload transactions for the current month
      await loadTransactionsByMonth(_selectedMonth);
      return true;
    } catch (e) {
      logger.info('Error processing monthly carry forward: $e');
      return false;
    }
  }

  List<Transaction> getUnpaidTransactions() {
    return _transactions.where((t) => t.status != 'Paid').toList();
  }

  List<Transaction> getCarriedForwardTransactions() {
    return _transactions.where((t) => t.isCarriedForward).toList();
  }

  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  List<Transaction> getTransactionsByStatus(String status) {
    return _transactions.where((t) => t.status == status).toList();
  }

  double getTotalIncome() {
    return _transactions
        .where((transaction) => transaction.amount > 0)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  double getTotalExpenses() {
    return _transactions
        .where((transaction) => transaction.amount < 0)
        .fold(0, (sum, transaction) => sum + transaction.amount.abs());
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }

  double getTotalUnpaid() {
    return _transactions
        .where((t) => t.status != 'Paid')
        .fold(0, (sum, t) => sum + t.remainingAmount);
  }

  Map<String, double> getCategoryTotals() {
    Map<String, double> categoryTotals = {};
    
    for (var transaction in _transactions) {
      if (transaction.amount < 0) { // Only count expenses
        if (categoryTotals.containsKey(transaction.category)) {
          categoryTotals[transaction.category] = 
              categoryTotals[transaction.category]! + transaction.amount.abs();
        } else {
          categoryTotals[transaction.category] = transaction.amount.abs();
        }
      }
    }
    
    return categoryTotals;
  }

  String getMonthYearString(DateTime date) {
    return DateFormat(AppConstants.monthYearFormat).format(date);
  }

  // Get transactions that should be carried forward to the next month
  List<Transaction> getTransactionsForCarryForward() {
    return _transactions.where((t) => 
      t.status != 'Paid' && 
      AppConstants.carryForwardCategories.contains(t.category)
    ).toList();
  }

  // Get transactions that should be reset for the next month
  List<Transaction> getTransactionsForReset() {
    return _transactions.where((t) => 
      AppConstants.resetCategories.contains(t.category)
    ).toList();
  }
  
  @override
  void dispose() {
    // Cancel the transaction subscription to prevent memory leaks
    _transactionSubscription?.cancel();
    logger.info('Disposing TransactionViewModel');
    super.dispose();
  }
}
