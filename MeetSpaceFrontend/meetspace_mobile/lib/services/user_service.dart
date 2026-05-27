import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  final ApiService api;
  final String baseUrl;

  UserService({
    required this.api,
    required this.baseUrl,
  });

  Future<UserResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
    required String phone,
    XFile? profileImage,
  }) async {
    var uri = Uri.parse('$baseUrl/User/register');
    var request = http.MultipartRequest('POST', uri);
    
    request.fields['FirstName'] = firstName;
    request.fields['LastName'] = lastName;
    request.fields['Email'] = email;
    request.fields['Username'] = username;
    request.fields['Password'] = password;
    request.fields['PhoneNumber'] = phone;

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'ProfileImageUrl',
          profileImage.path,
          contentType: _imageContentType(profileImage.path),
        ),
      );
    }

    var response = await request.send();
    var responseString = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return UserResponse.fromJson(jsonDecode(responseString));
    }

    throw Exception(responseString);
  }

  Future<UserResponse> updateProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    String? currentPassword,
    String? newPassword,
    XFile? profileImage,
  }) async {
    var uri = Uri.parse('$baseUrl/User/$userId');
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] =
    'Bearer ${api.token}';

    request.fields['FirstName'] = firstName;
    request.fields['LastName'] = lastName;
    request.fields['Username'] = username;
    request.fields['Email'] = email;
    request.fields['PhoneNumber'] = phone;

    if (currentPassword != null && currentPassword.trim().isNotEmpty) {
  request.fields['CurrentPassword'] = currentPassword.trim();
}

    if (newPassword != null && newPassword.trim().isNotEmpty) {
      request.fields['Password'] = newPassword.trim();
    }

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'ProfileImageUrl',
          profileImage.path,
          contentType: _imageContentType(profileImage.path),
        ),
      );
    }

    var response = await request.send();
    var responseString = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return UserResponse.fromJson(jsonDecode(responseString));
    }

    throw Exception("Failed to update profile");
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await api.post(
      "User/forgot-password",
      {'email': email},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Forgot password failed");
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await api.post(
      "User/reset-password",
      {
        'email': email,
        'resetCode': code,
        'newPassword': newPassword,
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 400) {
      return jsonDecode(response.body);
    }

    throw Exception("Reset password failed");
  }

  MediaType _imageContentType(String path) {
  final lower = path.toLowerCase();

  if (lower.endsWith('.png')) {
    return MediaType('image', 'png');
  }

  if (lower.endsWith('.webp')) {
    return MediaType('image', 'webp');
  }

  return MediaType('image', 'jpeg');
}
}