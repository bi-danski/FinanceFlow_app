import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ChallengeType {
  noSpend,       // No spending in a category for a period
  budgetLimit,   // Stay under budget for a category
  savingsTarget, // Save a specific amount
  habitBuilding, // Build a financial habit (e.g., daily tracking)
  custom         // User-defined challenge
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  expert
}

enum ChallengeStatus {
  notStarted,
  active,
  completed,
  failed
}

class SpendingChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categories; // Categories this challenge applies to
  final double targetAmount; // Budget limit or savings target
  final double currentAmount; // Current spending or savings
  final IconData icon;
  final Color color;
  final List<ChallengeBadge> availableBadges;
  final List<ChallengeBadge> earnedBadges;
  final List<ChallengeRule> rules;
  
  SpendingChallenge({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    this.status = ChallengeStatus.notStarted,
    required this.startDate,
    required this.endDate,
    required this.categories,
    this.targetAmount = 0.0,
    this.currentAmount = 0.0,
    this.icon = Icons.emoji_events,
    this.color = Colors.amber,
    List<ChallengeBadge>? availableBadges,
    List<ChallengeBadge>? earnedBadges,
    List<ChallengeRule>? rules,
  }) : 
    id = id ?? const Uuid().v4(),
    availableBadges = availableBadges ?? [],
    earnedBadges = earnedBadges ?? [],
    rules = rules ?? [];
  
  // Duration of the challenge in days
  int get durationInDays => endDate.difference(startDate).inDays;
  
  // Days remaining in the challenge
  int get daysRemaining => 
    status == ChallengeStatus.active 
      ? endDate.difference(DateTime.now()).inDays 
      : 0;
  
  // Progress percentage
  double get progressPercentage {
    if (status == ChallengeStatus.notStarted) return 0.0;
    if (status == ChallengeStatus.completed) return 1.0;
    if (status == ChallengeStatus.failed) {
      final totalDays = durationInDays;
      final daysElapsed = totalDays - daysRemaining;
      return daysElapsed / totalDays;
    }
    
    switch (type) {
      case ChallengeType.noSpend:
        // For no-spend, progress is days elapsed without spending
        final totalDays = durationInDays;
        final daysElapsed = totalDays - daysRemaining;
        return daysElapsed / totalDays;
        
      case ChallengeType.budgetLimit:
        // For budget limit, progress is how much of budget is remaining
        if (targetAmount <= 0) return 0.0;
        return (1 - (currentAmount / targetAmount)).clamp(0.0, 1.0);
        
      case ChallengeType.savingsTarget:
        // For savings target, progress is how much has been saved
        if (targetAmount <= 0) return 0.0;
        return (currentAmount / targetAmount).clamp(0.0, 1.0);
        
      case ChallengeType.habitBuilding:
      case ChallengeType.custom:
        // For habit building or custom, progress is days elapsed
        final totalDays = durationInDays;
        final daysElapsed = totalDays - daysRemaining;
        return daysElapsed / totalDays;
    }
  }
  
  // Check if challenge is on track
  bool get isOnTrack {
    if (status != ChallengeStatus.active) return false;
    
    switch (type) {
      case ChallengeType.noSpend:
        // On track if no spending recorded
        return currentAmount == 0;
        
      case ChallengeType.budgetLimit:
        // On track if spending is proportionally under budget
        if (durationInDays == 0) return false;
        final elapsedRatio = (durationInDays - daysRemaining) / durationInDays;
        return currentAmount <= (targetAmount * elapsedRatio);
        
      case ChallengeType.savingsTarget:
        // On track if savings are proportionally on target
        if (durationInDays == 0) return false;
        final elapsedRatio = (durationInDays - daysRemaining) / durationInDays;
        return currentAmount >= (targetAmount * elapsedRatio);
        
      case ChallengeType.habitBuilding:
      case ChallengeType.custom:
        // For habit building, check if all rules are satisfied
        return rules.every((rule) => rule.isSatisfied);
    }
  }
  
  // Get points earned in this challenge
  int get pointsEarned {
    int basePoints = 0;
    
    // Base points by difficulty
    switch (difficulty) {
      case ChallengeDifficulty.easy: basePoints = 100; break;
      case ChallengeDifficulty.medium: basePoints = 250; break;
      case ChallengeDifficulty.hard: basePoints = 500; break;
      case ChallengeDifficulty.expert: basePoints = 1000; break;
    }
    
    // Adjust based on status and progress
    switch (status) {
      case ChallengeStatus.notStarted: return 0;
      case ChallengeStatus.active: return (basePoints * progressPercentage).round();
      case ChallengeStatus.completed: return basePoints;
      case ChallengeStatus.failed: return (basePoints * progressPercentage * 0.5).round();
    }
  }
  
  // Update challenge with new transaction data
  SpendingChallenge updateWithTransaction(double amount, String category, DateTime date) {
    if (status != ChallengeStatus.active) return this;
    if (date.isBefore(startDate) || date.isAfter(endDate)) return this;
    if (!categories.contains(category) && categories.isNotEmpty) return this;
    
    double newCurrentAmount = currentAmount;
    ChallengeStatus newStatus = status;
    List<ChallengeBadge> newEarnedBadges = List.from(earnedBadges);
    
    switch (type) {
      case ChallengeType.noSpend:
        // If any spending in the category, challenge fails
        if (amount > 0) {
          newStatus = ChallengeStatus.failed;
        }
        break;
        
      case ChallengeType.budgetLimit:
        // Add to current spending
        newCurrentAmount += amount;
        // If over budget, challenge fails
        if (newCurrentAmount > targetAmount) {
          newStatus = ChallengeStatus.failed;
        }
        break;
        
      case ChallengeType.savingsTarget:
        // Add to current savings
        newCurrentAmount += amount;
        // If reached target, challenge completes
        if (newCurrentAmount >= targetAmount) {
          newStatus = ChallengeStatus.completed;
          
          // Award all remaining badges
          for (final badge in availableBadges) {
            if (!newEarnedBadges.contains(badge)) {
              newEarnedBadges.add(badge);
            }
          }
        }
        break;
        
      case ChallengeType.habitBuilding:
      case ChallengeType.custom:
        // Update rules based on transaction
        // This would need custom logic per rule type
        break;
    }
    
    // Check for badges to award
    for (final badge in availableBadges) {
      if (!newEarnedBadges.contains(badge)) {
        if (badge.isEarned(newCurrentAmount, progressPercentage)) {
          newEarnedBadges.add(badge);
        }
      }
    }
    
    return copyWith(
      currentAmount: newCurrentAmount,
      status: newStatus,
      earnedBadges: newEarnedBadges,
    );
  }
  
  // Check if challenge is completed
  SpendingChallenge checkCompletion() {
    if (status != ChallengeStatus.active) return this;
    
    // If end date has passed, evaluate completion
    if (DateTime.now().isAfter(endDate)) {
      switch (type) {
        case ChallengeType.noSpend:
          // Completed if no spending recorded
          return copyWith(
            status: currentAmount == 0 ? ChallengeStatus.completed : ChallengeStatus.failed
          );
          
        case ChallengeType.budgetLimit:
          // Completed if under budget
          return copyWith(
            status: currentAmount <= targetAmount ? ChallengeStatus.completed : ChallengeStatus.failed
          );
          
        case ChallengeType.savingsTarget:
          // Completed if savings target reached
          return copyWith(
            status: currentAmount >= targetAmount ? ChallengeStatus.completed : ChallengeStatus.failed
          );
          
        case ChallengeType.habitBuilding:
        case ChallengeType.custom:
          // Completed if all rules satisfied
          return copyWith(
            status: rules.every((rule) => rule.isSatisfied) ? ChallengeStatus.completed : ChallengeStatus.failed
          );
      }
    }
    
    return this;
  }
  
  SpendingChallenge copyWith({
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    double? targetAmount,
    double? currentAmount,
    IconData? icon,
    Color? color,
    List<ChallengeBadge>? availableBadges,
    List<ChallengeBadge>? earnedBadges,
    List<ChallengeRule>? rules,
  }) {
    return SpendingChallenge(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categories: categories ?? this.categories,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      availableBadges: availableBadges ?? this.availableBadges,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      rules: rules ?? this.rules,
    );
  }
}

class ChallengeBadge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final double unlockThreshold; // Percentage or amount to unlock
  
  ChallengeBadge({
    String? id,
    required this.name,
    required this.description,
    required this.icon,
    this.color = Colors.amber,
    required this.unlockThreshold,
  }) : id = id ?? const Uuid().v4();
  
  bool isEarned(double currentAmount, double progressPercentage) {
    // Different badge types might have different unlock conditions
    return progressPercentage >= unlockThreshold;
  }
}

class ChallengeRule {
  final String id;
  final String description;
  final bool isSatisfied;
  
  ChallengeRule({
    String? id,
    required this.description,
    this.isSatisfied = false,
  }) : id = id ?? const Uuid().v4();
  
  ChallengeRule copyWith({
    String? description,
    bool? isSatisfied,
  }) {
    return ChallengeRule(
      id: id,
      description: description ?? this.description,
      isSatisfied: isSatisfied ?? this.isSatisfied,
    );
  }
}
