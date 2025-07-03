import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  final String? id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isRecurring;
  final String? frequency; // monthly / quarterly / yearly

  Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isRecurring = false,
    this.frequency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'isRecurring': isRecurring,
      'frequency': frequency,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map, String docId) {
    return Bill(
      id: docId,
      name: map['name'],
      amount: (map['amount'] as num).toDouble(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isRecurring: map['isRecurring'] ?? false,
      frequency: map['frequency'],
    );
  }
}
