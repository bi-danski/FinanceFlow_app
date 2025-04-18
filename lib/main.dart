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

void main() {
  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: '/dashboard',
      onGenerateRoute: NavigationService.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
