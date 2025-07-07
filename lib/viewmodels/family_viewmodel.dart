import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/family_member_model.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyViewModel extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  final String _primaryUserId = FirebaseAuth.instance.currentUser?.uid ?? 'demo';
  final Logger logger = Logger('FamilyViewModel');
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;

  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;

  StreamSubscription? _sub;

  void startListening() {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _firestore.familyMembersStream(_primaryUserId).listen((members) {
      _familyMembers = members;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      logger.warning('Family members stream error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> addFamilyMember(FamilyMember member) async {
    try {
      await _firestore.addFamilyMember(_primaryUserId, member);
      return true;
    } catch (e) {
      logger.info('Error adding family member: $e');
      return false;
    }
  }

  Future<bool> updateFamilyMemberSpending(FamilyMember member, double amount) async {
    try {
      // Update the member's spending in Firestore
      await _firestore.updateFamilyMemberSpending(_primaryUserId, member.id!, amount);
      
      // Update local state
      final index = _familyMembers.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _familyMembers[index] = _familyMembers[index].copyWith(spent: amount);
        notifyListeners();
      }
      return true;
    } catch (e) {
      logger.warning('Error updating family member spending: $e');
      return false;
    }
  }

  double getTotalFamilyBudget() {
    return _familyMembers.fold(0, (sum, member) => sum + member.budget);
  }

  double getTotalFamilySpent() {
    return _familyMembers.fold(0, (sum, member) => sum + member.spent);
  }

  double getRemainingFamilyBudget() {
    return getTotalFamilyBudget() - getTotalFamilySpent();
  }
}
