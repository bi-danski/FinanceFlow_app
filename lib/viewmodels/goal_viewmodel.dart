import 'package:flutter/foundation.dart';
import '../models/goal_model.dart';
import '../services/database_service.dart';

class GoalViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Goal> _goals = [];
  bool _isLoading = false;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;

  Future<void> loadGoals() async {
    _isLoading = true;
    notifyListeners();

    try {
      _goals = await _databaseService.getGoals();
    } catch (e) {
      print('Error loading goals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGoal(Goal goal) async {
    try {
      await _databaseService.insertGoal(goal);
      await loadGoals();
      return true;
    } catch (e) {
      print('Error adding goal: $e');
      return false;
    }
  }

  Future<bool> updateGoalProgress(Goal goal, double amount) async {
    try {
      Goal updatedGoal = Goal(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount + amount,
        targetDate: goal.targetDate,
        description: goal.description,
        category: goal.category,
      );
      
      await _databaseService.updateGoal(updatedGoal);
      await loadGoals();
      return true;
    } catch (e) {
      print('Error updating goal: $e');
      return false;
    }
  }

  double getTotalSavingsGoals() {
    return _goals.fold(0, (sum, goal) => sum + goal.targetAmount);
  }

  double getTotalCurrentSavings() {
    return _goals.fold(0, (sum, goal) => sum + goal.currentAmount);
  }

  double getOverallProgress() {
    if (getTotalSavingsGoals() == 0) return 0;
    return (getTotalCurrentSavings() / getTotalSavingsGoals()) * 100;
  }
}
