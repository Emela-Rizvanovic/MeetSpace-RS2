import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class AuthProvider with ChangeNotifier {
  UserResponse? user;

  final String baseUrl = "http://10.0.2.2:5245/api";  
  // 10.0.2.2 = localhost za Android emulator

  Future<void> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/User/login");

    final request = UserLoginRequest(username: username, password: password);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    print("URL → $url");
    print("REQUEST → ${request.toJson()}");
    print("STATUS → ${response.statusCode}");
    print("BODY → ${response.body}");

    if (response.statusCode == 200) {
      user = UserResponse.fromJson(jsonDecode(response.body));
      notifyListeners();
    } else {
      throw Exception("Invalid username or password");
    }
  }

   Future<void> register({
  required String firstName,
  required String lastName,
  required String email,
  required String username,
  required String password,
  required String phone,
  XFile? profileImage, // optional
}) async {
  var uri = Uri.parse('$baseUrl/User/register');

  var request = http.MultipartRequest('POST', uri);

  request.fields['FirstName'] = firstName;
  request.fields['LastName'] = lastName;
  request.fields['Email'] = email;
  request.fields['Username'] = username;
  request.fields['Password'] = password;
  request.fields['PhoneNumber'] = phone;
  request.fields['RoleId'] = '2';

  // ⚠️ Backend expects: ProfileImageUrl
  if (profileImage != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'ProfileImageUrl',                       // <-- MUST MATCH BACKEND NAME
        profileImage.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
  }

  var response = await request.send();
  var responseString = await response.stream.bytesToString();

  print("REGISTER STATUS → ${response.statusCode}");
  print("REGISTER RESPONSE → $responseString");

  if (response.statusCode == 201) {
    user = UserResponse.fromJson(jsonDecode(responseString));
    notifyListeners();
  } else {
    throw Exception(responseString);
  }
}

}
