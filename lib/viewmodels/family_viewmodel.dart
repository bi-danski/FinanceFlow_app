import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/family_member_model.dart';
import '../services/database_service.dart';

class FamilyViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final Logger logger = Logger('FamilyViewModel');
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;

  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;

  Future<void> loadFamilyMembers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _familyMembers = await _databaseService.getFamilyMembers();
    } catch (e) {
      logger.info('Error loading family members: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addFamilyMember(FamilyMember member) async {
    try {
      await _databaseService.insertFamilyMember(member);
      await loadFamilyMembers();
      return true;
    } catch (e) {
      logger.info('Error adding family member: $e');
      return false;
    }
  }

  Future<bool> updateFamilyMemberSpending(FamilyMember member, double amount) async {
    try {
      FamilyMember updatedMember = FamilyMember(
        id: member.id,
        name: member.name,
        budget: member.budget,
        spent: member.spent + amount,
        avatarPath: member.avatarPath,
      );
      
      await _databaseService.updateFamilyMember(updatedMember);
      await loadFamilyMembers();
      return true;
    } catch (e) {
      logger.info('Error updating family member: $e');
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
