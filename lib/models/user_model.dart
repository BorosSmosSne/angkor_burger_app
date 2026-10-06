/// User model representing the authenticated user and token credentials.
class User {
  final String? token;
  final String? email;
  final String? name;
  final String? phone;
  final String role;

  User({
    this.token,
    this.email,
    this.name,
    this.phone,
    this.role = 'customer',
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      token: json['token'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
    };
  }
}
