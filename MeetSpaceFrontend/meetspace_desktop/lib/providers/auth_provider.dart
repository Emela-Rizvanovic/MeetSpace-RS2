import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/booking.dart';
import '../models/amenity.dart';
import '../models/space.dart';
import '../models/review.dart';
import '../models/login_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../services/favorite_service.dart';
import '../services/space_service.dart';
import '../services/amenity_service.dart';
import '../services/user_service.dart';
import '../services/recommendation_service.dart';
import '../services/payment_service.dart';
import '../services/country_service.dart';
import '../services/city_service.dart';
import '../services/facility_service.dart';
import '../services/space_type_service.dart';
import '../services/amenity_category_service.dart';
import '../services/payment_method_service.dart';
import '../services/payment_status_service.dart';
import '../services/booking_status_service.dart';
import 'dart:io';

class AuthProvider with ChangeNotifier {
  UserResponse? user;

  final String baseUrl = "http://localhost:5245/api";

  String? _token;

String? get token => _token;
bool get isLoggedIn => _token != null;
bool get isAdmin => user?.roleName == "Admin";

ApiService get api => ApiService(
  baseUrl: baseUrl,
  token: _token,
);

BookingService get bookingService =>
    BookingService(api);

ReviewService get reviewService =>
    ReviewService(api);

FavoriteService get favoriteService =>
    FavoriteService(api);

SpaceService get spaceService =>
    SpaceService(api);

AmenityService get amenityService =>
    AmenityService(api);

UserService get userService =>
    UserService(
      api: api,
      baseUrl: baseUrl,
    );

RecommendationService get recommendationService =>
    RecommendationService(api);

PaymentService get paymentService =>
    PaymentService(api);

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

    print("URL → $url");
    print("REQUEST → ${request.toJson()}");
    print("STATUS → ${response.statusCode}");
    print("BODY → ${response.body}");

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
  _token = null;
  user = null;

  await _secureStorage.delete(key: 'jwt_token');
  await _secureStorage.delete(key: 'user_data');

  notifyListeners();
}

Future<void> register({
  required String firstName,
  required String lastName,
  required String email,
  required String username,
  required String password,
  required String phone,
  File? profileImage,
}) async {
  final registeredUser = await userService.register(
    firstName: firstName,
    lastName: lastName,
    email: email,
    username: username,
    password: password,
    phone: phone,
    profileImage: profileImage,
  );

  user = registeredUser;
  notifyListeners();
}

Future<ForgotPasswordResponse> forgotPassword(String email) async {
  final result = await userService.forgotPassword(email);

  return ForgotPasswordResponse.fromJson(result);
}

Future<ForgotPasswordResponse> resetPassword({
  required String email,
  required String code,
  required String newPassword,
}) async {
  final result = await userService.resetPassword(
    email: email,
    code: code,
    newPassword: newPassword,
  );

  return ForgotPasswordResponse.fromJson(result);
}

Future<List<BookingResponse>> getMyBookings() async {
  if (user == null) throw Exception("Not logged in");

  return bookingService.getMyBookings(user!.id);
}

Future<List<AmenityResponse>> getAmenities({
  String? name,
  int? amenityCategoryId,
}) {
  return amenityService.getAmenities(
    name: name,
    amenityCategoryId: amenityCategoryId,
  );
}

Future<List<SpaceResponse>> getSpaces({
  String? name,
  int? facilityId,
  int? spaceTypeId,
  double? minPrice,
  double? maxPrice,
  int? minCapacity,
  int? maxCapacity,
}) {
  return spaceService.getSpaces(
    name: name,
    facilityId: facilityId,
    spaceTypeId: spaceTypeId,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minCapacity: minCapacity,
    maxCapacity: maxCapacity,
  );
}

Future<void> addFavorite(int spaceId) async {
  if (user == null) throw Exception("Not logged in");

  return favoriteService.addFavorite(spaceId);
}

Future<void> removeFavorite(int spaceId) async {
  if (user == null) throw Exception("Not logged in");

  return favoriteService.removeFavorite(user!.id, spaceId);
}

Future<List<SpaceResponse>> getFavoriteSpaces() async {
  if (user == null) throw Exception("Not logged in");

  return favoriteService.getFavoriteSpaces(user!.id);
}

Future<void> updateProfile({
  required String firstName,
  required String lastName,
  required String username,
  required String email,
  required String phone,
  String? newPassword,
  File? profileImage,
}) async {
  if (user == null) throw Exception("Not logged in");

  final updatedUser = await userService.updateProfile(
    userId: user!.id,
    firstName: firstName,
    lastName: lastName,
    username: username,
    email: email,
    phone: phone,
    newPassword: newPassword,
    profileImage: profileImage,
  );

  user = updatedUser;
  notifyListeners();
}

Future<List<BookingResponse>> getBookingsForSpace(int spaceId) {
  return bookingService.getBookingsForSpace(spaceId);
}

Future<void> createBooking({
  required int spaceId,
  required DateTime startTime,
  required DateTime endTime,
  required List<Map<String, dynamic>> amenities,
}) async {
  if (user == null) throw Exception("Not logged in");

  final body = {
    "spaceId": spaceId,
    "bookingStatusId": 1,
    "startTime": startTime.toIso8601String(),
    "endTime": endTime.toIso8601String(),
    "amenities": amenities,
  };

  return bookingService.createBooking(body);
}

Future<List<ReviewResponse>> getReviewsBySpace(int spaceId) {
  return reviewService.getReviewsBySpace(spaceId);
}

Future<void> createReview({
  required int spaceId,
  required int rating,
  String? comment,
}) async {
  if (user == null) throw Exception("Not logged in");

  final body = {
    "spaceId": spaceId,
    "rating": rating,
    "comment": comment ?? "",
  };

  return reviewService.createReview(body);
}

Future<void> updateReview({
  required int reviewId,
  required int rating,
  String? comment,
}) async {
  if (user == null) throw Exception("Not logged in");

  final body = {
    "rating": rating,
    "comment": comment ?? "",
  };

  return reviewService.updateReview(reviewId, body);
}

Future<Map<String, dynamic>> getReviewSummary(int spaceId) {
  return reviewService.getReviewSummary(spaceId);
}

Future<void> deleteReview(int reviewId) {
  return reviewService.deleteReview(reviewId);
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

class ForgotPasswordResponse {
  final bool success;
  final String message;

  ForgotPasswordResponse({required this.success, required this.message});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}
