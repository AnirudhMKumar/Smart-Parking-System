class User {
  final int id;
  final String email;
  final String? fullName;
  final String? phone;
  final DateTime createdAt;

  User({required this.id, required this.email, this.fullName, this.phone, required this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
