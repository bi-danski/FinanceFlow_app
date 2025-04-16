class IncomeSource {
  final int? id;
  final String name;
  final String type; // Salary, Side Hustle, Loan, Grant, etc.
  final double amount;
  final DateTime date;
  final bool isRecurring;
  final String frequency; // Monthly, Weekly, One-time, etc.
  final String? notes;

  IncomeSource({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.date,
    this.isRecurring = false,
    this.frequency = 'One-time',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'frequency': frequency,
      'notes': notes,
    };
  }

  factory IncomeSource.fromMap(Map<String, dynamic> map) {
    return IncomeSource(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isRecurring: map['isRecurring'] == 1,
      frequency: map['frequency'],
      notes: map['notes'],
    );
  }

  // For Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'isRecurring': isRecurring,
      'frequency': frequency,
      'notes': notes,
    };
  }

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    return IncomeSource(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      isRecurring: json['isRecurring'],
      frequency: json['frequency'],
      notes: json['notes'],
    );
  }
}
