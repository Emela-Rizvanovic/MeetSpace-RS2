class UserLoginRequest {
  final String username;
  final String password;

  UserLoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class UserResponse {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final String? phoneNumber;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    this.phoneNumber
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImageUrl: json['profileImageUrl'],
      phoneNumber: json['phoneNumber']
    );
  }
}

