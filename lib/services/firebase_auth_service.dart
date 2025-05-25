import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart' as app_models; // Use alias for our app's User model
import 'firestore_service.dart';

/// Firebase authentication service for FinanceFlow app
/// Handles user authentication operations using Firebase Auth
class FirebaseAuthService extends ChangeNotifier {
  // Singleton pattern
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  static FirebaseAuthService get instance => _instance;
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final _logger = Logger('FirebaseAuthService');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? _firebaseUser;
  app_models.User? _appUser;
  bool _isLoading = false;

  // Getters
  User? get firebaseUser => _firebaseUser;
  app_models.User? get currentUser => _appUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;

  /// Initialize the auth service and set up auth state listener
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Listen for auth state changes
      _auth.authStateChanges().listen(_onAuthStateChanged);
      
      // Check if we have a current user
      _firebaseUser = _auth.currentUser;
      if (_firebaseUser != null) {
        await _loadUserProfile();
      }
    } catch (e) {
      _logger.severe('Error initializing Firebase Auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle auth state changes
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    
    if (firebaseUser != null) {
      await _loadUserProfile();
    } else {
      _appUser = null;
    }
    
    notifyListeners();
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_firebaseUser == null) return;
    
    try {
      // Load user profile from Firestore
      final userDoc = await FirestoreService.instance.getUserProfile(_firebaseUser!.uid);
      
      if (userDoc.exists) {
        // User profile exists in Firestore
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Convert Firestore timestamp to DateTime
        final createdAt = userData['createdAt'] != null 
            ? (userData['createdAt'] as Timestamp).toDate() 
            : DateTime.now();
            
        final lastLogin = userData['lastLogin'] != null 
            ? (userData['lastLogin'] as Timestamp).toDate() 
            : DateTime.now();
        
        // Create app user model from Firestore data
        _appUser = app_models.User(
          id: int.tryParse(_firebaseUser!.uid) ?? 0,
          email: userData['email'] ?? _firebaseUser!.email ?? '',
          name: userData['name'] ?? _firebaseUser!.displayName ?? 'User',
          createdAt: createdAt,
          lastLogin: lastLogin,
          preferences: userData['preferences'] as Map<String, dynamic>? ?? {},
        );
        
        // Update last login time in Firestore
        await FirestoreService.instance.updateUserProfile(
          _firebaseUser!.uid, 
          {'lastLogin': FieldValue.serverTimestamp()}
        );
      } else {
        // No profile in Firestore yet, create one from Firebase user data
        _logger.info('No Firestore profile found for user ${_firebaseUser!.uid}, creating one');
        
        await FirestoreService.instance.createUserProfile(
          _firebaseUser!.uid,
          _firebaseUser!.displayName ?? _firebaseUser!.email?.split('@').first ?? 'User',
          _firebaseUser!.email ?? ''
        );
        
        // Create basic app user model
        _appUser = app_models.User(
          id: int.tryParse(_firebaseUser!.uid) ?? 0,
          email: _firebaseUser!.email ?? '',
          name: _firebaseUser!.displayName ?? _firebaseUser!.email?.split('@').first ?? 'User',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          preferences: {},
        );
      }
    } catch (e) {
      _logger.severe('Error loading user profile from Firestore: $e');
      
      // Fallback to basic profile if Firestore fails
      _appUser = app_models.User(
        id: int.tryParse(_firebaseUser!.uid) ?? 0,
        email: _firebaseUser!.email ?? '',
        name: _firebaseUser!.displayName ?? _firebaseUser!.email?.split('@').first ?? 'User',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        preferences: {},
      );
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Create the user in Firebase Auth
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
      if (result.user != null) {
        // Update display name in Firebase Auth
        await result.user!.updateDisplayName(name);
        
        // Create user profile in Firestore
        await FirestoreService.instance.createUserProfile(
          result.user!.uid, 
          name, 
          email
        );
        
        _logger.info('User registered and profile created: ${result.user!.uid}');
      }
      
      return result;
    } catch (e) {
      _logger.severe('Error during registration: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _appUser = null;
      notifyListeners();
    } catch (e) {
      _logger.severe('Error signing out: $e');
      rethrow;
    }
  }
  
  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_firebaseUser == null) throw Exception('No user logged in');
      
      // Update Firebase Auth profile
      if (displayName != null) {
        await _firebaseUser!.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await _firebaseUser!.updatePhotoURL(photoURL);
      }
      
      // Reload user to get updated info
      await _firebaseUser!.reload();
      _firebaseUser = _auth.currentUser;
      
      // Update Firestore profile
      Map<String, dynamic> updateData = {};
      
      if (displayName != null) {
        updateData['name'] = displayName;
      }
      
      if (photoURL != null) {
        updateData['photoURL'] = photoURL;
      }
      
      // Only update Firestore if we have data to update
      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        await FirestoreService.instance.updateUserProfile(
          _firebaseUser!.uid,
          updateData
        );
        _logger.info('User profile updated in Firestore: ${_firebaseUser!.uid}');
      }
      
      // Update app user model
      await _loadUserProfile();
      
      notifyListeners();
    } catch (e) {
      _logger.severe('Error updating profile: $e');
      rethrow;
    }
  }
  
  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_firebaseUser == null || _firebaseUser!.email == null) {
        throw Exception('No user logged in or email is not available');
      }
      
      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );
      
      await _firebaseUser!.reauthenticateWithCredential(credential);
      await _firebaseUser!.updatePassword(newPassword);
    } catch (e) {
      _logger.severe('Error changing password: $e');
      rethrow;
    }
  }
}
