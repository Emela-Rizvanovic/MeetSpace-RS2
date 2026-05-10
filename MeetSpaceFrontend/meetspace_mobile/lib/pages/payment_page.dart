import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/space.dart';
import 'paypal_webview.dart';
import 'booking_confirmation_page.dart';
import '../models/amenity.dart';

class PaymentPage extends StatefulWidget {
  final SpaceResponse space;
  final DateTime startTime;
  final DateTime endTime;
  final Map<int, bool> selectedAmenities;
  final List<AmenityResponse> amenities;

  const PaymentPage({
    super.key,
    required this.space,
    required this.startTime,
    required this.endTime,
    required this.selectedAmenities,
    required this.amenities,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const bg = Color(0xFF3B3B3B);

  CardFieldInputDetails? _card;
  final _nameController = TextEditingController();

  bool _loading = false;

  String _method = "card"; 

  // ---------------- STRIPE ----------------
  Future<void> _pay() async {
 
    if (_card == null || !_card!.complete) {
      _snack("Enter valid card");
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();

    final hours =
    widget.endTime.difference(widget.startTime).inHours;

double amount = hours * widget.space.pricePerHour;

// ADD AMENITIES
for (var amenity in widget.amenities) {
  if (widget.selectedAmenities[amenity.id] == true) {
    amount += amenity.price;
  }
}

      final intent =
          await auth.paymentService.createPaymentIntent(amount);

      final clientSecret = intent["clientSecret"];
      final intentId = intent["paymentIntentId"];

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: _nameController.text,
            ),
          ),
        ),
      );

      final amenities = widget.selectedAmenities.entries
          .where((e) => e.value)
          .map((e) => {
                "amenityId": e.key,
                "quantity": 1,
              })
          .toList();

      await auth.paymentService.confirmPayment(
        spaceId: widget.space.id,
        startTime: widget.startTime,
        endTime: widget.endTime,
        paymentIntentId: intentId,
        amenities: amenities,
      );

     if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => BookingConfirmationPage(
      space: widget.space,
      startTime: widget.startTime,
      endTime: widget.endTime,
      totalPrice: amount,
      guests: widget.space.capacity,
    ),
  ),
);
    } catch (e) {
      if (!mounted) return;
      _snack("Payment failed");
      print(e);
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ---------------- PAYPAL ----------------
Future<void> _payWithPaypal() async {
  setState(() => _loading = true);

  try {
    final auth = context.read<AuthProvider>();

   final hours =
    widget.endTime.difference(widget.startTime).inHours;

double amount = hours * widget.space.pricePerHour;

// ADD AMENITIES
for (var amenity in widget.amenities) {
  if (widget.selectedAmenities[amenity.id] == true) {
    amount += amenity.price;
  }
}

    final data =
        await auth.paymentService.createPaypalOrder(amount);

    if (!mounted) return;

    final amenities = widget.selectedAmenities.entries
    .where((e) => e.value)
    .map((e) => {
          "amenityId": e.key,
          "quantity": 1,
        })
    .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
      builder: (_) => PayPalWebView(
  url: data["url"],
  orderId: data["orderId"],
  spaceId: widget.space.id,
  startTime: widget.startTime,
  endTime: widget.endTime,
  amenities: amenities,
  space: widget.space,
  totalPrice: amount,
),
      ),
    );

  } catch (e) {
    if (!mounted) return;
    _snack("PayPal failed");
    print(e);
  }

  if (!mounted) return;
  setState(() => _loading = false);
}

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _input(String hint, TextEditingController c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFE9E9E9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _icon(String path) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Image.asset(path, height: 18),
    );
  }

  Widget _button(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _method == "paypal"
              ? const Color(0xFF2E4DF6)
              : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
  children: [

    /// BACK BUTTON
    InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 18,
        ),
      ),
    ),

    const SizedBox(width: 14),

    const Text(
      "Payment information",
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
),

const SizedBox(height: 20),

              // ---------------- CARD TOGGLE ----------------
              GestureDetector(
                onTap: () => setState(() => _method = "card"),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _method == "card"
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        const Text("Credit/Debit Card",
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Row(
                      children: [
                        _icon("assets/icons/mastercard.png"),
                        const SizedBox(width: 6),
                        _icon("assets/icons/visa.png"),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- PAYPAL TOGGLE ----------------
              GestureDetector(
                onTap: () => setState(() => _method = "paypal"),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _method == "paypal"
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        const Text("PayPal",
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    _icon("assets/icons/paypal.png"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- CARD UI ----------------
              if (_method == "card") ...[
                _input("Cardholder name", _nameController),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CardField(
                    onCardChanged: (card) => _card = card,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _button("Pay", _pay),
              ],

              // ---------------- PAYPAL UI ----------------
              if (_method == "paypal") ...[
                const SizedBox(height: 10),

                const Text(
                  "You will be redirected to PayPal website to complete your order securely.",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 20),

                _button("Continue with PayPal", _payWithPaypal),
              ],

              const SizedBox(height: 50),

              const Center(
                child: Column(
                  children: [
                    Text(
                      "MEETSPACE",
                      style: TextStyle(
                        letterSpacing: 6,
                        color: Colors.white70,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text("+387 00 000 000",
                        style: TextStyle(color: Colors.white54)),
                    Text("info@meetspace.com",
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}