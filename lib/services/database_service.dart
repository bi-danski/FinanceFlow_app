import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';

import '../models/transaction_model.dart' as app_models;
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/family_member_model.dart';
import '../models/income_source_model.dart';
import '../models/loan_model.dart';
import '../models/insight_model.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  final Logger _logger = Logger('DatabaseService');

  DatabaseService._internal();

  Database? _database;
  bool _initialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (kIsWeb) {
      // For web, use in-memory database with mock data
      _database = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _onCreate,
      );
      
      if (!_initialized) {
        await _initMockData();
        _initialized = true;
      }
    } else {
      try {
        // For mobile/desktop
        String databasesPath = await getDatabasesPath();
        String path = join(databasesPath, 'finance_flow.db');
        _database = await openDatabase(
          path,
          version: 1,
          onCreate: _onCreate,
        );
      } catch (e) {
        _logger.warning('Error initializing database: $e');
        // Fallback to in-memory database
        _database = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: _onCreate,
        );
      }
    }
    
    return _database!;
  }

  Future<void> _initMockData() async {
    // Initialize with some mock data for web platform
    _logger.info('Initializing mock data for web platform');
    
    // Add some mock transactions
    await insertTransaction(app_models.Transaction(
      id: 1,
      title: 'Groceries',
      amount: 85.50,
      date: DateTime.now().subtract(Duration(days: 2)),
      category: 'Food',
      description: 'Weekly grocery shopping',
      paymentMethod: 'Credit Card',
      status: 'Paid',
      paidAmount: 85.50,
    ));
    
    await insertTransaction(app_models.Transaction(
      id: 2,
      title: 'Electricity Bill',
      amount: 120.00,
      date: DateTime.now().subtract(Duration(days: 5)),
      category: 'Utilities',
      description: 'Monthly electricity bill',
      paymentMethod: 'Bank Transfer',
      status: 'Paid',
      paidAmount: 120.00,
    ));
    
    await insertTransaction(app_models.Transaction(
      id: 3,
      title: 'Internet Bill',
      amount: 60.00,
      date: DateTime.now(),
      category: 'Utilities',
      description: 'Monthly internet subscription',
      paymentMethod: 'Credit Card',
      status: 'Unpaid',
      paidAmount: 0.0,
    ));
    
    // Get current month start and end dates
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    
    // Add some mock budgets
    await insertBudget(Budget(
      id: 1,
      category: 'Food',
      amount: 500.0,
      spent: 85.50,
      startDate: monthStart,
      endDate: monthEnd,
    ));
    
    await insertBudget(Budget(
      id: 2,
      category: 'Utilities',
      amount: 300.0,
      spent: 120.0,
      startDate: monthStart,
      endDate: monthEnd,
    ));
    
    // Add some mock insights
    await insertInsight(Insight(
      id: 1,
      title: 'Budget Alert',
      description: 'You\'ve spent 80% of your Food budget this month.',
      type: 'budget_alert',
      date: DateTime.now().subtract(Duration(days: 1)),
      isRead: false,
      isDismissed: false,
      data: {'category': 'Food', 'percentage': 80},
    ));
    
    await insertInsight(Insight(
      id: 2,
      title: 'Spending Pattern',
      description: 'Your utility expenses have increased by 15% compared to last month.',
      type: 'spending_pattern',
      date: DateTime.now().subtract(Duration(days: 3)),
      isRead: true,
      isDismissed: false,
      data: {'category': 'Utilities', 'percentage': 15},
    ));
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        date TEXT,
        category TEXT,
        description TEXT,
        paymentMethod TEXT,
        status TEXT,
        paidAmount REAL,
        isCarriedForward INTEGER,
        originalTransactionId INTEGER
      )
    ''');

    // Create budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        amount REAL,
        startDate TEXT,
        endDate TEXT,
        isRecurring INTEGER
      )
    ''');

    // Create goals table
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        targetAmount REAL,
        currentAmount REAL,
        deadline TEXT,
        category TEXT,
        isCompleted INTEGER
      )
    ''');

    // Create family members table
    await db.execute('''
      CREATE TABLE family_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        relationship TEXT,
        contributionAmount REAL,
        contributionFrequency TEXT
      )
    ''');

    // Create income sources table
    await db.execute('''
      CREATE TABLE income_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        amount REAL,
        frequency TEXT,
        nextDate TEXT,
        sourceType TEXT,
        isActive INTEGER
      )
    ''');

    // Create loans table
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        amount REAL,
        interestRate REAL,
        startDate TEXT,
        endDate TEXT,
        paymentAmount REAL,
        paymentFrequency TEXT,
        remainingAmount REAL,
        loanType TEXT,
        status TEXT
      )
    ''');

    // Create insights table
    await db.execute('''
      CREATE TABLE insights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        type TEXT,
        date TEXT,
        isRead INTEGER,
        isDismissed INTEGER,
        relevanceScore REAL,
        data TEXT
      )
    ''');
  }

  // Transaction methods
  Future<int> insertTransaction(app_models.Transaction transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<app_models.Transaction>> getTransactions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) => app_models.Transaction.fromMap(maps[i]));
  }

  Future<List<app_models.Transaction>> getRecentTransactions(int limit) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => app_models.Transaction.fromMap(maps[i]));
  }

  Future<int> updateTransaction(app_models.Transaction transaction) async {
    Database db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<app_models.Transaction>> getTransactionsByMonth(DateTime month) async {
    Database db = await database;

    // Calculate the first and last day of the month
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        firstDay.toIso8601String(),
        lastDay.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => app_models.Transaction.fromMap(maps[i]));
  }

  Future<List<app_models.Transaction>> getUnpaidTransactions() async {
    Database db = await database;

    List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: "status IN ('Unpaid', 'Partial')",
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => app_models.Transaction.fromMap(maps[i]));
  }

  Future<List<app_models.Transaction>> getCarriedForwardTransactions() async {
    Database db = await database;

    List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'isCarriedForward = 1',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => app_models.Transaction.fromMap(maps[i]));
  }

  Future<void> processMonthlyCarryForward(DateTime fromMonth, DateTime toMonth) async {
    // Get all unpaid or partially paid transactions from the previous month
    final firstDay = DateTime(fromMonth.year, fromMonth.month, 1);
    final lastDay = DateTime(fromMonth.year, fromMonth.month + 1, 0);

    Database db = await database;

    List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: "date BETWEEN ? AND ? AND status IN ('Unpaid', 'Partial')",
      whereArgs: [
        firstDay.toIso8601String(),
        lastDay.toIso8601String(),
      ],
    );

    final transactions = List.generate(
      maps.length,
      (i) => app_models.Transaction.fromMap(maps[i]),
    );

    // Process each transaction
    for (final transaction in transactions) {
      // Check if this category should be carried forward
      if (AppConstants.carryForwardCategories.contains(transaction.category)) {
        // Create a new transaction for the next month
        final newDate = DateTime(toMonth.year, toMonth.month, 1);
        final carriedTransaction = transaction.createCarryForwardCopy(newDate);

        // Insert the carried forward transaction
        await insertTransaction(carriedTransaction);

        // Update the original transaction to mark it as processed
        final updatedTransaction = transaction.copyWith(
          status: transaction.status, // Keep the original status
        );

        await updateTransaction(updatedTransaction);
      } else if (AppConstants.resetCategories.contains(transaction.category)) {
        // Categories that should be reset and not carried forward
        // Just mark them as processed
        final updatedTransaction = transaction.copyWith(
          status: 'Unpaid', // Reset to unpaid for the new month
          paidAmount: 0.0, // Reset paid amount
        );

        await updateTransaction(updatedTransaction);
      }
    }
  }

  // Budget methods
  Future<int> insertBudget(Budget budget) async {
    Database db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<Budget>> getBudgets() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('budgets');
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<int> updateBudget(Budget budget) async {
    Database db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    Database db = await database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Budget?> getBudgetByCategory(String category) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'category = ?',
      whereArgs: [category],
    );

    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateBudgetSpent(String category, double amount) async {
    Database db = await database;
    Budget? budget = await getBudgetByCategory(category);

    if (budget != null) {
      double newSpent = budget.spent + amount;
      await db.update(
        'budgets',
        {'spent': newSpent},
        where: 'id = ?',
        whereArgs: [budget.id],
      );
    }
  }

  // Goal methods
  Future<int> insertGoal(Goal goal) async {
    Database db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getGoals() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('goals');
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  Future<int> updateGoal(Goal goal) async {
    Database db = await database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // Family member methods
  Future<int> insertFamilyMember(FamilyMember member) async {
    Database db = await database;
    return await db.insert('family_members', member.toMap());
  }

  Future<List<FamilyMember>> getFamilyMembers() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('family_members');
    return List.generate(maps.length, (i) => FamilyMember.fromMap(maps[i]));
  }

  Future<int> updateFamilyMember(FamilyMember member) async {
    Database db = await database;
    return await db.update(
      'family_members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  // Income source methods
  Future<int> insertIncomeSource(IncomeSource incomeSource) async {
    Database db = await database;
    return await db.insert('income_sources', incomeSource.toMap());
  }

  Future<List<IncomeSource>> getIncomeSources() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('income_sources');
    return List.generate(maps.length, (i) => IncomeSource.fromMap(maps[i]));
  }

  Future<int> updateIncomeSource(IncomeSource incomeSource) async {
    Database db = await database;
    return await db.update(
      'income_sources',
      incomeSource.toMap(),
      where: 'id = ?',
      whereArgs: [incomeSource.id],
    );
  }

  Future<int> deleteIncomeSource(int id) async {
    Database db = await database;
    return await db.delete(
      'income_sources',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<IncomeSource>> getIncomeSourcesByType(String type) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'income_sources',
      where: 'type = ?',
      whereArgs: [type],
    );
    return List.generate(maps.length, (i) => IncomeSource.fromMap(maps[i]));
  }

  Future<List<IncomeSource>> getRecentIncomeSources(int limit) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'income_sources',
      orderBy: 'date DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => IncomeSource.fromMap(maps[i]));
  }

  // Loan methods
  Future<int> insertLoan(Loan loan) async {
    Database db = await database;
    return await db.insert('loans', loan.toMap());
  }

  Future<List<Loan>> getLoans() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('loans');
    return List.generate(maps.length, (i) => Loan.fromMap(maps[i]));
  }

  Future<int> updateLoan(Loan loan) async {
    Database db = await database;
    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<int> deleteLoan(int id) async {
    Database db = await database;
    return await db.delete(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Loan>> getLoansByStatus(String status) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'status = ?',
      whereArgs: [status],
    );
    return List.generate(maps.length, (i) => Loan.fromMap(maps[i]));
  }

  // Insight methods
  Future<int> insertInsight(Insight insight) async {
    Database db = await database;
    return await db.insert('insights', insight.toMap());
  }

  Future<List<Insight>> getInsights() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'insights',
      where: 'isDismissed = 0',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Insight.fromMap(maps[i]));
  }

  Future<List<Insight>> getRecentInsights(int limit) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'insights',
      where: 'isDismissed = 0',
      orderBy: 'date DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Insight.fromMap(maps[i]));
  }

  Future<List<Insight>> getUnreadInsights() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'insights',
      where: 'isRead = 0 AND isDismissed = 0',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Insight.fromMap(maps[i]));
  }

  Future<int> updateInsight(Insight insight) async {
    Database db = await database;
    return await db.update(
      'insights',
      insight.toMap(),
      where: 'id = ?',
      whereArgs: [insight.id],
    );
  }

  Future<int> deleteInsight(int id) async {
    Database db = await database;
    return await db.delete(
      'insights',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllInsights() async {
    Database db = await database;
    return await db.delete('insights');
  }
}
