import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart' as app_models;
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/income_source_model.dart';
import '../models/loan_model.dart';

/// Real-time data service for FinanceFlow app
/// Provides streams of data from Firestore for real-time updates
class RealtimeDataService extends ChangeNotifier {
  // Singleton pattern
  static final RealtimeDataService _instance = RealtimeDataService._internal();
  static RealtimeDataService get instance => _instance;
  factory RealtimeDataService() => _instance;
  RealtimeDataService._internal();

  final _logger = Logger('RealtimeDataService');
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controllers
  final StreamController<List<app_models.Transaction>> _transactionsController = 
      StreamController<List<app_models.Transaction>>.broadcast();
  final StreamController<List<Budget>> _budgetsController = 
      StreamController<List<Budget>>.broadcast();
  final StreamController<List<Goal>> _goalsController = 
      StreamController<List<Goal>>.broadcast();
  final StreamController<List<IncomeSource>> _incomeSourcesController = 
      StreamController<List<IncomeSource>>.broadcast();
  final StreamController<List<Loan>> _loansController = 
      StreamController<List<Loan>>.broadcast();
  
  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;
  StreamSubscription<QuerySnapshot>? _budgetsSubscription;
  StreamSubscription<QuerySnapshot>? _goalsSubscription;
  StreamSubscription<QuerySnapshot>? _incomeSourcesSubscription;
  StreamSubscription<QuerySnapshot>? _loansSubscription;
  
  // Streams
  Stream<List<app_models.Transaction>> get transactionsStream => _transactionsController.stream;
  Stream<List<Budget>> get budgetsStream => _budgetsController.stream;
  Stream<List<Goal>> get goalsStream => _goalsController.stream;
  Stream<List<IncomeSource>> get incomeSourcesStream => _incomeSourcesController.stream;
  Stream<List<Loan>> get loansStream => _loansController.stream;
  
  // Collection references
  CollectionReference get _transactionsCollection => _db.collection('transactions');
  CollectionReference get _budgetsCollection => _db.collection('budgets');
  CollectionReference get _goalsCollection => _db.collection('goals');
  CollectionReference get _incomeSourcesCollection => _db.collection('income_sources');
  CollectionReference get _loansCollection => _db.collection('loans');
  
  /// Initialize all data streams
  void initializeStreams() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _logger.warning('Cannot initialize streams: No authenticated user');
      return;
    }
    
    _logger.info('Initializing real-time data streams for user: $userId');
    
    // Start all streams
    startTransactionsStream();
    startBudgetsStream();
    startGoalsStream();
    startIncomeSourcesStream();
    startLoansStream();
  }
  
  /// Start streaming transactions
  void startTransactionsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting transactions stream');
    
    // Cancel existing subscription if any
    _transactionsSubscription?.cancel();
    
    // Start new subscription
    _transactionsSubscription = _transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
          try {
            final transactions = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Convert Firestore document ID to transaction ID
              data['id'] = int.tryParse(doc.id) ?? 0;
              return app_models.Transaction.fromMap(data);
            }).toList();
            
            _transactionsController.add(transactions);
            _logger.info('Updated transactions stream with ${transactions.length} items');
          } catch (e) {
            _logger.severe('Error processing transactions snapshot: $e');
            _transactionsController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in transactions stream: $error');
          _transactionsController.addError(error);
        });
  }
  
  /// Start streaming budgets
  void startBudgetsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting budgets stream');
    
    // Cancel existing subscription if any
    _budgetsSubscription?.cancel();
    
    // Start new subscription
    _budgetsSubscription = _budgetsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          try {
            final budgets = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = int.tryParse(doc.id) ?? 0;
              return Budget.fromMap(data);
            }).toList();
            
            _budgetsController.add(budgets);
            _logger.info('Updated budgets stream with ${budgets.length} items');
          } catch (e) {
            _logger.severe('Error processing budgets snapshot: $e');
            _budgetsController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in budgets stream: $error');
          _budgetsController.addError(error);
        });
  }
  
  /// Start streaming goals
  void startGoalsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting goals stream');
    
    // Cancel existing subscription if any
    _goalsSubscription?.cancel();
    
    // Start new subscription
    _goalsSubscription = _goalsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          try {
            final goals = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = int.tryParse(doc.id) ?? 0;
              return Goal.fromMap(data);
            }).toList();
            
            _goalsController.add(goals);
            _logger.info('Updated goals stream with ${goals.length} items');
          } catch (e) {
            _logger.severe('Error processing goals snapshot: $e');
            _goalsController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in goals stream: $error');
          _goalsController.addError(error);
        });
  }
  
  /// Start streaming income sources
  void startIncomeSourcesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting income sources stream');
    
    // Cancel existing subscription if any
    _incomeSourcesSubscription?.cancel();
    
    // Start new subscription
    _incomeSourcesSubscription = _incomeSourcesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          try {
            final incomeSources = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = int.tryParse(doc.id) ?? 0;
              return IncomeSource.fromMap(data);
            }).toList();
            
            _incomeSourcesController.add(incomeSources);
            _logger.info('Updated income sources stream with ${incomeSources.length} items');
          } catch (e) {
            _logger.severe('Error processing income sources snapshot: $e');
            _incomeSourcesController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in income sources stream: $error');
          _incomeSourcesController.addError(error);
        });
  }
  
  /// Start streaming loans
  void startLoansStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting loans stream');
    
    // Cancel existing subscription if any
    _loansSubscription?.cancel();
    
    // Start new subscription
    _loansSubscription = _loansCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          try {
            final loans = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = int.tryParse(doc.id) ?? 0;
              return Loan.fromMap(data);
            }).toList();
            
            _loansController.add(loans);
            _logger.info('Updated loans stream with ${loans.length} items');
          } catch (e) {
            _logger.severe('Error processing loans snapshot: $e');
            _loansController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in loans stream: $error');
          _loansController.addError(error);
        });
  }
  
  /// Stop all streams and clean up resources
  @override
  void dispose() {
    _logger.info('Disposing real-time data service');
    
    // Cancel all subscriptions
    _transactionsSubscription?.cancel();
    _budgetsSubscription?.cancel();
    _goalsSubscription?.cancel();
    _incomeSourcesSubscription?.cancel();
    _loansSubscription?.cancel();
    
    // Close all controllers
    _transactionsController.close();
    _budgetsController.close();
    _goalsController.close();
    _incomeSourcesController.close();
    _loansController.close();
    
    // Call super.dispose() as required
    super.dispose();
  }
  
  /// Restart all streams (useful after authentication changes)
  void restartStreams() {
    _logger.info('Restarting all data streams');
    
    // Cancel all existing subscriptions
    _transactionsSubscription?.cancel();
    _budgetsSubscription?.cancel();
    _goalsSubscription?.cancel();
    _incomeSourcesSubscription?.cancel();
    _loansSubscription?.cancel();
    
    // Start all streams again
    initializeStreams();
  }
}
