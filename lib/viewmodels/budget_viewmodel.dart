import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/budget_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/realtime_data_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final RealtimeDataService _realtimeDataService = RealtimeDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Budget> _budgets = [];
  bool _isLoading = false;
  bool _useFirestore = false; // Flag to determine if we should use Firestore or SQLite
  StreamSubscription<List<Budget>>? _budgetSubscription;
  final Logger logger = Logger('BudgetViewModel');

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  bool get useFirestore => _useFirestore;
  
  BudgetViewModel() {
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
      _subscribeToBudgets();
    } else {
      // Load from SQLite if not using Firestore
      loadBudgets();
    }
  }
  
  /// Subscribe to real-time budget updates from Firestore
  void _subscribeToBudgets() {
    logger.info('Subscribing to budget updates');
    
    // Cancel any existing subscription
    _budgetSubscription?.cancel();
    
    // Start the budgets stream if not already started
    _realtimeDataService.startBudgetsStream();
    
    // Subscribe to the stream
    _budgetSubscription = _realtimeDataService.budgetsStream.listen(
      (budgets) {
        _budgets = budgets;
        _isLoading = false;
        logger.info('Received ${_budgets.length} budgets');
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error in budget stream: $error');
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  Future<void> loadBudgets() async {
    if (_useFirestore) {
      // For Firestore, we're already subscribed to real-time updates
      // Just update the loading state
      _isLoading = true;
      notifyListeners();
      
      // The stream listener will handle updating budgets
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
        _budgets = await _databaseService.getBudgets();
      } catch (e) {
        logger.info('Error loading budgets: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addBudget(Budget budget) async {
    try {
      if (_useFirestore) {
        // For Firestore, save to cloud
        await _firestoreService.saveBudget(budget);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, save to local database
        if (budget.id == null) {
          // New budget
          await _databaseService.insertBudget(budget);
        } else {
          // Update existing budget
          await _databaseService.updateBudget(budget);
        }
        await loadBudgets();
      }
      logger.info('Budget added: $budget');
      return true;
    } catch (e) {
      logger.warning('Failed to add/update budget: $e');
      return false;
    }
  }

  Future<bool> deleteBudget(int id) async {
    try {
      if (_useFirestore) {
        // For Firestore, delete from cloud
        await _firestoreService.deleteBudget(id.toString());
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, delete from local database
        await _databaseService.deleteBudget(id);
        await loadBudgets();
      }
      return true;
    } catch (e) {
      logger.severe('Unexpected error deleting budget: $e');
      return false;
    }
  }

  Budget? getBudgetByCategory(String category) {
    try {
      return _budgets.firstWhere((budget) => budget.category == category);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateBudgetSpent(String category, double amount) async {
    try {
      if (_useFirestore) {
        // For Firestore, we need to get the budget first, then update it
        Budget? budget = getBudgetByCategory(category);
        if (budget != null) {
          budget = budget.copyWith(spent: budget.spent + amount);
          await _firestoreService.saveBudget(budget);
          // The stream listener will handle updating the UI
        } else {
          logger.warning('No budget found for category: $category');
          return false;
        }
      } else {
        // For SQLite, use the database service
        await _databaseService.updateBudgetSpent(category, amount);
        await loadBudgets();
      }
      return true;
    } catch (e) {
      logger.warning('Failed to update budget spent: $e');
      return false;
    }
  }

  double getTotalBudget() {
    return _budgets.fold(0, (sum, budget) => sum + budget.amount);
  }

  double getTotalSpent() {
    return _budgets.fold(0, (sum, budget) => sum + budget.spent);
  }

  double getRemainingBudget() {
    return getTotalBudget() - getTotalSpent();
  }

  double getPercentUsed() {
    if (getTotalBudget() == 0) return 0;
    return (getTotalSpent() / getTotalBudget()) * 100;
  }

  List<Budget> getBudgetsByOverspent() {
    return _budgets.where((budget) => budget.spent > budget.amount).toList();
  }

  List<Budget> getBudgetsNearLimit() {
    return _budgets.where((budget) => 
      budget.percentUsed >= 80 && budget.percentUsed < 100
    ).toList();
  }
  
  @override
  void dispose() {
    // Cancel the budget subscription to prevent memory leaks
    _budgetSubscription?.cancel();
    logger.info('Disposing BudgetViewModel');
    super.dispose();
  }
}
