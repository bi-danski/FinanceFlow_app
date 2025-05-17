import 'dart:math';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../models/transaction_model.dart' as app_models; // Use alias to match database_service.dart
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/insight_model.dart';
import '../models/income_source_model.dart';
import '../models/loan_model.dart';
import '../constants/app_constants.dart';
import 'database_service.dart';

class InsightsService {
  static final InsightsService instance = InsightsService._internal();
  final DatabaseService _databaseService = DatabaseService.instance;
  final Random _random = Random();
  final Logger logger = Logger('InsightsService');

  InsightsService._internal();

  // Generate insights based on user's financial data
  Future<List<Insight>> generateInsights() async {
    List<Insight> insights = [];
    
    // Get all necessary data
    final transactions = await _databaseService.getTransactions();
    final budgets = await _databaseService.getBudgets();
    final goals = await _databaseService.getGoals();
    final incomeSources = await _databaseService.getIncomeSources();
    final loans = await _databaseService.getLoans();
    
    // Generate different types of insights
    insights.addAll(await _generateSpendingPatternInsights(transactions));
    insights.addAll(await _generateBudgetAlerts(transactions, budgets));
    insights.addAll(await _generateSavingOpportunities(transactions));
    insights.addAll(await _generateFinancialHealthInsights(
      transactions, budgets, goals, incomeSources, loans
    ));
    
    // Sort insights by relevance score (descending)
    insights.sort((a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));
    
    return insights;
  }

  // Get insights from database
  Future<List<Insight>> getInsights() async {
    try {
      return await _databaseService.getInsights();
    } catch (e) {
      logger.info('Error getting insights: $e');
      return [];
    }
  }

  // Save an insight to database
  Future<int> saveInsight(Insight insight) async {
    try {
      return await _databaseService.insertInsight(insight);
    } catch (e) {
      logger.info('Error saving insight: $e');
      return -1;
    }
  }

  // Mark insight as read
  Future<bool> markAsRead(int id) async {
    try {
      final insights = await _databaseService.getInsights();
      final insight = insights.firstWhere((i) => i.id == id, orElse: () => throw Exception('Insight not found'));
      final updatedInsight = insight.copyWith(isRead: true);
      await _databaseService.updateInsight(updatedInsight);
      return true;
    } catch (e) {
      logger.warning('Error marking insight as read: $e');
      return false;
    }
  }

  // Dismiss insight
  Future<bool> dismissInsight(int id) async {
    try {
      final insights = await _databaseService.getInsights();
      final insight = insights.firstWhere((i) => i.id == id, orElse: () => throw Exception('Insight not found'));
      final updatedInsight = insight.copyWith(isDismissed: true);
      await _databaseService.updateInsight(updatedInsight);
      return true;
    } catch (e) {
      logger.severe('Error dismissing insight: $e');
      return false;
    }
  }

  // Generate spending pattern insights
  Future<List<Insight>> _generateSpendingPatternInsights(List<app_models.Transaction> transactions) async {
    List<Insight> insights = [];
    
    if (transactions.isEmpty) return insights;
    
    // Group transactions by category
    Map<String, List<app_models.Transaction>> categorizedTransactions = {};
    for (var transaction in transactions) {
      if (transaction.amount < 0) { // Only consider expenses
        final category = transaction.category;
        if (!categorizedTransactions.containsKey(category)) {
          categorizedTransactions[category] = [];
        }
        categorizedTransactions[category]!.add(transaction);
      }
    }
    
    // Calculate current month and previous month
    DateTime now = DateTime.now();
    DateTime currentMonthStart = DateTime(now.year, now.month, 1);
    DateTime previousMonthStart = DateTime(now.year, now.month - 1, 1);
    
    // Analyze spending patterns for each category
    categorizedTransactions.forEach((category, categoryTransactions) {
      // Calculate total spent in current and previous month
      double currentMonthTotal = categoryTransactions
          .where((t) => t.date.isAfter(currentMonthStart))
          .fold(0, (sum, t) => sum + t.amount);
      
      double previousMonthTotal = categoryTransactions
          .where((t) => t.date.isAfter(previousMonthStart) && t.date.isBefore(currentMonthStart))
          .fold(0, (sum, t) => sum + t.amount);
      
      // Calculate percentage change
      double percentageChange = ((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100;
      
      // Only create insight if change is significant (more than 20%)
      if (percentageChange.abs() >= 20) {
        final insight = SpendingPatternInsight(
          title: '${percentageChange > 0 ? 'Increased' : 'Decreased'} spending on $category',
          description: 'Your spending on $category has ${percentageChange > 0 ? 'increased' : 'decreased'} by ${percentageChange.abs().toStringAsFixed(1)}% compared to last month.',
          date: DateTime.now(),
          category: category,
          percentageChange: percentageChange,
          previousAmount: previousMonthTotal,
          currentAmount: currentMonthTotal,
          timeFrame: 'month',
          relevanceScore: min(1.0, percentageChange.abs() / 100),
        );
        
        insights.add(insight);
      }
    });
    
    return insights;
  }

  // Generate budget alerts
  Future<List<Insight>> _generateBudgetAlerts(List<app_models.Transaction> transactions, List<Budget> budgets) async {
    List<Insight> insights = [];
    
    if (budgets.isEmpty) return insights;
    
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    // Check each budget
    for (var budget in budgets) {
      // Get transactions for this category in the current month
      final categoryTransactions = transactions.where((t) => 
        t.category == budget.category && 
        t.date.year == currentMonth.year && 
        t.date.month == currentMonth.month &&
        t.amount < 0 // Only expenses
      ).toList();
      
      if (categoryTransactions.isEmpty) continue;
      
      // Calculate total spent
      final totalSpent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
      
      // Calculate percentage of budget used
      final percentageUsed = (totalSpent / budget.amount) * 100;
      
      // Create alerts based on percentage used
      if (percentageUsed >= 90) {
        final insight = BudgetAlertInsight(
          title: 'Budget for ${budget.category} almost depleted',
          description: 'You\'ve used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.category} budget for this month.',
          date: DateTime.now(),
          category: budget.category,
          budgetAmount: budget.amount,
          spentAmount: totalSpent,
          percentageUsed: percentageUsed,
          relevanceScore: min(1.0, percentageUsed / 100),
        );
        
        insights.add(insight);
      } else if (percentageUsed >= 75 && now.day <= 20) {
        // If we've used 75% of budget but we're only 2/3 through the month
        final insight = BudgetAlertInsight(
          title: 'High spending rate on ${budget.category}',
          description: 'You\'ve already used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.category} budget, but we\'re only ${(now.day / 30 * 100).toStringAsFixed(1)}% through the month.',
          date: DateTime.now(),
          category: budget.category,
          budgetAmount: budget.amount,
          spentAmount: totalSpent,
          percentageUsed: percentageUsed,
          relevanceScore: min(0.9, percentageUsed / 100),
        );
        
        insights.add(insight);
      }
    }
    
    return insights;
  }

  // Generate saving opportunities
  Future<List<Insight>> _generateSavingOpportunities(List<app_models.Transaction> transactions) async {
    List<Insight> insights = [];
    
    if (transactions.isEmpty) return insights;
    
    // Group transactions by month if needed for future implementations
    
    // Group transactions by category
    Map<String, List<app_models.Transaction>> categorizedTransactions = {};
    for (var transaction in transactions) {
      if (transaction.amount < 0) { // Only consider expenses
        final category = transaction.category;
        if (!categorizedTransactions.containsKey(category)) {
          categorizedTransactions[category] = [];
        }
        categorizedTransactions[category]!.add(transaction);
      }
    }
    
    // Define saving suggestions for each category
    Map<String, List<String>> savingSuggestions = {
      'Food': [
        'Consider meal planning to reduce food waste and grocery costs.',
        'Try cooking at home more often instead of eating out.',
        'Look for grocery store sales and use coupons when possible.',
      ],
      'Transport': [
        'Consider carpooling or using public transportation when possible.',
        'Combine errands to save on fuel costs.',
        'Check if your car insurance offers any discounts.',
      ],
      'Entertainment': [
        'Look for free or low-cost entertainment options in your area.',
        'Consider sharing subscription services with family or friends.',
        'Take advantage of happy hours and special promotions.',
      ],
      'Shopping': [
        'Make a shopping list and stick to it to avoid impulse purchases.',
        'Wait for sales before making major purchases.',
        'Consider buying used or refurbished items when appropriate.',
      ],
    };
    
    // Analyze each category for potential savings
    for (var category in categorizedTransactions.keys) {
      if (!savingSuggestions.containsKey(category)) continue;
      
      final categoryTransactions = categorizedTransactions[category]!;
      
      // Calculate average monthly spending
      final totalSpent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
      final monthsSpan = _calculateMonthsSpan(categoryTransactions);
      
      if (monthsSpan == 0) continue;
      
      final averageMonthlySpending = totalSpent / monthsSpan;
      
      // Only suggest savings for categories with significant spending
      if (averageMonthlySpending > 100) {
        // Estimate potential savings (10-20% of current spending)
        final savingsPercentage = 0.1 + (_random.nextDouble() * 0.1);
        final potentialSavings = averageMonthlySpending * savingsPercentage;
        
        // Get a random suggestion
        final suggestions = savingSuggestions[category]!;
        final suggestion = suggestions[_random.nextInt(suggestions.length)];
        
        final insight = SavingOpportunityInsight(
          title: 'Potential savings on $category',
          description: 'You could save approximately ${NumberFormat.currency(symbol: '\$').format(potentialSavings)} per month on $category expenses.',
          date: DateTime.now(),
          category: category,
          potentialSavings: potentialSavings,
          suggestion: suggestion,
          relevanceScore: min(0.8, potentialSavings / 200),
        );
        
        insights.add(insight);
      }
    }
    
    return insights;
  }

  // Generate financial health insights
  Future<List<Insight>> _generateFinancialHealthInsights(
    List<app_models.Transaction> transactions,
    List<Budget> budgets,
    List<Goal> goals,
    List<IncomeSource> incomeSources,
    List<Loan> loans
  ) async {
    List<Insight> insights = [];
    
    if (transactions.isEmpty) return insights;
    
    // Calculate total income
    final totalIncome = incomeSources.fold(0.0, (sum, source) => sum + source.amount);
    
    // Calculate total expenses (monthly average)
    final expenses = transactions.where((t) => t.amount < 0).toList();
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount.abs());
    final monthsSpan = _calculateMonthsSpan(expenses);
    final averageMonthlyExpenses = monthsSpan > 0 ? totalExpenses / monthsSpan : 0;
    
    // Calculate savings rate
    final savingsRate = totalIncome > 0 ? (totalIncome - averageMonthlyExpenses) / totalIncome : 0;
    
    // Calculate debt-to-income ratio
    final totalDebt = loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);
    final debtToIncomeRatio = totalIncome > 0 ? totalDebt / totalIncome : 0;
    
    // Calculate emergency fund in months
    final emergencyFund = goals.where((g) => g.category == 'Emergency Fund').fold(0.0, (sum, g) => sum + g.currentAmount);
    final emergencyFundMonths = averageMonthlyExpenses > 0 ? emergencyFund / averageMonthlyExpenses : 0;
    
    // Determine overall financial health
    String overallHealth;
    List<String> recommendations = [];
    
    if (savingsRate >= AppConstants.goodSavingsRateThreshold &&
        debtToIncomeRatio <= AppConstants.goodDebtToIncomeRatio &&
        emergencyFundMonths >= AppConstants.goodEmergencyFundMonths) {
      overallHealth = 'good';
      recommendations.add('Your financial health is excellent! Consider increasing your investments for long-term growth.');
    } else if (savingsRate >= AppConstants.moderateSavingsRateThreshold &&
               debtToIncomeRatio <= AppConstants.moderateDebtToIncomeRatio &&
               emergencyFundMonths >= AppConstants.moderateEmergencyFundMonths) {
      overallHealth = 'moderate';
      
      if (savingsRate < AppConstants.goodSavingsRateThreshold) {
        recommendations.add('Try to increase your savings rate to at least ${(AppConstants.goodSavingsRateThreshold * 100).toStringAsFixed(0)}% of your income.');
      }
      
      if (debtToIncomeRatio > AppConstants.goodDebtToIncomeRatio) {
        recommendations.add('Work on reducing your debt-to-income ratio below ${(AppConstants.goodDebtToIncomeRatio * 100).toStringAsFixed(0)}%.');
      }
      
      if (emergencyFundMonths < AppConstants.goodEmergencyFundMonths) {
        recommendations.add('Build your emergency fund to cover at least ${AppConstants.goodEmergencyFundMonths.toStringAsFixed(0)} months of expenses.');
      }
    } else {
      overallHealth = 'poor';
      
      if (savingsRate < AppConstants.moderateSavingsRateThreshold) {
        recommendations.add('Increase your savings rate by reducing non-essential expenses.');
      }
      
      if (debtToIncomeRatio > AppConstants.moderateDebtToIncomeRatio) {
        recommendations.add('Focus on paying down high-interest debt as quickly as possible.');
      }
      
      if (emergencyFundMonths < AppConstants.moderateEmergencyFundMonths) {
        recommendations.add('Prioritize building an emergency fund to cover at least ${AppConstants.moderateEmergencyFundMonths.toStringAsFixed(0)} months of expenses.');
      }
    }
    
    final insight = FinancialHealthInsight(
      title: 'Your Financial Health: ${overallHealth.substring(0, 1).toUpperCase()}${overallHealth.substring(1)}',
      description: 'Based on your savings rate, debt levels, and emergency fund, your financial health is $overallHealth.',
      date: DateTime.now(),
      savingsRate: savingsRate.toDouble(),
      debtToIncomeRatio: debtToIncomeRatio.toDouble(),
      emergencyFundMonths: emergencyFundMonths.toDouble(),
      overallHealth: overallHealth,
      recommendations: recommendations,
      relevanceScore: 1.0, // Financial health is always highly relevant
    );
    
    insights.add(insight);
    
    return insights;
  }

  // Helper method to calculate months span in a list of transactions
  int _calculateMonthsSpan(List<app_models.Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    
    // Find earliest and latest dates
    DateTime? earliest;
    DateTime? latest;
    
    for (var transaction in transactions) {
      if (earliest == null || transaction.date.isBefore(earliest)) {
        earliest = transaction.date;
      }
      
      if (latest == null || transaction.date.isAfter(latest)) {
        latest = transaction.date;
      }
    }
    
    if (earliest == null || latest == null) return 0;
    
    // Calculate difference in months
    return (latest.year - earliest.year) * 12 + latest.month - earliest.month + 1;
  }
}
