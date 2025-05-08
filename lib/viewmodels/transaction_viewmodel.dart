import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../constants/app_constants.dart';

class TransactionViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();
  final Logger logger = Logger('TransactionViewModel');

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    loadTransactionsByMonth(month);
  }

  Future<void> loadTransactions() async {
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

  Future<void> loadRecentTransactions(int limit) async {
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

  Future<void> loadTransactionsByMonth(DateTime month) async {
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

  Future<bool> addTransaction(Transaction transaction) async {
    try {
      await _databaseService.insertTransaction(transaction);
      await loadTransactionsByMonth(_selectedMonth);
      return true;
    } catch (e) {
      logger.info('Error adding transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      await _databaseService.updateTransaction(transaction);
      await loadTransactionsByMonth(_selectedMonth);
      return true;
    } catch (e) {
      logger.warning('Error updating transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _databaseService.deleteTransaction(id);
      await loadTransactionsByMonth(_selectedMonth);
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
}
