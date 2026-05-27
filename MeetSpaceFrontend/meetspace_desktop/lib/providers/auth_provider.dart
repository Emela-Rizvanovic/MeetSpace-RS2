import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/login_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../services/space_service.dart';
import '../services/amenity_service.dart';
import '../services/user_service.dart';
import '../services/country_service.dart';
import '../services/city_service.dart';
import '../services/facility_service.dart';
import '../services/space_type_service.dart';
import '../services/amenity_category_service.dart';
import '../services/payment_method_service.dart';
import '../services/payment_status_service.dart';
import '../services/booking_status_service.dart';
import '../constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  UserResponse? user;

  final String baseUrl =
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:5245/api',
    );

  String? _token;

String? get token => _token;
bool get isLoggedIn => _token != null;
bool get isAdmin => user?.roleName == AppRoles.admin;

ApiService get api => ApiService(
  baseUrl: baseUrl,
  token: _token,
);

BookingService get bookingService =>
    BookingService(api);

ReviewService get reviewService =>
    ReviewService(api);

SpaceService get spaceService =>
    SpaceService(api);

AmenityService get amenityService =>
    AmenityService(api);

UserService get userService =>
    UserService(
      api: api,
      baseUrl: baseUrl,
    );


    CountryService get countryService =>
    CountryService(api);

    CityService get cityService =>
    CityService(api);

    FacilityService get facilityService =>
    FacilityService(api);

    SpaceTypeService get spaceTypeService =>
    SpaceTypeService(api);

    AmenityCategoryService get amenityCategoryService =>
    AmenityCategoryService(api);

 PaymentMethodService get paymentMethodService =>
    PaymentMethodService(api);

    PaymentStatusService get paymentStatusService =>
    PaymentStatusService(api);

    BookingStatusService get bookingStatusService =>
    BookingStatusService(api);

final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

Map<String, dynamic>? _decodeToken(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  final payload = base64Url.normalize(parts[1]);
  final decoded = utf8.decode(base64Url.decode(payload));
  return jsonDecode(decoded);
}

  Future<void> login(String username, String password) async {
    await logout();
    
    final url = Uri.parse("$baseUrl/User/admin-login");

    final request = UserLoginRequest(username: username, password: password);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    
    if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body);
  final loginResponse = LoginResponse.fromJson(decoded);

  _token = loginResponse.token;
  user = loginResponse.user;

  await _secureStorage.write(key: 'jwt_token', value: _token);
await _secureStorage.write(
  key: 'user_data',
  value: jsonEncode(loginResponse.user.toJson()),
);

  notifyListeners();
} else {
      throw Exception("Invalid username or password");
    }
  }

Future<void> logout() async {
  final tokenToRevoke = _token;

  if (tokenToRevoke != null) {
    try {
      await ApiService(
        baseUrl: baseUrl,
        token: tokenToRevoke,
      ).post("User/logout", {});
    } catch (_) {
      // Local logout should still continue.
    }
  }

  _token = null;
  user = null;

  await _secureStorage.delete(key: 'jwt_token');
  await _secureStorage.delete(key: 'user_data');

  notifyListeners();
}

Future<void> tryAutoLogin() async {
  final storedToken = await _secureStorage.read(key: 'jwt_token');
  final storedUser = await _secureStorage.read(key: 'user_data');

  if (storedToken == null || storedUser == null) {
    return;
  }

  if (_isTokenExpired(storedToken)) {
    await logout();
    return;
  }

  _token = storedToken;
  user = UserResponse.fromJson(jsonDecode(storedUser));

  notifyListeners();
}

bool _isTokenExpired(String token) {
  final decoded = _decodeToken(token);
  if (decoded == null) return true;

  if (!decoded.containsKey('exp')) return true;

  final exp = decoded['exp'];
  final expiryDate =
      DateTime.fromMillisecondsSinceEpoch(exp * 1000);

  return DateTime.now().isAfter(expiryDate);
}

}

