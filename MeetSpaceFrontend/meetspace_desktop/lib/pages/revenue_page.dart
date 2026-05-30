import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/revenue.dart';
import '../services/revenue_service.dart';
import 'revenue_history_page.dart';

class RevenuePage extends StatefulWidget {
  const RevenuePage({super.key});

  @override
  State<RevenuePage> createState() => _RevenuePageState();
}

class _RevenuePageState extends State<RevenuePage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  List<RevenueResponse> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final service = RevenueService(auth.api);

    final latest = await service.getLatest();

    setState(() {
      _data = latest;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
Row(
  children: [
    InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
      ),
    ),

    const SizedBox(width: 16),

    const Text(
      "MEETSPACE",
      style: TextStyle(
        color: Colors.white70,
        letterSpacing: 4,
        fontSize: 18,
      ),
    ),
  ],
),

            const SizedBox(height: 10),
const Text(
  "Revenue history",
  style: TextStyle(
    color: brandOrange,
    fontSize: 34,
    fontWeight: FontWeight.bold,
  ),
),

            const SizedBox(height: 30),

            const Center(
              child: Text(
                "Last 3 transactions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandOrange),
                    )
                  : Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _data.map((e) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 15),
                            child: _card(e),
                          );
                        }).toList(),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
  "See full history",
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RevenueHistoryPage(),
      ),
    );
  },
),
                const SizedBox(width: 16),
                
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _card(RevenueResponse r) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        height: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "BAM ${r.amount.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "DETAILS",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 12),

            _detail("User", r.user),
            _detail("Date", _formatDateTime(r.date)),
            _detail("Location", r.location),
            _detail("Payment", r.paymentMethod),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: brandOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$title: $value",
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

 Widget _actionButton(String text, {VoidCallback? onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: brandOrange,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: Text(text),
  );
}

  String _formatDateTime(DateTime d) {
    return "${d.day}.${d.month}.${d.year} - ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }
}