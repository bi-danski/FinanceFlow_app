import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/budget_model.dart';
import '../services/database_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Budget> _budgets = [];
  bool _isLoading = false;
  final Logger logger = Logger('BudgetViewModel');

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets() async {
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

  Future<bool> addBudget(Budget budget) async {
    try {
      if (budget.id == null) {
        // New budget
        await _databaseService.insertBudget(budget);
      } else {
        // Update existing budget
        await _databaseService.updateBudget(budget);
      }
      await loadBudgets();
      logger.info('Budget added: $budget');
      return true;
    } catch (e) {
      logger.warning('Failed to add/update budget: $e');
      return false;
    }
  }

  Future<bool> deleteBudget(int id) async {
    try {
      await _databaseService.deleteBudget(id);
      await loadBudgets();
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
      await _databaseService.updateBudgetSpent(category, amount);
      await loadBudgets();
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
}
