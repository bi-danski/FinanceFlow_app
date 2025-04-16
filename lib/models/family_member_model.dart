class FamilyMember {
  final int? id;
  final String name;
  final double budget;
  final double spent;
  final String? avatarPath;

  FamilyMember({
    this.id,
    required this.name,
    required this.budget,
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
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'],
      name: map['name'],
      budget: map['budget'],
      spent: map['spent'],
      avatarPath: map['avatarPath'],
    );
  }

  double get remaining => budget - spent;
  double get percentUsed => (spent / budget) * 100;
}
