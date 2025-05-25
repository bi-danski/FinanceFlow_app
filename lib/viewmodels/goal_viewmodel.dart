import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/goal_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/realtime_data_service.dart';

class GoalViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final RealtimeDataService _realtimeDataService = RealtimeDataService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger logger = Logger('GoalViewModel');
  
  List<Goal> _goals = [];
  bool _isLoading = false;
  bool _useFirestore = false; // Flag to determine if we should use Firestore or SQLite
  StreamSubscription<List<Goal>>? _goalSubscription;

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  bool get useFirestore => _useFirestore;
  
  GoalViewModel() {
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
      _subscribeToGoals();
    } else {
      // Load from SQLite if not using Firestore
      loadGoals();
    }
  }
  
  /// Subscribe to real-time goal updates from Firestore
  void _subscribeToGoals() {
    logger.info('Subscribing to goal updates');
    
    // Cancel any existing subscription
    _goalSubscription?.cancel();
    
    // Start the goals stream if not already started
    _realtimeDataService.startGoalsStream();
    
    // Subscribe to the stream
    _goalSubscription = _realtimeDataService.goalsStream.listen(
      (goals) {
        _goals = goals;
        _isLoading = false;
        logger.info('Received ${_goals.length} goals');
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error in goal stream: $error');
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  Future<void> loadGoals() async {
    if (_useFirestore) {
      // For Firestore, we're already subscribed to real-time updates
      // Just update the loading state
      _isLoading = true;
      notifyListeners();
      
      // The stream listener will handle updating goals
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
        _goals = await _databaseService.getGoals();
      } catch (e) {
        logger.info('Error loading goals: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addGoal(Goal goal) async {
    try {
      if (_useFirestore) {
        // For Firestore, save to cloud
        await _firestoreService.saveGoal(goal);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, save to local database
        await _databaseService.insertGoal(goal);
        await loadGoals();
      }
      return true;
    } catch (e) {
      logger.info('Error adding goal: $e');
      return false;
    }
  }

  Future<bool> updateGoalProgress(Goal goal, double amount) async {
    try {
      // Create updated goal with new amount
      Goal updatedGoal = Goal(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount + amount,
        targetDate: goal.targetDate,
        description: goal.description,
        category: goal.category,
      );
      
      if (_useFirestore) {
        // For Firestore, save to cloud
        await _firestoreService.saveGoal(updatedGoal);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, update in local database
        await _databaseService.updateGoal(updatedGoal);
        await loadGoals();
      }
      return true;
    } catch (e) {
      logger.warning('Error updating goal: $e');
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
  
  @override
  void dispose() {
    // Cancel the goal subscription to prevent memory leaks
    _goalSubscription?.cancel();
    logger.info('Disposing GoalViewModel');
    super.dispose();
  }
}
