import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart' as app_models;
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class TransactionViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<app_models.Transaction> _transactions = [];
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();
  bool _useFirestore = true;
  StreamSubscription<List<app_models.Transaction>>? _transactionSubscription;
  final Logger logger = Logger('TransactionViewModel');

  List<app_models.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  bool get useFirestore => _useFirestore;
  
  TransactionViewModel() {
    logger.info('Initializing TransactionViewModel');
    
    // Initialize with mock data if the list is empty
    if (_transactions.isEmpty) {
      logger.info('No transactions found, initializing with mock data');
      _initializeMockData();
    }
    
    // Check if user is authenticated to determine data source
    _checkDataSource();
    
    // Set up auth state listener
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        logger.info('User signed in, switching to Firestore');
        _useFirestore = true;
        _setupFirestoreListener();
      } else {
        logger.info('User signed out, switching to local database');
        _useFirestore = false;
        _transactionSubscription?.cancel();
      }
      // Reload transactions when auth state changes
      loadTransactionsByMonth(_selectedMonth);
    });
    
    // Load transactions for the current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadTransactionsByMonth(_selectedMonth);
    });
  }
  
  void _setupFirestoreListener() {
    _transactionSubscription?.cancel();
    _transactionSubscription = _firestoreService.transactionsStream(month: _selectedMonth).listen(
      (transactions) {
        _transactions = transactions;
        // Mark loading complete when stream delivers data
        if (_isLoading) {
          _isLoading = false;
        }
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error in Firestore listener: $error');
        _useFirestore = false;
        // Ensure loading flag is cleared on error to avoid infinite spinner
        _isLoading = false;
        notifyListeners();
        loadTransactionsByMonth(_selectedMonth);
      },
    );
  }
  
  /// Initialize mock transaction data to ensure the app has data to work with
  /// This is important for development and testing purposes
  void _initializeMockData() {
    logger.info('Initializing mock transaction data');
    final now = DateTime.now();
    final userId = _auth.currentUser?.uid ?? 'mock_user';
    
    // Create a list of mock transactions for the current month
    _transactions = [
      app_models.Transaction(
        id: '1',
        title: 'Grocery Shopping',
        amount: 85.75,
        date: DateTime(now.year, now.month, now.day - 2),
        category: 'Food',
        type: app_models.TransactionType.expense,
        status: app_models.TransactionStatus.completed,
        userId: userId,
      ),
      app_models.Transaction(
        id: '2',
        title: 'Salary',
        amount: 2500.00,
        date: DateTime(now.year, now.month, 1),
        category: 'Salary',
        type: app_models.TransactionType.income,
        status: app_models.TransactionStatus.completed,
        userId: userId,
      ),
      app_models.Transaction(
        id: '3',
        title: 'Electricity Bill',
        amount: 120.50,
        date: DateTime(now.year, now.month, now.day - 5),
        category: 'Bills',
        type: app_models.TransactionType.expense,
        status: app_models.TransactionStatus.completed,
        userId: userId,
      ),
    ];
  }
  
  /// Check if we should use Firestore or SQLite
  void _checkDataSource() {
    final user = _auth.currentUser;
    _useFirestore = user != null;
    logger.info('Using ${_useFirestore ? 'Firestore' : 'SQLite'} as data source');
  }
  
  /// Load transactions for a specific month
  Future<void> loadTransactionsByMonth(DateTime month) async {
    logger.info('loadTransactionsByMonth called for month: ${month.toIso8601String()}');
    debugPrint('TransactionViewModel: loadTransactionsByMonth called for month: ${month.toIso8601String()}');
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    _isLoading = true;
    _selectedMonth = month;
    notifyListeners();
    
    try {
      logger.info('Loading transactions for ${DateFormat('MMMM yyyy').format(month)}');
      
      if (_useFirestore) {
        logger.info('Using Firestore as data source');
        try {
          final result = await _firestoreService
              .getTransactionsByMonth(month)
              .timeout(const Duration(seconds: 8));
          _transactions = result['transactions'] as List<app_models.Transaction>;
        } on TimeoutException catch (_) {
          logger.warning('Firestore getTransactionsByMonth timed out, switching to local DB');
          _useFirestore = false;
          _transactions = await _databaseService.getTransactionsByMonth(month);
        }
      } else {
        logger.info('Using local database as data source');
        try {
          _transactions = await _databaseService
              .getTransactionsByMonth(month)
              .timeout(const Duration(seconds: 8));
        } on TimeoutException catch (_) {
          logger.warning('Local DB getTransactionsByMonth timed out');
          _transactions = [];
        }
      }
      
      logger.info('Successfully loaded ${_transactions.length} transactions');
    } on TimeoutException {
      logger.warning('Firestore request timed out, falling back to local database');
      _useFirestore = false;
      _transactions = await _databaseService.getTransactionsByMonth(month);
    } catch (e) {
      logger.severe('Error loading transactions: $e');
      // Fallback to mock data if there's an error and we don't have any data
      if (_transactions.isEmpty) {
        logger.info('No transactions found, using mock data');
        _initializeMockData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Add a new transaction
  Future<void> addTransaction(app_models.Transaction transaction) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (_useFirestore) {
        await _firestoreService.addTransaction(transaction);
      } else {
        await _databaseService.insertTransaction(transaction);
        _transactions = await _databaseService.getTransactionsByMonth(_selectedMonth);
      }
      
      // Reload transactions to ensure we have the latest data
      await loadTransactionsByMonth(_selectedMonth);
    } catch (e) {
      logger.severe('Error adding transaction: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update an existing transaction
  Future<void> updateTransaction(app_models.Transaction transaction) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (_useFirestore) {
        await _firestoreService.updateTransaction(transaction);
      } else {
        await _databaseService.updateTransaction(transaction);
        _transactions = await _databaseService.getTransactionsByMonth(_selectedMonth);
      }
      
      // Reload transactions to ensure we have the latest data
      await loadTransactionsByMonth(_selectedMonth);
    } catch (e) {
      logger.severe('Error updating transaction: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (_useFirestore) {
        await _firestoreService.deleteTransaction(id);
      } else {
        await _databaseService.deleteTransaction(id);
        _transactions = await _databaseService.getTransactionsByMonth(_selectedMonth);
      }
      
      // Reload transactions to ensure we have the latest data
      await loadTransactionsByMonth(_selectedMonth);
    } catch (e) {
      logger.severe('Error deleting transaction: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get the total income for the selected month
  double getTotalIncome() {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  /// Get the total expenses for the selected month
  double getTotalExpenses() {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  /// Get the current balance (income - expenses)
  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }
  
  /// Get the total amount of unpaid transactions
  double getTotalUnpaid() {
    return _transactions
        .where((t) => t.status == app_models.TransactionStatus.pending || 
                     t.status == app_models.TransactionStatus.partial)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  /// Get a map of category totals for the selected month
  Map<String, double> getCategoryTotals() {
    final Map<String, double> categoryTotals = {};
    
    for (var transaction in _transactions) {
      if (transaction.isExpense) {
        categoryTotals.update(
          transaction.category,
          (total) => total + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    
    return categoryTotals;
  }
  
  /// Format a date as 'MMMM yyyy' (e.g., 'June 2023')
  String getMonthYearString(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
  
  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
