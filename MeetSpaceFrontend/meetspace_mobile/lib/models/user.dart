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
<<<<<<< Updated upstream
=======
  final String? phoneNumber;
   final String roleName;
>>>>>>> Stashed changes

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
<<<<<<< Updated upstream
=======
    this.phoneNumber,
    required this.roleName,
>>>>>>> Stashed changes
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImageUrl: json['profileImageUrl'],
<<<<<<< Updated upstream
=======
      phoneNumber: json['phoneNumber'],
      roleName: json['roleName'],
>>>>>>> Stashed changes
    );
  }

  Map<String, dynamic> toJson() {
  return {
    'id': id,
    'roleName': roleName,
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'email': email,
    'phoneNumber': phoneNumber,
    'profileImageUrl': profileImageUrl,
  };
}
}

