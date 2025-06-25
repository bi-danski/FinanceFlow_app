import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'firebase_options.dart';
import 'services/connectivity_service.dart';
import 'themes/app_theme.dart';
import 'constants/app_constants.dart';
import 'services/navigation_service.dart';
import 'services/auth_service.dart';
// Screens
import 'package:financeflow_app/views/auth/sign_in_screen.dart';
import 'package:financeflow_app/views/dashboard/dashboard_screen.dart';
import 'services/transaction_service.dart';

// ViewModels
import 'package:financeflow_app/viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import 'services/service_provider.dart';
// Initialize logger
final _logger = Logger('FinanceFlowApp');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure sqflite factory based on platform
  if (kIsWeb) {
    // Use FFI web factory for web
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Initialize FFI for desktop platforms (or other non-web, non-mobile FFI targets)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Note: For mobile, sqflite typically uses its own platform channels without needing this FFI setup.
    // This 'else' block assumes you might be targeting desktop FFI.
    // If only mobile and web, the 'else' might not be needed or sqfliteFfiInit() would be removed.
  }

  // Set up logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Initialize Firebase with the generated options
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.info('Firebase initialized successfully');
    
    // Initialize Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    _logger.info('Firestore settings configured');
    
    // Initialize connectivity service
    final connectivityService = ConnectivityService.instance;
    await connectivityService.initialize();
    _logger.info('Connectivity service initialized');
    
    // Initialize authentication service
    final authService = AuthService.instance;
    await authService.initialize();
    
    // Use the ServiceProvider to create and manage app services
    _logger.info('Setting up service providers');
    
    // Create a single instance of TransactionViewModel
    final transactionViewModel = fixed.TransactionViewModel();
    
    runApp(
      MultiProvider(
        providers: [
          // Provide the TransactionService as a value
          Provider.value(
            value: TransactionService.instance,
          ),
          // Provide the TransactionViewModel as a value to ensure it's not recreated
          ChangeNotifierProvider.value(
            value: transactionViewModel,
          ),
          // Add other providers from ServiceProvider, passing the transactionViewModel to prevent duplicates
          ...ServiceProvider.createProviders(transactionViewModel: transactionViewModel),
        ],
        child: const FinanceFlowApp(),
      ),
    );
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Fallback to local authentication if Firebase fails
    debugPrint('Falling back to local authentication');
  }
}

class FinanceFlowApp extends StatelessWidget {
  const FinanceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // authService and firebaseAuthService will be accessed within the '/' route definition
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          final authService = Provider.of<AuthService>(context, listen: false);
          final bool isAuthenticated = authService.isAuthenticated;
          
          return MaterialPageRoute(
            builder: (context) => isAuthenticated 
                ? const DashboardScreen() 
                : const SignInScreen(),
          );
        }
        return NavigationService.generateRoute(settings);
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
