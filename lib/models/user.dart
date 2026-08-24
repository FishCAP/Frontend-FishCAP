class User {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? username;
  final String? profileImage;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.username,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? 'User',
      email: json['email'] ?? '',
      phoneNumber: json['phone'],
      username: json['username'],
      profileImage: json['profileImage'] ?? json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phoneNumber,
      'username': username,
      'profileImage': profileImage,
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? username,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
