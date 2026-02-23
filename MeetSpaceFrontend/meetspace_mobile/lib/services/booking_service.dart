import 'dart:convert';
import '../models/booking.dart';
import 'api_service.dart';

class BookingService {
  final ApiService api;

  BookingService(this.api);

  Future<List<BookingResponse>> getMyBookings(int userId) async {
    final response = await api.get("Booking/user/$userId");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => BookingResponse.fromJson(e))
            .toList();
      }
    }

    throw Exception("Failed to load bookings");
  }

  Future<List<BookingResponse>> getBookingsForSpace(int spaceId) async {
    final response = await api.get("Booking/space/$spaceId");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => BookingResponse.fromJson(e))
            .toList();
      }
    }

    throw Exception("Failed to load space bookings");
  }

  Future<void> createBooking(Map<String, dynamic> body) async {
    final response = await api.post("Booking", body);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception("Booking failed");
    }
  }
}