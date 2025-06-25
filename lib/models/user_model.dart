/// User model for the FinanceFlow app
class User {
  final int id;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? preferences;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.lastLogin,
    this.preferences,
    this.profileImageUrl,
  });

  /// Convert User to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'preferences': preferences,
      'profile_image_url': profileImageUrl,
    };
  }

  /// Create a User from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      lastLogin: map['last_login'] != null ? DateTime.parse(map['last_login']) : null,
      preferences: map['preferences'],
      profileImageUrl: map['profile_image_url'],
    );
  }

  /// Create a copy of this User with the given field values updated
  User copyWith({
    int? id,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? preferences,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      preferences: preferences ?? this.preferences,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
