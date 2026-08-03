class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      profileImage: json['profileImage'] ?? json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
    };
  }
}