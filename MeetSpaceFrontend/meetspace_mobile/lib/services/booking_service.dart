import 'dart:convert';
import '../models/booking.dart';
import 'api_service.dart';
import '../models/booking_availability.dart';

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

  Future<List<BookingAvailabilityResponse>> getAvailabilityForSpace(int spaceId) async {
  final response = await api.get("Booking/space/$spaceId/availability");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((e) => BookingAvailabilityResponse.fromJson(e))
          .toList();
    }
  }

  throw Exception("Failed to load space availability");
}

  Future<void> createBooking(Map<String, dynamic> body) async {
    final response = await api.post("Booking", body);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception("Booking failed");
    }
  }

  Future<void> cancelWithReason(int id, String reason) async {
  final response = await api.put(
    "Booking/$id/cancel",
    {"reason": reason},
  );

  if (response.statusCode != 200) {
    throw Exception("Cancel failed");
  }
}
}