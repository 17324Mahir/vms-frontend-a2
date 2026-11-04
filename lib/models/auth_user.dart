/// Minimal summary of an authenticated user.
class AuthUser {
  final String email;

  const AuthUser({required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
