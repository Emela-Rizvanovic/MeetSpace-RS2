import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/space.dart';
import 'dart:convert';

class BookingConfirmationPage extends StatelessWidget {
  final SpaceResponse space;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final int guests;

  const BookingConfirmationPage({
    super.key,
    required this.space,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.guests,
  });

  static const bg = Color(0xFF3B3B3B);

  @override
  Widget build(BuildContext context) {
    final date =
        "${startTime.day} ${_month(startTime.month)} ${startTime.year}";

    final time =
        "${_two(startTime.hour)}:${_two(startTime.minute)} - ${_two(endTime.hour)}:${_two(endTime.minute)}";

    final qrData = jsonEncode({
  "space": space.name,
  "date": startTime.toIso8601String(),
  "end": endTime.toIso8601String(),
  "price": totalPrice,
});

    return PopScope(
  canPop: false,
  child: Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your booking is confirmed!",
                style: TextStyle(
                  color: Color(0xFFFFA500),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                space.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                space.facilityAddress ?? "",
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  space.firstImageOrEmpty,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.white54),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _row("Meeting", date),
              _divider(),
              _row("Time", time),
              _divider(),
              _row("Space capacity", "$guests people"),
              _divider(),
              _row("Payment", "${totalPrice.toStringAsFixed(2)} BAM"),

              const SizedBox(height: 30),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(
                    data: qrData,
                    size: 200,
                  ),
                ),
              ),

              const SizedBox(height: 30),

SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
    onPressed: () {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: const Text(
      "Back to home",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),

const SizedBox(height: 30),
              const SizedBox(height: 40),

              const Center(
                child: Text(
                  "MEETSPACE",
                  style: TextStyle(
                    letterSpacing: 6,
                    color: Colors.white54,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
  ),
    );
  }

  Widget _row(String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            right,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(color: Colors.white24);
  }

  String _month(int m) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[m - 1];
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
