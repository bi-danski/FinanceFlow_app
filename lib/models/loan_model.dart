class Loan {
  final int? id;
  final String name;
  final double totalAmount;
  final double amountPaid;
  final double interestRate;
  final DateTime startDate;
  final DateTime dueDate;
  final String lender;
  final String status; // Active, Paid, Defaulted
  final String paymentFrequency; // Monthly, Weekly, Bi-weekly
  final double installmentAmount;
  final String? notes;

  Loan({
    this.id,
    required this.name,
    required this.totalAmount,
    this.amountPaid = 0.0,
    required this.interestRate,
    required this.startDate,
    required this.dueDate,
    required this.lender,
    this.status = 'Active',
    required this.paymentFrequency,
    required this.installmentAmount,
    this.notes,
  });

  double get remainingAmount => totalAmount - amountPaid;
  
  double get percentPaid => (amountPaid / totalAmount) * 100;

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status == 'Active';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'lender': lender,
      'status': status,
      'paymentFrequency': paymentFrequency,
      'installmentAmount': installmentAmount,
      'notes': notes,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'],
      name: map['name'],
      totalAmount: map['totalAmount'],
      amountPaid: map['amountPaid'],
      interestRate: map['interestRate'],
      startDate: DateTime.parse(map['startDate']),
      dueDate: DateTime.parse(map['dueDate']),
      lender: map['lender'],
      status: map['status'],
      paymentFrequency: map['paymentFrequency'],
      installmentAmount: map['installmentAmount'],
      notes: map['notes'],
    );
  }

  // For Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'lender': lender,
      'status': status,
      'paymentFrequency': paymentFrequency,
      'installmentAmount': installmentAmount,
      'notes': notes,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      name: json['name'],
      totalAmount: json['totalAmount'],
      amountPaid: json['amountPaid'],
      interestRate: json['interestRate'],
      startDate: DateTime.parse(json['startDate']),
      dueDate: DateTime.parse(json['dueDate']),
      lender: json['lender'],
      status: json['status'],
      paymentFrequency: json['paymentFrequency'],
      installmentAmount: json['installmentAmount'],
      notes: json['notes'],
    );
  }

  Loan copyWith({
    int? id,
    String? name,
    double? totalAmount,
    double? amountPaid,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    String? lender,
    String? status,
    String? paymentFrequency,
    double? installmentAmount,
    String? notes,
  }) {
    return Loan(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      lender: lender ?? this.lender,
      status: status ?? this.status,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      notes: notes ?? this.notes,
    );
  }
}
