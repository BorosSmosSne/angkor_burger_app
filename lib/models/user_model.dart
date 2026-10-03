/// User model representing the authenticated user and token credentials.
class User {
  final String? token;
  final String? email;
  final String? name;
  final String? phone;

  User({
    this.token,
    this.email,
    this.name,
    this.phone,
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      token: json['token'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'], // 👈 3. Add to fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'email': email,
      'name': name,
      'phone': phone, // 👈 4. Add to toJson
    };
  }
}
