import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/family_member_model.dart';
import '../models/user_model.dart';
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
      final users = await _databaseService.getFamilyMembers();
      _familyMembers = users.map((user) => FamilyMember(
        id: user.id,
        name: user.name,
        budget: 0.0, // Default values since User doesn't have these fields
        spent: 0.0,
        avatarPath: '',
      )).toList();
    } catch (e) {
      logger.info('Error loading family members: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addFamilyMember(FamilyMember member) async {
    try {
      // Convert FamilyMember to User for database service
      final user = User(
        id: member.id ?? 0, // Provide default value if id is null
        name: member.name,
        email: '', // Required field for User
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        preferences: {},
      );
      
      // Get current user ID for primary user relationship
      final currentUserId = await _databaseService.getCurrentUserId();
      
      // Use a default value of 1 if currentUserId is null
      await _databaseService.insertFamilyMember(user, currentUserId ?? 1);
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
      
      // Convert FamilyMember to User for database service
      final user = User(
        id: updatedMember.id ?? 0, // Provide default value if id is null
        name: updatedMember.name,
        email: '', // Required field for User
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        preferences: {},
      );
      
      await _databaseService.updateFamilyMember(user);
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
