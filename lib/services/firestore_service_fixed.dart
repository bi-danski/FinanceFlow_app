import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import '../models/transaction_model.dart' as app_models;
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/income_source_model.dart';
import '../models/loan_model.dart';

/// Firestore database service for FinanceFlow app
/// Handles cloud database operations for all app data
class FirestoreService {
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  static FirestoreService get instance => _instance;
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _logger = Logger('FirestoreService');
  final firestore.FirebaseFirestore _db = firestore.FirebaseFirestore.instance;
  
  // Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  
  // Collection references
  firestore.CollectionReference get _usersCollection => _db.collection('users');
  firestore.CollectionReference get _transactionsCollection => _db.collection('transactions');
  firestore.CollectionReference get _budgetsCollection => _db.collection('budgets');
  firestore.CollectionReference get _goalsCollection => _db.collection('goals');
  firestore.CollectionReference get _incomeSourcesCollection => _db.collection('income_sources');
  firestore.CollectionReference get _loansCollection => _db.collection('loans');
  
  // User profile methods
  
  /// Create a new user profile in Firestore
  Future<void> createUserProfile(String uid, String name, String email) async {
    try {
      await _usersCollection.doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': firestore.FieldValue.serverTimestamp(),
        'lastLogin': firestore.FieldValue.serverTimestamp(),
        'preferences': {},
      });
      _logger.info('User profile created for $uid');
    } catch (e) {
      _logger.severe('Error creating user profile: $e');
      rethrow;
    }
  }
  
  /// Get user profile data
  Future<firestore.DocumentSnapshot> getUserProfile(String uid) async {
    try {
      return await _usersCollection.doc(uid).get();
    } catch (e) {
      _logger.severe('Error getting user profile: $e');
      rethrow;
    }
  }
  
  /// Update user profile data
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
      _logger.info('User profile updated for $uid');
    } catch (e) {
      _logger.severe('Error updating user profile: $e');
      rethrow;
    }
  }
  
  // Transaction methods
  
  /// Save a transaction to Firestore
  /// If the transaction has an ID, update it, otherwise create a new one
  Future<firestore.DocumentReference> saveTransaction(app_models.Transaction transaction) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      final transactionData = transaction.toMap();
      transactionData['userId'] = _userId;
      transactionData['updatedAt'] = firestore.FieldValue.serverTimestamp();
      
      if (transaction.id != null && transaction.id!.isNotEmpty) {
        // Update existing transaction
        final docRef = _transactionsCollection.doc(transaction.id);
        await docRef.update(transactionData);
        _logger.info('Transaction updated: ${transaction.id}');
        return docRef;
      } else {
        // Create new transaction
        transactionData['createdAt'] = firestore.FieldValue.serverTimestamp();
        final docRef = await _transactionsCollection.add(transactionData);
        _logger.info('Transaction created: ${docRef.id}');
        return docRef;
      }
    } catch (e) {
      _logger.severe('Error saving transaction: $e');
      rethrow;
    }
  }
  
  /// Get all transactions for the current user
  Future<List<app_models.Transaction>> getTransactions() async {
    try {
      if (_userId == null) return [];
      
      final querySnapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Convert doc.id to int and set as id
        data['id'] = int.tryParse(doc.id) ?? 0;
        return app_models.Transaction.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.severe('Error getting transactions: $e');
      return [];
    }
  }
  
  /// Get transactions for a specific month
  Future<List<app_models.Transaction>> getTransactionsByMonth(int year, int month) async {
    try {
      if (_userId == null) return [];
      
      // Calculate start and end dates for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      
      final querySnapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = int.tryParse(doc.id) ?? 0;
        return app_models.Transaction.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.severe('Error getting transactions by month: $e');
      return [];
    }
  }
  
  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      await _transactionsCollection.doc(id).delete();
      _logger.info('Transaction deleted: $id');
    } catch (e) {
      _logger.severe('Error deleting transaction: $e');
      rethrow;
    }
  }
  
  // Budget methods
  
  /// Save a budget to Firestore
  Future<firestore.DocumentReference> saveBudget(Budget budget) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      final budgetData = budget.toMap();
      budgetData['userId'] = _userId;
      budgetData['updatedAt'] = firestore.FieldValue.serverTimestamp();
      
      if (budget.id != null && budget.id! > 0) {
        // Update existing budget
        final docRef = _budgetsCollection.doc(budget.id.toString());
        await docRef.update(budgetData);
        _logger.info('Budget updated: ${budget.id}');
        return docRef;
      } else {
        // Create new budget
        budgetData['createdAt'] = firestore.FieldValue.serverTimestamp();
        final docRef = await _budgetsCollection.add(budgetData);
        _logger.info('Budget created: ${docRef.id}');
        return docRef;
      }
    } catch (e) {
      _logger.severe('Error saving budget: $e');
      rethrow;
    }
  }
  
  /// Get all budgets for the current user
  Future<List<Budget>> getBudgets() async {
    try {
      if (_userId == null) return [];
      
      final querySnapshot = await _budgetsCollection
          .where('userId', isEqualTo: _userId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Budget.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.severe('Error getting budgets: $e');
      return [];
    }
  }
  
  /// Delete a budget
  Future<void> deleteBudget(String id) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      await _budgetsCollection.doc(id).delete();
      _logger.info('Budget deleted: $id');
    } catch (e) {
      _logger.severe('Error deleting budget: $e');
      rethrow;
    }
  }
  
  // Goal methods
  
  /// Save a goal to Firestore
  Future<firestore.DocumentReference> saveGoal(Goal goal) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      final goalData = goal.toMap();
      goalData['userId'] = _userId;
      goalData['updatedAt'] = firestore.FieldValue.serverTimestamp();
      
      if (goal.id != null && goal.id!.isNotEmpty) {
        // Update existing goal
        final docRef = _goalsCollection.doc(goal.id.toString());
        await docRef.update(goalData);
        _logger.info('Goal updated: ${goal.id}');
        return docRef;
      } else {
        // Create new goal
        goalData['createdAt'] = firestore.FieldValue.serverTimestamp();
        final docRef = await _goalsCollection.add(goalData);
        _logger.info('Goal created: ${docRef.id}');
        return docRef;
      }
    } catch (e) {
      _logger.severe('Error saving goal: $e');
      rethrow;
    }
  }
  
  /// Get all goals for the current user
  Future<List<Goal>> getGoals() async {
    try {
      if (_userId == null) return [];
      
      final querySnapshot = await _goalsCollection
          .where('userId', isEqualTo: _userId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Goal.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.severe('Error getting goals: $e');
      return [];
    }
  }
  
  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      await _goalsCollection.doc(id).delete();
      _logger.info('Goal deleted: $id');
    } catch (e) {
      _logger.severe('Error deleting goal: $e');
      rethrow;
    }
  }
  
  // Income source methods
  
  /// Save an income source to Firestore
  Future<firestore.DocumentReference> saveIncomeSource(IncomeSource incomeSource) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      final incomeSourceData = incomeSource.toMap();
      incomeSourceData['userId'] = _userId;
      incomeSourceData['updatedAt'] = firestore.FieldValue.serverTimestamp();
      
      if (incomeSource.id != null && incomeSource.id! > 0) {
        // Update existing income source
        final docRef = _incomeSourcesCollection.doc(incomeSource.id.toString());
        await docRef.update(incomeSourceData);
        _logger.info('Income source updated: ${incomeSource.id}');
        return docRef;
      } else {
        // Create new income source
        incomeSourceData['createdAt'] = firestore.FieldValue.serverTimestamp();
        final docRef = await _incomeSourcesCollection.add(incomeSourceData);
        _logger.info('Income source created: ${docRef.id}');
        return docRef;
      }
    } catch (e) {
      _logger.severe('Error saving income source: $e');
      rethrow;
    }
  }
  
  /// Get all income sources for the current user
  Future<List<IncomeSource>> getIncomeSources() async {
    try {
      if (_userId == null) return [];
      
      final querySnapshot = await _incomeSourcesCollection
          .where('userId', isEqualTo: _userId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = int.tryParse(doc.id) ?? 0;
        return IncomeSource.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.severe('Error getting income sources: $e');
      return [];
    }
  }
  
  /// Delete an income source
  Future<void> deleteIncomeSource(String id) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      await _incomeSourcesCollection.doc(id).delete();
      _logger.info('Income source deleted: $id');
    } catch (e) {
      _logger.severe('Error deleting income source: $e');
      rethrow;
    }
  }
  
  // Loan methods
  
  /// Save a loan to Firestore
  Future<firestore.DocumentReference> saveLoan(Loan loan) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      final loanData = loan.toMap();
      loanData['userId'] = _userId;
      loanData['updatedAt'] = firestore.FieldValue.serverTimestamp();
      
      if (loan.id != null && loan.id! > 0) {
        // Update existing loan
        final docRef = _loansCollection.doc(loan.id.toString());
        await docRef.update(loanData);
        _logger.info('Loan updated: ${loan.id}');
        return docRef;
      } else {
        // Create new loan
        loanData['createdAt'] = firestore.FieldValue.serverTimestamp();
        final docRef = await _loansCollection.add(loanData);
        _logger.info('Loan created: ${docRef.id}');
        return docRef;
      }
    } catch (e) {
      _logger.severe('Error saving loan: $e');
      rethrow;
    }
  }
  
  /// Get all loans for the current user
  Future<List<Loan>> getLoans() async {
    try {
      if (_userId == null) return [];
      
      final querySnapshot = await _loansCollection
          .where('userId', isEqualTo: _userId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = int.tryParse(doc.id) ?? 0;
        return Loan.fromMap(data);
      }).toList();
    } catch (e) {
      _logger.severe('Error getting loans: $e');
      return [];
    }
  }
  
  /// Delete a loan
  Future<void> deleteLoan(String id) async {
    try {
      if (_userId == null) throw Exception('No authenticated user');
      
      await _loansCollection.doc(id).delete();
      _logger.info('Loan deleted: $id');
    } catch (e) {
      _logger.severe('Error deleting loan: $e');
      rethrow;
    }
  }
}
