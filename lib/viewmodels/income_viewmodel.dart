import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/income_source_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/realtime_data_service.dart';

class IncomeViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final RealtimeDataService _realtimeDataService = RealtimeDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<IncomeSource> _incomeSources = [];
  bool _isLoading = false;
  bool _useFirestore = false; // Flag to determine if we should use Firestore or SQLite
  StreamSubscription<List<IncomeSource>>? _incomeSourceSubscription;
  final Logger logger = Logger('IncomeViewModel');

  List<IncomeSource> get incomeSources => _incomeSources;
  bool get isLoading => _isLoading;
  bool get useFirestore => _useFirestore;
  
  IncomeViewModel() {
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
      _subscribeToIncomeSources();
    } else {
      // Load from SQLite if not using Firestore
      loadIncomeSources();
    }
  }
  
  /// Subscribe to real-time income source updates from Firestore
  void _subscribeToIncomeSources() {
    logger.info('Subscribing to income source updates');
    
    // Cancel any existing subscription
    _incomeSourceSubscription?.cancel();
    
    // Start the income sources stream if not already started
    _realtimeDataService.startIncomeSourcesStream();
    
    // Subscribe to the stream
    _incomeSourceSubscription = _realtimeDataService.incomeSourcesStream.listen(
      (incomeSources) {
        _incomeSources = incomeSources;
        _isLoading = false;
        logger.info('Received ${_incomeSources.length} income sources');
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error in income source stream: $error');
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  Future<void> loadIncomeSources() async {
    if (_useFirestore) {
      // For Firestore, we're already subscribed to real-time updates
      // Just update the loading state
      _isLoading = true;
      notifyListeners();
      
      // The stream listener will handle updating income sources
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
        _incomeSources = await _databaseService.getIncomeSources();
      } catch (e) {
        logger.info('Error loading income sources: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addIncomeSource(IncomeSource incomeSource) async {
    try {
      if (_useFirestore) {
        // For Firestore, save to cloud
        await _firestoreService.saveIncomeSource(incomeSource);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, save to local database
        if (incomeSource.id == null) {
          // New income source
          await _databaseService.insertIncomeSource(incomeSource);
        } else {
          // Update existing income source
          await _databaseService.updateIncomeSource(incomeSource);
        }
        await loadIncomeSources();
      }
      return true;
    } catch (e) {
      logger.info('Error adding/updating income source: $e');
      return false;
    }
  }

  Future<bool> deleteIncomeSource(int id) async {
    try {
      if (_useFirestore) {
        // For Firestore, delete from cloud
        await _firestoreService.deleteIncomeSource(id.toString());
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, delete from local database
        await _databaseService.deleteIncomeSource(id);
        await loadIncomeSources();
      }
      return true;
    } catch (e) {
      logger.warning('Error deleting income source: $e');
      return false;
    }
  }

  double getTotalIncome() {
    return _incomeSources.fold(0, (sum, source) => sum + source.amount);
  }

  double getTotalIncomeByType(String type) {
    return _incomeSources
        .where((source) => source.type == type)
        .fold(0, (sum, source) => sum + source.amount);
  }

  List<IncomeSource> getRecurringIncome() {
    return _incomeSources.where((source) => source.isRecurring).toList();
  }

  List<IncomeSource> getIncomeByType(String type) {
    return _incomeSources.where((source) => source.type == type).toList();
  }

  List<IncomeSource> getRecentIncome(int count) {
    final sortedSources = List<IncomeSource>.from(_incomeSources)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedSources.take(count).toList();
  }

  Map<String, double> getIncomeDistribution() {
    final distribution = <String, double>{};
    
    for (final source in _incomeSources) {
      if (distribution.containsKey(source.type)) {
        distribution[source.type] = distribution[source.type]! + source.amount;
      } else {
        distribution[source.type] = source.amount;
      }
    }
    
    return distribution;
  }
  
  @override
  void dispose() {
    // Cancel the income source subscription to prevent memory leaks
    _incomeSourceSubscription?.cancel();
    logger.info('Disposing IncomeViewModel');
    super.dispose();
  }
}
