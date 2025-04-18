import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/income_source_model.dart';
import '../services/database_service.dart';

class IncomeViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<IncomeSource> _incomeSources = [];
  bool _isLoading = false;
  final Logger logger = Logger('IncomeViewModel');

  List<IncomeSource> get incomeSources => _incomeSources;
  bool get isLoading => _isLoading;

  Future<void> loadIncomeSources() async {
    _isLoading = true;
    notifyListeners();

    try {
      _incomeSources = await _databaseService.getIncomeSources();
    } catch (e) {
      logger.info('Error loading income sources: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addIncomeSource(IncomeSource incomeSource) async {
    try {
      if (incomeSource.id == null) {
        // New income source
        await _databaseService.insertIncomeSource(incomeSource);
      } else {
        // Update existing income source
        await _databaseService.updateIncomeSource(incomeSource);
      }
      await loadIncomeSources();
      return true;
    } catch (e) {
      logger.info('Error adding/updating income source: $e');
      return false;
    }
  }

  Future<bool> deleteIncomeSource(int id) async {
    try {
      await _databaseService.deleteIncomeSource(id);
      await loadIncomeSources();
      return true;
    } catch (e) {
      logger.warning('Error deleting income source: $e');
      return false;
    }
  }

  double getTotalIncome() {
    return _incomeSources.fold(0, (sum, source) => sum + source.amount);
  }

  double getTotalIncomeByType(String type) {
    return _incomeSources
        .where((source) => source.type == type)
        .fold(0, (sum, source) => sum + source.amount);
  }

  List<IncomeSource> getRecurringIncome() {
    return _incomeSources.where((source) => source.isRecurring).toList();
  }

  List<IncomeSource> getIncomeByType(String type) {
    return _incomeSources.where((source) => source.type == type).toList();
  }

  List<IncomeSource> getRecentIncome(int count) {
    final sortedSources = List<IncomeSource>.from(_incomeSources)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedSources.take(count).toList();
  }

  Map<String, double> getIncomeDistribution() {
    final distribution = <String, double>{};
    
    for (final source in _incomeSources) {
      if (distribution.containsKey(source.type)) {
        distribution[source.type] = distribution[source.type]! + source.amount;
      } else {
        distribution[source.type] = source.amount;
      }
    }
    
    return distribution;
  }
}
