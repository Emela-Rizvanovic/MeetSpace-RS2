import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/space.dart';

class PaymentPage extends StatefulWidget {
  final SpaceResponse space;
  final DateTime startTime;
  final DateTime endTime;
  final Map<int, bool> selectedAmenities;

  const PaymentPage({
    super.key,
    required this.space,
    required this.startTime,
    required this.endTime,
    required this.selectedAmenities,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const bg = Color(0xFF3B3B3B);

  CardFieldInputDetails? _card;
  final _nameController = TextEditingController();

  bool _agree = false;
  bool _loading = false;

  Future<void> _pay() async {
    if (!_agree) {
      _snack("Accept terms");
      return;
    }

    if (_card == null || !_card!.complete) {
      _snack("Enter valid card");
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();

      final hours =
          widget.endTime.difference(widget.startTime).inHours;

      final amount = hours * widget.space.pricePerHour;

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

      _snack("Payment successful (Pending approval)");
      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      _snack("Payment failed");
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

              const Text(
                "Payment information",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: const [
        Icon(Icons.radio_button_checked, color: Colors.blue),
        SizedBox(width: 8),
        Text("Credit/Debit Card",
            style: TextStyle(color: Colors.white)),
      ],
    ),

    Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
  "assets/icons/Mastercard.png",
  height: 18,
),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        child: Image.asset(
  "assets/icons/Visa.png",
  height: 18,
),
        ),
      ],
    )
  ],
),

              const SizedBox(height: 15),

              _input("Cardholder name", _nameController),

              // 🔥 STILIZOVANI CARD FIELD (kao prototip)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CardField(
                  onCardChanged: (card) => _card = card,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),

              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    activeColor: Colors.orange,
                    onChanged: (v) =>
                        setState(() => _agree = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the Terms and conditions",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text(
                          "Pay",
                          style: TextStyle(
                            color: Colors.white, // 🔥 FIXED
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

             Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: const [
        Icon(Icons.radio_button_off, color: Colors.white70),
        SizedBox(width: 8),
        Text("PayPal",
            style: TextStyle(color: Colors.white)),
      ],
    ),

    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Image.asset(
  "assets/icons/PayPal.png",
  height: 18,
),
    ),
  ],
),

              const Padding(
                padding: EdgeInsets.only(left: 28, top: 6),
                child: Text(
                  "You will be redirected to PayPal website to complete your order securely.",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

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