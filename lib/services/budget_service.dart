import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple service that retrieves the user's monthly budget amount.
///
/// Budgets are assumed to be stored in a `budgets` collection with fields:
///   - userId  (String)
///   - month   (int 1-12)
///   - year    (int full year)
///   - amount  (double)
/// If no record exists for the requested month, `getMonthlyBudget` returns 0.
class BudgetService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  BudgetService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _budgetsCollection => _firestore.collection('budgets');

  /// Returns the budget amount for the given [month] (first day of month supplies year & month).
  Future<double> getMonthlyBudget(DateTime month) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0.0;

    try {
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: uid)
          .where('month', isEqualTo: month.month)
          .where('year', isEqualTo: month.year)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return 0.0;
      final data = snapshot.docs.first.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      return amount;
    } catch (_) {
      // Log somewhere higher up if desired
      return 0.0;
    }
  }
}
