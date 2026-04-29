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
   final String roleName;

   final bool isActive;
final DateTime? createdAt;
final DateTime? updatedAt;

  UserResponse({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,

    this.phoneNumber,
    required this.roleName,

    this.createdAt,
    required this.isActive,
    this.updatedAt

  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImageUrl: json['profileImageUrl'],

      phoneNumber: json['phoneNumber'],
      roleName: json['roleName'],

      isActive: json['isActive'] ?? false,
createdAt: json['createdAt'] != null
    ? DateTime.parse(json['createdAt'])
    : null,
updatedAt: json['updatedAt'] != null
    ? DateTime.parse(json['updatedAt'])
    : null,

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


UserResponse copyWith({
  String? firstName,
  String? lastName,
  String? email,
  String? roleName,
  bool? isActive,
}) {
  return UserResponse(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    username: username,
    email: email ?? this.email,
    phoneNumber: phoneNumber,
    roleName: roleName ?? this.roleName,
    isActive: isActive ?? this.isActive,
    profileImageUrl: profileImageUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
}

