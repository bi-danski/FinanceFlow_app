class FamilyMember {
  final int? id;
  final String name;
  final double budget;
  final double spent;
  final String role;
  final String? avatarPath;

  FamilyMember({
    this.id,
    required this.name,
    required this.budget,
    this.role = 'child',
    this.spent = 0.0,
    this.avatarPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'budget': budget,
      'spent': spent,
      'avatarPath': avatarPath,
      'role': role,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      budget: map['budget'],
      spent: map['spent'],
      role: (map['role'] ?? 'child') as String,
      avatarPath: map['avatarPath'],
    );
  }

  double get remaining => budget - spent;

  // Role-based budget presets
  static const Map<String, double> rolePresets = {
    'parent': 1000.0,
    'child': 200.0,
  };

  // Get suggested budget based on role
  double get suggestedBudget => rolePresets[role] ?? 200.0;
  double get percentUsed => (spent / budget) * 100;

  FamilyMember copyWith({
    int? id,
    String? name,
    double? budget,
    double? spent,
    String? role,
    String? avatarPath,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
