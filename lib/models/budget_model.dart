class Budget {
  final int? id;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final double spent;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.spent = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'spent': spent,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      spent: map['spent'],
    );
  }

  double get remainingAmount => amount - spent;
  double get percentUsed => (spent / amount) * 100;
  
  Budget copyWith({
    int? id,
    String? category,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      spent: spent ?? this.spent,
    );
  }
}
