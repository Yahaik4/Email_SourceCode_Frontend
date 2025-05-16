class UserModel {
  final String id;
  final String username;
  final String email;
  final String password;
  final String? avatar;
  final String? phoneNumber;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.avatar,
    this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      avatar: json['avatar'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'avatar': avatar,
      'phoneNumber': phoneNumber,
    };
  }
} 