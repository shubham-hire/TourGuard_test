class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? userType; // 'indian' or 'international'
  final String? nationality;
  final String? documentUrl;
  final String? profilePhotoUrl; // Profile picture URL
  final String? hashId;
  final String? blockchainHashId; // Ethereum blockchain hash ID

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.userType,
    this.nationality,
    this.documentUrl,
    this.profilePhotoUrl,
    this.hashId,
    this.blockchainHashId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['userType'],
      nationality: json['nationality'],
      documentUrl: json['documentUrl'],
      profilePhotoUrl: json['profilePhotoUrl'],
      hashId: json['hashId'],
      blockchainHashId: json['blockchainHashId'],
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
      'profilePhotoUrl': profilePhotoUrl,
      'hashId': hashId,
      'blockchainHashId': blockchainHashId,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? userType,
    String? nationality,
    String? documentUrl,
    String? profilePhotoUrl,
    String? hashId,
    String? blockchainHashId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      nationality: nationality ?? this.nationality,
      documentUrl: documentUrl ?? this.documentUrl,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      hashId: hashId ?? this.hashId,
      blockchainHashId: blockchainHashId ?? this.blockchainHashId,
    );
  }
}
