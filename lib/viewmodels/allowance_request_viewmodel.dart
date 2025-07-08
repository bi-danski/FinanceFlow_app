import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/allowance_request_model.dart';
import '../services/firestore_service.dart';

class AllowanceRequestViewModel extends ChangeNotifier {
  final _logger = Logger('AllowanceRequestViewModel');
  final FirestoreService _firestore = FirestoreService.instance;

  final String primaryUserId;
  final String memberId;

  AllowanceRequestViewModel({required this.primaryUserId, required this.memberId});

  List<AllowanceRequest> _requests = [];
  bool _isLoading = false;
  StreamSubscription? _sub;

  List<AllowanceRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  void startListening() {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _firestore
        .allowanceRequestsStream(memberId)
        .listen((data) {
      _requests = data
          .map((m) => AllowanceRequest.fromMap(m, id: m['id']))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _logger.warning('Allowance request stream error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> requestAllowance({required double amount, required String reason, required String memberName}) async {
    try {
      await _firestore.createAllowanceRequest(memberId, amount: amount, reason: reason);
    } catch (e) {
      _logger.severe('Error creating allowance request: $e');
      rethrow;
    }
  }

  Future<void> approveRequest(String requestId) async {
    await _updateStatus(requestId, 'approved');
  }

  Future<void> declineRequest(String requestId) async {
    await _updateStatus(requestId, 'declined');
  }

  Future<void> _updateStatus(String requestId, String status) async {
    try {
      await _firestore.updateAllowanceRequest(memberId, requestId, status: status);
    } catch (e) {
      _logger.severe('Error updating allowance request status: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
