import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

/// A service to manage bill reminders and upcoming payments
class BillService {
  static final BillService instance = BillService._internal();
  
  BillService._internal();
  
  final _logger = Logger('BillService');
  final _billsCollection = FirebaseFirestore.instance.collection('bills');
  
  /// Get all upcoming bills that are due within the next 30 days
  Stream<List<Map<String, dynamic>>> getUpcomingBills() {
    try {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));
      
      return _billsCollection
          .where('dueDate', isGreaterThanOrEqualTo: now)
          .where('dueDate', isLessThanOrEqualTo: thirtyDaysLater)
          .where('isPaid', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              _logger.info('No upcoming bills found');
              return <Map<String, dynamic>>[];
            }
            
            return snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              } catch (e) {
                _logger.severe('Error parsing bill document ${doc.id}: $e');
                return <String, dynamic>{};
              }
            }).toList();
          });
    } catch (e) {
      _logger.severe('Error getting upcoming bills: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }
  
  /// Mark a bill as paid
  Future<bool> markBillAsPaid(String billId) async {
    try {
      await _billsCollection.doc(billId).update({
        'isPaid': true,
        'paidDate': DateTime.now(),
      });
      
      _logger.info('Bill $billId marked as paid');
      return true;
    } catch (e) {
      _logger.severe('Error marking bill $billId as paid: $e');
      return false;
    }
  }
  
  /// Add a new bill reminder
  Future<String?> addBill({
    required String title,
    required double amount,
    required DateTime dueDate,
    required String category,
  }) async {
    try {
      final docRef = await _billsCollection.add({
        'title': title,
        'amount': amount,
        'dueDate': dueDate,
        'category': category,
        'isPaid': false,
        'createdAt': DateTime.now(),
      });
      
      _logger.info('Added new bill with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.severe('Error adding bill: $e');
      return null;
    }
  }
  
  /// Get sample bill reminders for new users
  List<Map<String, dynamic>> getSampleBills() {
    final now = DateTime.now();
    
    return [
      {
        'id': '1',
        'title': 'Rent',
        'amount': 12000.0,
        'dueDate': DateTime(now.year, now.month, 1),
        'category': 'Housing',
        'isPaid': false,
      },
      {
        'id': '2',
        'title': 'Electricity Bill',
        'amount': 2500.0,
        'dueDate': DateTime(now.year, now.month, 15),
        'category': 'Utilities',
        'isPaid': false,
      },
      {
        'id': '3',
        'title': 'Internet',
        'amount': 3000.0,
        'dueDate': DateTime(now.year, now.month, 20),
        'category': 'Utilities',
        'isPaid': false,
      },
      {
        'id': '4',
        'title': 'Car Insurance',
        'amount': 7500.0,
        'dueDate': DateTime(now.year, now.month, 10),
        'category': 'Insurance',
        'isPaid': false,
      },
    ];
  }
}
