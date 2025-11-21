class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userType; // 'indian' or 'international'
  final String? nationality;
  final String? documentUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.nationality,
    this.documentUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      userType: json['userType'],
      nationality: json['nationality'],
      documentUrl: json['documentUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'nationality': nationality,
      'documentUrl': documentUrl,
    };
  }
}
