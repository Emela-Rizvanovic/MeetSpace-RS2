import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/space.dart';
import '../providers/auth_provider.dart';

class PaymentPage extends StatefulWidget {
  final SpaceResponse space;
  final DateTime selectedDate;
  final DateTime startTime;
  final DateTime endTime;
  final Map<int, bool> selectedAmenities;

  const PaymentPage({
    super.key,
    required this.space,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.selectedAmenities,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);

  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);

    try {
      final auth = context.read<AuthProvider>();

      await auth.createBooking(
        spaceId: widget.space.id,
        startTime: widget.startTime,
        endTime: widget.endTime,
        amenities: widget.selectedAmenities.entries
            .where((e) => e.value)
            .map((e) => {
                  "amenityId": e.key,
                  "quantity": 1,
                })
            .toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment successful!")),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Center(
          child: _processing
              ? const CircularProgressIndicator(color: Colors.white)
              : SizedBox(
                  width: 250,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Pay",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}