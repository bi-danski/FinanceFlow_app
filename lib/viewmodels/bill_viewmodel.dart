import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/bill_model.dart';


class BillViewModel extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final List<Bill> _bills = [];
  List<Bill> get bills => List.unmodifiable(_bills);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadBills(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .orderBy('dueDate')
          .get();
      _bills
        ..clear()
        ..addAll(snapshot.docs.map((d) => Bill.fromMap(d.data(), d.id)));
    } catch (e) {
      debugPrint('Error loading bills: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBill(String uid, Bill bill) async {
    try {
      final ref = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .add(bill.toMap());
      _bills.add(bill.copyWith(id: ref.id));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding bill: $e');
      return false;
    }
  }

  Future<List<Bill>> getUpcomingBills({int limit = 3}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .orderBy('dueDate')
          .limit(limit)
          .get();
      return snapshot.docs.map((d) => Bill.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('Error fetching upcoming bills: $e');
      return [];
    }
  }
}
