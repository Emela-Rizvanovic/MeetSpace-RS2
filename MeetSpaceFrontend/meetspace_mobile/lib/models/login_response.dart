import 'user.dart';

class LoginResponse {
  final String token;
  final UserResponse user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      user: UserResponse.fromJson(json['user']),
    );
  }
}