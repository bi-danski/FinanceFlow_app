import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/spending_challenge_model.dart';
import '../services/firestore_service.dart';

class ChallengeViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final Logger _logger = Logger('ChallengeViewModel');

  ChallengeViewModel({required FirestoreService firestoreService}) 
      : _firestoreService = firestoreService {
    _listenToChallenges();
  }

  List<SpendingChallenge> _challenges = [];
  List<SpendingChallenge> get challenges => _challenges;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription? _challengesSubscription;

  void _listenToChallenges() {
    _setLoading(true);
    try {
      _challengesSubscription = _firestoreService.getChallengesStream().listen((challenges) {
        _challenges = challenges;
        _setError(null);
        _setLoading(false);
      }, onError: (e) {
        _logger.severe('Error listening to challenges: $e');
        _setError('Failed to load challenges.');
        _setLoading(false);
      });
    } catch (e) {
      _logger.severe('Error setting up challenge listener: $e');
      _setError('An unexpected error occurred.');
      _setLoading(false);
    }
  }

  Future<void> addChallenge(SpendingChallenge challenge) async {
    try {
      await _firestoreService.addChallenge(challenge);
      notifyListeners();
    } catch (e) {
      _logger.severe('Error adding challenge: $e');
      _setError('Failed to add challenge.');
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _challengesSubscription?.cancel();
    super.dispose();
  }
}
