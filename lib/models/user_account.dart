enum UserRole { user, dietitian, admin }

class UserAccount {
  final String email;
  final String? password;
  final UserRole role;

  UserAccount({
    required this.email,
    this.password,
    this.role = UserRole.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'role': role.toString().split('.').last,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      email: json['email'],
      password: json['password'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == (json['role'] ?? 'user'),
        orElse: () => UserRole.user,
      ),
    );
  }
}
