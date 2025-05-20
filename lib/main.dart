import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // Firebase initialization removed to fix web compatibility issues
  debugPrint('Running app with local authentication');

  
  // Initialize auth service
  final authService = AuthService.instance;
  await authService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
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
