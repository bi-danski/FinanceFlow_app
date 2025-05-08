import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert' show json, utf8;

import '../models/user_model.dart';
import '../models/transaction_model.dart' as app_models; // Use alias for our app's Transaction model
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/insight_model.dart';
import '../models/income_source_model.dart';
import '../models/loan_model.dart';

/// Database service for FinanceFlow app
/// Handles database operations for user authentication and data storage
class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;
  DatabaseService._internal();
  
  final _logger = Logger('DatabaseService');
  User? _currentUser; // Track current logged in user
  Database? _db;

  // Get database instance
  Future<Database> get database async {
    if (_db != null) return _db!;
    await _initDatabase();
    return _db!;
  }

  // Initialize the database
  Future<void> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'finance_flow.db');
      _logger.info('Initializing database at path: $path');
      
      if (kIsWeb) {
        // For web platform, use in-memory database
        _logger.info('Using in-memory database for web platform');
        _db = await openDatabase(
          inMemoryDatabasePath,
          version: 1,
          onCreate: _onCreate,
        );
        await _initMockData();
      } else {
        _db = await openDatabase(
          path,
          version: 1,
          onCreate: _onCreate,
        );
      }
      _logger.info('Database initialized successfully');
    } catch (e) {
      _logger.severe('Error initializing database: $e');
      rethrow;
    }
  }

  // Initialize mock data for web platform
  Future<void> _initMockData() async {
    _logger.info('Initializing mock data for web platform');
    
    // Add a mock user
    try {
      await insertUser(
        User(
          id: 1,
          email: 'demo@example.com',
          name: 'Demo User',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          preferences: {},
        ),
        'password123'
      );
      _logger.info('Added mock user: demo@example.com / password123');
    } catch (e) {
      _logger.warning('Error adding mock user: $e');
    }
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    _logger.info('Creating database tables...');
    
    // Create users table with proper constraints
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        email TEXT UNIQUE,
        name TEXT,
        password_hash TEXT,
        created_at TEXT,
        last_login TEXT,
        preferences TEXT
      )
    ''');
    
    _logger.info('Database tables created successfully');
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Insert a new user or update if exists
  Future<int> insertUser(User user, String password) async {
    Database db = await database;
    final passwordHash = _hashPassword(password);
    
    // Create a properly formatted map for the database
    final Map<String, dynamic> userMap = {
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'password_hash': passwordHash,
      'created_at': user.createdAt.toIso8601String(),
      'last_login': user.lastLogin?.toIso8601String(),
      'preferences': user.preferences != null ? json.encode(user.preferences) : json.encode({}),
    };
    
    try {
      _logger.info('Inserting user: ${user.email}');
      return await db.insert(
        'users', 
        userMap,
        conflictAlgorithm: ConflictAlgorithm.replace  // Handle conflicts automatically
      );
    } catch (e) {
      _logger.severe('Error inserting user: $e');
      // Log more details for debugging
      _logger.severe('User data: $userMap');
      rethrow;
    }
  }

  // Get user by ID
  Future<User?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }
  
  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }
  
  // Authenticate user with email and password
  Future<User?> authenticateUser(String email, String password) async {
    Database db = await database;
    final passwordHash = _hashPassword(password);
    
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, passwordHash],
    );
    
    if (maps.isEmpty) return null;
    
    // Set current user on successful authentication
    _currentUser = User.fromMap(maps.first);
    return _currentUser;
  }
  
  // Get current user ID
  Future<int?> getCurrentUserId() async {
    return _currentUser?.id;
  }
  
  // Logout current user
  Future<void> logout() async {
    _currentUser = null;
  }
  
  // Update user information
  Future<int> updateUser(User user) async {
    Database db = await database;
    Map<String, dynamic> userMap = {
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'created_at': user.createdAt.toIso8601String(),
      'last_login': user.lastLogin?.toIso8601String(),
      'preferences': user.preferences != null ? json.encode(user.preferences) : null,
    };
    
    return await db.update(
      'users',
      userMap,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
  
  // Update user password
  Future<int> updateUserPassword(int userId, String newPassword) async {
    Database db = await database;
    final passwordHash = _hashPassword(newPassword);
    
    return await db.update(
      'users',
      {'password_hash': passwordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  // Delete user by ID
  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // STUB METHODS FOR INSIGHTS SERVICE
  // These are placeholder implementations to prevent compilation errors
  // They should be properly implemented when the full functionality is needed
  
  // Transaction methods
  Future<List<app_models.Transaction>> getTransactions() async {
    _logger.info('Getting all transactions');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) {
      return app_models.Transaction.fromMap(maps[i]);
    });
  }

  Future<List<app_models.Transaction>> getRecentTransactions({int limit = 10}) async {
    _logger.info('Getting recent transactions with limit: $limit');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return app_models.Transaction.fromMap(maps[i]);
    });
  }

  Future<List<app_models.Transaction>> getTransactionsByMonth(int year, int month) async {
    _logger.info('Getting transactions for $month/$year');
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return app_models.Transaction.fromMap(maps[i]);
    });
  }

  Future<int> insertTransaction(app_models.Transaction transaction) async {
    _logger.info('Inserting transaction: ${transaction.description}');
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(app_models.Transaction transaction) async {
    _logger.info('Updating transaction: ${transaction.id}');
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    _logger.info('Deleting transaction: $id');
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> processMonthlyCarryForward() async {
    _logger.info('Processing monthly carry forward');
    // This would handle any monthly budget or balance carry-forward logic
    // Implementation would depend on specific business rules
    // For now, this is just a stub
  }
  
  // Budget methods
  Future<List<Budget>> getBudgets() async {
    _logger.info('Getting all budgets');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('budgets');
    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  Future<int> insertBudget(Budget budget) async {
    _logger.info('Inserting budget: ${budget.category}');
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<int> updateBudget(Budget budget) async {
    _logger.info('Updating budget: ${budget.id}');
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    _logger.info('Deleting budget: $id');
    final db = await database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateBudgetSpent(dynamic budgetIdentifier, double amountSpent) async {
    _logger.info('Updating budget spent amount for: $budgetIdentifier, $amountSpent');
    final db = await database;
    List<Map<String, dynamic>> budget;
    
    // Handle both ID and category-based lookups
    if (budgetIdentifier is int) {
      budget = await db.query(
        'budgets',
        where: 'id = ?',
        whereArgs: [budgetIdentifier],
      );
    } else if (budgetIdentifier is String) {
      budget = await db.query(
        'budgets',
        where: 'category = ?',
        whereArgs: [budgetIdentifier],
      );
    } else {
      _logger.warning('Invalid budget identifier type: ${budgetIdentifier.runtimeType}');
      return 0;
    }
    
    if (budget.isEmpty) {
      _logger.warning('Budget not found: $budgetIdentifier');
      return 0;
    }
    
    final currentSpent = budget.first['spent'] as double? ?? 0.0;
    final newSpent = currentSpent + amountSpent;
    final budgetId = budget.first['id'] as int;
    
    return await db.update(
      'budgets',
      {'spent': newSpent},
      where: 'id = ?',
      whereArgs: [budgetId],
    );
  }
  
  // Goal methods
  Future<List<Goal>> getGoals() async {
    _logger.info('Getting all goals');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('goals');
    return List.generate(maps.length, (i) {
      return Goal.fromMap(maps[i]);
    });
  }

  Future<int> insertGoal(Goal goal) async {
    _logger.info('Inserting goal: ${goal.name}');
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<int> updateGoal(Goal goal) async {
    _logger.info('Updating goal: ${goal.id}');
    final db = await database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    _logger.info('Deleting goal: $id');
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // IncomeSource methods
  Future<List<IncomeSource>> getIncomeSources() async {
    _logger.info('Getting all income sources');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('income_sources');
    return List.generate(maps.length, (i) {
      return IncomeSource.fromMap(maps[i]);
    });
  }

  Future<int> insertIncomeSource(IncomeSource incomeSource) async {
    _logger.info('Inserting income source: ${incomeSource.name}');
    final db = await database;
    return await db.insert('income_sources', incomeSource.toMap());
  }

  Future<int> updateIncomeSource(IncomeSource incomeSource) async {
    _logger.info('Updating income source: ${incomeSource.id}');
    final db = await database;
    return await db.update(
      'income_sources',
      incomeSource.toMap(),
      where: 'id = ?',
      whereArgs: [incomeSource.id],
    );
  }

  Future<int> deleteIncomeSource(int id) async {
    _logger.info('Deleting income source: $id');
    final db = await database;
    return await db.delete(
      'income_sources',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Loan methods
  Future<List<Loan>> getLoans() async {
    _logger.info('Getting all loans');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('loans');
    return List.generate(maps.length, (i) {
      return Loan.fromMap(maps[i]);
    });
  }

  Future<int> insertLoan(Loan loan) async {
    _logger.info('Inserting loan: ${loan.name}');
    final db = await database;
    return await db.insert('loans', loan.toMap());
  }

  Future<int> updateLoan(Loan loan) async {
    _logger.info('Updating loan: ${loan.id}');
    final db = await database;
    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<int> deleteLoan(int id) async {
    _logger.info('Deleting loan: $id');
    final db = await database;
    return await db.delete(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Family methods
  Future<List<User>> getFamilyMembers() async {
    _logger.info('Getting family members');
    final db = await database;
    final userId = await getCurrentUserId();
    if (userId == null) {
      _logger.warning('No current user found');
      return [];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'primaryUserId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<int> insertFamilyMember(User familyMember, int primaryUserId) async {
    _logger.info('Inserting family member: ${familyMember.name}');
    final db = await database;
    final userMap = familyMember.toMap();
    userMap['primaryUserId'] = primaryUserId;
    return await db.insert('users', userMap);
  }

  Future<int> updateFamilyMember(User familyMember) async {
    _logger.info('Updating family member: ${familyMember.id}');
    final db = await database;
    return await db.update(
      'users',
      familyMember.toMap(),
      where: 'id = ?',
      whereArgs: [familyMember.id],
    );
  }

  Future<int> deleteFamilyMember(int id) async {
    _logger.info('Deleting family member: $id');
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Insight methods
  Future<List<Insight>> getInsights() async {
    _logger.warning('getInsights() called but not fully implemented');
    return <Insight>[]; // Explicitly typed empty list
  }
  
  Future<int> insertInsight(Insight insight) async {
    _logger.warning('insertInsight() called but not fully implemented');
    return -1; // Return -1 to indicate not implemented
  }
  
  Future<int> updateInsight(Insight insight) async {
    _logger.warning('updateInsight() called but not fully implemented');
    return -1; // Return -1 to indicate not implemented
  }
}
