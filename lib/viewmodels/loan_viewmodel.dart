import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/loan_model.dart';
import '../services/database_service.dart';

class LoanViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Loan> _loans = [];
  bool _isLoading = false;
  final Logger logger = Logger('LoanViewModel');

  List<Loan> get loans => _loans;
  bool get isLoading => _isLoading;

  Future<void> loadLoans() async {
    _isLoading = true;
    notifyListeners();

    try {
      _loans = await _databaseService.getLoans();
    } catch (e) {
      logger.info('Error loading loans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLoan(Loan loan) async {
    try {
      if (loan.id == null) {
        // New loan
        await _databaseService.insertLoan(loan);
      } else {
        // Update existing loan
        await _databaseService.updateLoan(loan);
      }
      await loadLoans();
      return true;
    } catch (e) {
      logger.warning('Error adding/updating loan: $e');
      return false;
    }
  }

  Future<bool> deleteLoan(int id) async {
    try {
      await _databaseService.deleteLoan(id);
      await loadLoans();
      return true;
    } catch (e) {
      logger.warning('Error deleting loan: $e');
      return false;
    }
  }

  Future<bool> recordLoanPayment(int loanId, double amount) async {
    try {
      final loan = _loans.firstWhere((loan) => loan.id == loanId);
      final updatedLoan = loan.copyWith(
        amountPaid: loan.amountPaid + amount,
        status: (loan.amountPaid + amount) >= loan.totalAmount ? 'Paid' : 'Active',
      );
      
      await _databaseService.updateLoan(updatedLoan);
      await loadLoans();
      return true;
    } catch (e) {
      logger.warning('Error recording loan payment: $e');
      return false;
    }
  }

  double getTotalLoanAmount() {
    return _loans.fold(0, (sum, loan) => sum + loan.totalAmount);
  }

  double getTotalRemainingAmount() {
    return _loans.fold(0, (sum, loan) => sum + loan.remainingAmount);
  }

  double getTotalAmountPaid() {
    return _loans.fold(0, (sum, loan) => sum + loan.amountPaid);
  }

  List<Loan> getActiveLoans() {
    return _loans.where((loan) => loan.status == 'Active').toList();
  }

  List<Loan> getOverdueLoans() {
    return _loans.where((loan) => loan.isOverdue).toList();
  }

  List<Loan> getLoansByStatus(String status) {
    return _loans.where((loan) => loan.status == status).toList();
  }

  List<Loan> getUpcomingPayments(int daysAhead) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: daysAhead));
    
    return _loans.where((loan) {
      if (loan.status != 'Active') return false;
      
      // Calculate next payment date based on frequency
      DateTime nextPayment;
      switch (loan.paymentFrequency) {
        case 'Weekly':
          final daysSinceStart = now.difference(loan.startDate).inDays;
          final weeksPassed = (daysSinceStart / 7).floor();
          nextPayment = loan.startDate.add(Duration(days: (weeksPassed + 1) * 7));
          break;
        case 'Bi-weekly':
          final daysSinceStart = now.difference(loan.startDate).inDays;
          final biWeeksPassed = (daysSinceStart / 14).floor();
          nextPayment = loan.startDate.add(Duration(days: (biWeeksPassed + 1) * 14));
          break;
        case 'Monthly':
          final monthsSinceStart = (now.year - loan.startDate.year) * 12 + 
                                  now.month - loan.startDate.month;
          nextPayment = DateTime(
            loan.startDate.year + ((loan.startDate.month + monthsSinceStart + 1) ~/ 12),
            (loan.startDate.month + monthsSinceStart + 1) % 12 == 0 ? 12 : (loan.startDate.month + monthsSinceStart + 1) % 12,
            loan.startDate.day,
          );
          break;
        default:
          return false;
      }
      
      return nextPayment.isAfter(now) && nextPayment.isBefore(cutoff);
    }).toList();
  }
}
