import 'package:flutter/material.dart';

import '../views/dashboard/dashboard_screen.dart';
import '../views/expenses/expenses_screen.dart';
import '../views/goals/goals_screen.dart';
import '../views/reports/reports_screen.dart';
import '../views/family/family_screen.dart';
import '../views/settings/settings_screen.dart';
import '../views/budgets/budgets_screen.dart';
import '../views/income/income_screen.dart';
import '../views/loans/loans_screen.dart';
import '../views/insights/insights_screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> navigateToReplacement(String routeName, {Object? arguments}) {
    return navigator!.pushReplacementNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> navigateToAndClearStack(String routeName, {Object? arguments}) {
    return navigator!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  static void goBack() {
    return navigator!.pop();
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/expenses':
        return MaterialPageRoute(builder: (_) => const ExpensesScreen());
      case '/goals':
        return MaterialPageRoute(builder: (_) => const GoalsScreen());
      case '/reports':
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case '/family':
        return MaterialPageRoute(builder: (_) => const FamilyScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/budgets':
        return MaterialPageRoute(builder: (_) => const BudgetsScreen());
      case '/income':
        return MaterialPageRoute(builder: (_) => const IncomeScreen());
      case '/loans':
        return MaterialPageRoute(builder: (_) => const LoansScreen());
      case '/insights':
        return MaterialPageRoute(builder: (_) => const InsightsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Widget getScreenByIndex(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ExpensesScreen();
      case 2:
        return const BudgetsScreen();
      case 3:
        return const GoalsScreen();
      case 4:
        return const ReportsScreen();
      case 5:
        return const FamilyScreen();
      case 6:
        return const SettingsScreen();
      case 7:
        return const IncomeScreen();
      case 8:
        return const LoansScreen();
      case 9:
        return const InsightsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
