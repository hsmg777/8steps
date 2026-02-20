class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: (json['role'] as String?) ?? 'USER',
      firstName: (json['firstName'] as String?)?.trim(),
      lastName: (json['lastName'] as String?)?.trim(),
    );
  }
}
