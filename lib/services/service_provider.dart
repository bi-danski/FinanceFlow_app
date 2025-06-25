import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:logging/logging.dart';

import 'realtime_data_service.dart';
import 'auth_service.dart';
import 'transaction_service.dart';
import 'sms_parser_service.dart';
import 'sms_import_service.dart';
import '../viewmodels/transaction_viewmodel_fixed.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/goal_viewmodel.dart';
import '../viewmodels/family_viewmodel.dart';
import '../viewmodels/income_viewmodel.dart';
import '../viewmodels/loan_viewmodel.dart';
import '../viewmodels/insights_viewmodel.dart';

/// A dedicated provider for application services that properly handles lifecycle
class ServiceProvider {
  static final _logger = Logger('ServiceProvider');
  
  /// Create all application service providers
  static List<SingleChildWidget> createProviders({TransactionViewModel? transactionViewModel}) {
    _logger.info('Creating application service providers');
    
    // Get service instances
    final authService = AuthService.instance;
    final transactionService = TransactionService.instance;
    
    // Create the realtime data service (fresh instance)
    final realtimeDataService = RealtimeDataService();
    
    // Initialize SMS services
    final smsParserService = SmsParserService();
    final smsImportService = SmsImportService(
      transactionService: transactionService,
      smsParserService: smsParserService,
    );
    
    final providers = <SingleChildWidget>[
      // Core services
      ChangeNotifierProvider.value(value: authService),
      // Create realtime data service with automatic disposal by the provider
      ChangeNotifierProvider<RealtimeDataService>(
        create: (_) {
          _logger.info('Creating RealtimeDataService through provider');
          return realtimeDataService;
        },
      ),
      
      // SMS services
      Provider.value(value: smsParserService),
      ChangeNotifierProvider.value(value: smsImportService),
      
      // View models (excluding TransactionViewModel if provided)
      if (transactionViewModel == null)
        ChangeNotifierProvider(create: (_) => TransactionViewModel()),
      
      // Other view models
      ChangeNotifierProvider(create: (_) => BudgetViewModel()),
      ChangeNotifierProvider(create: (_) => GoalViewModel()),
      ChangeNotifierProvider(create: (_) => FamilyViewModel()),
      ChangeNotifierProvider(create: (_) => IncomeViewModel()),
      ChangeNotifierProvider(create: (_) => LoanViewModel()),
      ChangeNotifierProvider(create: (_) => InsightsViewModel()),
    ];
    
    return providers;
  }
}
