class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? description;
  final String? paymentMethod;
  final String status; // 'Paid', 'Unpaid', 'Partial'
  final double? paidAmount; // For partial payments
  final bool isCarriedForward; // Indicates if this was carried forward from previous month
  final int? originalTransactionId; // Reference to the original transaction if carried forward

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    this.paymentMethod,
    this.status = 'Unpaid',
    this.paidAmount = 0.0,
    this.isCarriedForward = false,
    this.originalTransactionId,
  });

  double get remainingAmount => amount - (paidAmount ?? 0.0);
  
  bool get isPaid => status == 'Paid';
  
  bool get isUnpaid => status == 'Unpaid';
  
  bool get isPartiallyPaid => status == 'Partial';
  
  bool get shouldCarryForward {
    // Only carry forward if unpaid or partially paid and category is in carry forward list
    if (isPaid) return false;
    
    // Check if this category should be carried forward
    // This will be implemented with AppConstants.carryForwardCategories
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'paymentMethod': paymentMethod,
      'status': status,
      'paidAmount': paidAmount,
      'isCarriedForward': isCarriedForward ? 1 : 0,
      'originalTransactionId': originalTransactionId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      description: map['description'],
      paymentMethod: map['paymentMethod'],
      status: map['status'] ?? 'Unpaid',
      paidAmount: map['paidAmount'],
      isCarriedForward: map['isCarriedForward'] == 1,
      originalTransactionId: map['originalTransactionId'],
    );
  }

  // Create a copy of this transaction for the next month (carry forward)
  Transaction createCarryForwardCopy(DateTime newDate) {
    return Transaction(
      title: title,
      amount: remainingAmount, // Only carry forward the remaining amount
      date: newDate,
      category: category,
      description: description,
      paymentMethod: paymentMethod,
      status: 'Unpaid', // Reset status to unpaid
      paidAmount: 0.0, // Reset paid amount
      isCarriedForward: true,
      originalTransactionId: id,
    );
  }

  // Create a copy with updated values
  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? description,
    String? paymentMethod,
    String? status,
    double? paidAmount,
    bool? isCarriedForward,
    int? originalTransactionId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      isCarriedForward: isCarriedForward ?? this.isCarriedForward,
      originalTransactionId: originalTransactionId ?? this.originalTransactionId,
    );
  }
}
