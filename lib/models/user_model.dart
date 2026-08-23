/// User model representing the authenticated user and token credentials.
class User {
  final String? token;
  final String? email;
  final String? name;

  User({
    this.token,
    this.email,
    this.name,
  });
}
