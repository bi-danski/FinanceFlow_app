import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/connectivity_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/realtime_data_service.dart';
import 'viewmodels/transaction_viewmodel.dart';
import 'viewmodels/budget_viewmodel.dart';
import 'viewmodels/goal_viewmodel.dart';
import 'viewmodels/family_viewmodel.dart';
import 'viewmodels/income_viewmodel.dart';
import 'viewmodels/loan_viewmodel.dart';
import 'viewmodels/insights_viewmodel.dart';
import 'themes/app_theme.dart';
import 'constants/app_constants.dart';
import 'services/navigation_service.dart';
import 'services/auth_service.dart';
import 'views/auth/sign_in_screen.dart';
import 'views/auth/sign_up_screen.dart';
import 'views/auth/forgot_password_screen.dart';
import 'views/dashboard/dashboard_screen.dart';
import 'views/onboarding/splash_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/insights/enhanced_insights_screen.dart';
import 'views/budgets/enhanced_budget_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
    );
    debugPrint('Firestore offline persistence enabled');
    
    // Initialize ConnectivityService for offline support
    final connectivityService = ConnectivityService.instance;
    await connectivityService.initialize();
    debugPrint('Connectivity service initialized');
    
    // Initialize Firebase Auth service
    final firebaseAuthService = FirebaseAuthService.instance;
    await firebaseAuthService.initialize();
    debugPrint('Firebase Auth initialized successfully');
    
    // Initialize the RealtimeDataService for real-time data updates
    final realtimeDataService = RealtimeDataService.instance;
    // Listen for auth state changes to start/stop streams
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User is signed in, start real-time data streams
        realtimeDataService.initializeStreams();
        debugPrint('Started real-time data streams for user: ${user.uid}');
      } else {
        // User is signed out, stop streams
        realtimeDataService.dispose();
        debugPrint('Stopped real-time data streams');
      }
    });
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Fallback to local authentication if Firebase fails
    debugPrint('Falling back to local authentication');
  }

  // Initialize local auth service (temporary, will be removed in full migration)
  final authService = AuthService.instance;
  await authService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        // Add the RealtimeDataService for real-time data updates
        ChangeNotifierProvider.value(value: RealtimeDataService.instance),
        ChangeNotifierProvider(create: (_) => TransactionViewModel()),
        ChangeNotifierProvider(create: (_) => BudgetViewModel()),
        ChangeNotifierProvider(create: (_) => GoalViewModel()),
        ChangeNotifierProvider(create: (_) => FamilyViewModel()),
        ChangeNotifierProvider(create: (_) => IncomeViewModel()),
        ChangeNotifierProvider(create: (_) => LoanViewModel()),
        ChangeNotifierProvider(create: (_) => InsightsViewModel()),
      ],
      child: const FinanceFlowApp(),
    ),
  );
}

class FinanceFlowApp extends StatelessWidget {
  const FinanceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      navigatorKey: NavigationService.navigatorKey,
      home: authService.isAuthenticated ? const DashboardScreen() : const SplashScreen(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/enhanced_insights': (context) => const EnhancedInsightsScreen(),
        '/enhanced_budget': (context) => const EnhancedBudgetManagementScreen(),
      },
      onGenerateRoute: NavigationService.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
