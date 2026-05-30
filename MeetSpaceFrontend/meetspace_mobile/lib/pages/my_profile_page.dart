import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import 'menu_page.dart';
import 'edit_profile_page.dart';



class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  Future<List<BookingResponse>>? _bookingsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookingsFuture ??=
        Provider.of<AuthProvider>(context, listen: false).getMyBookings();
  }

 void _reloadBookings() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _bookingsFuture = auth.getMyBookings();
    });
  });
}

Future<void> _cancelBooking(BookingResponse booking) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);

  final reason = await showDialog<String>(
    context: context,
    builder: (_) => const _CancelBookingDialog(),
  );

  if (!mounted) return;
  if (reason == null || reason.trim().isEmpty) return;

 try {
  await auth.cancelBooking(
    bookingId: booking.id,
    reason: reason.trim(),
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red,
      content: Row(
        children: const [
          Icon(Icons.cancel, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text("Booking cancelled successfully"),
          ),
        ],
      ),
    ),
  );

  _reloadBookings();
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red,
      content: const Text(
        "Cancellation reason must contain 5-500 characters.",
      ),
    ),
  );
}
}

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final u = auth.user;

    if (u == null) {
      return Scaffold(
        backgroundColor: bgGrey,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Header(
                  title: 'MEETSPACE',
                  onMenu: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuPage()),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "You are not logged in.",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Go to login",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fullName =
        _safe("${u.firstName} ${u.lastName}".trim(), fallback: "User");
    final username = _safe(u.username, fallback: "-");
    final phone = _safe(u.phoneNumber, fallback: "-");
    final email = _safe(u.email, fallback: "-");
    final imageUrl = (u.profileImageUrl ?? "").trim();

    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: 'MEETSPACE',
                onMenu: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuPage()),
                ),
              ),

              const SizedBox(height: 14),

              const Center(
                child: Text(
                  "My profile",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    color: brandOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 34,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1.25, 
                        child: imageUrl.isEmpty
                            ? Container(
                                color: const Color(0xFFE9E9E9),
                                child: const Icon(
                                  Icons.person,
                                  size: 120,
                                  color: Color(0xFFB0B0B0),
                                ),
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFE9E9E9),
                                    child: const Icon(
                                      Icons.person,
                                      size: 120,
                                      color: Color(0xFFB0B0B0),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      fullName,
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _InfoRow(label: "Username:", value: username),
                    const SizedBox(height: 6),
                    _InfoRow(label: "Phone number:", value: phone),
                    const SizedBox(height: 6),
                    _InfoRow(label: "E-mail address:", value: email),

                    const SizedBox(height: 18),

                    Center(
                      child: OutlinedButton(
                       onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const EditProfilePage(),
    ),
  );
},

                        style: OutlinedButton.styleFrom(
                          foregroundColor: brandOrange,
                          side: const BorderSide(color: brandOrange, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Edit profile",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "My bookings",
                style: TextStyle(
                  fontFamily: "Poppins",
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 10),

              FutureBuilder<List<BookingResponse>>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: CircularProgressIndicator(color: brandOrange),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorBox(
                      message: snapshot.error.toString(),
                      onRetry: () {
                        setState(() {
                          _bookingsFuture =
                              Provider.of<AuthProvider>(context, listen: false)
                                  .getMyBookings();
                        });
                      },
                    );
                  }

                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return const _EmptyBox(text: "No bookings yet.");
                  }

                  return Column(
                    children: bookings
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                           child: _BookingCardFromApi(
  booking: b,
  onCancel: _cancelBooking,
),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _safe(String? v, {required String fallback}) {
    final s = (v ?? "").trim();
    return s.isEmpty ? fallback : s;
  }
}

class _CancelBookingDialog extends StatefulWidget {
  const _CancelBookingDialog();

  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Cancel booking",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    color: Color(0xFFA56E09),
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
                tooltip: "Close",
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Please enter the reason for cancelling this booking.",
            style: TextStyle(
              fontFamily: "Poppins",
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            cursorColor: const Color(0xFFA56E09),
            style: const TextStyle(
              fontFamily: "Poppins",
              color: Colors.white,
            ),
            onChanged: (_) {
  if (_errorMessage != null) {
    setState(() {
      _errorMessage = null;
    });
  }
},
            decoration: InputDecoration(
              hintText: "Cancellation reason",
              hintStyle: const TextStyle(
                fontFamily: "Poppins",
                color: Colors.white38,
              ),
              filled: true,
              fillColor: const Color(0xFF3B3B3B),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFA56E09),
                  width: 1.4,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
  const SizedBox(height: 6),
  Text(
    _errorMessage!,
    style: const TextStyle(
      fontFamily: "Poppins",
      color: Colors.red,
      fontSize: 12,
      height: 1.3,
    ),
  ),
],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                 onPressed: () {
  final value = _controller.text.trim();

  if (value.length < 5 || value.length > 500) {
    setState(() {
      _errorMessage =
          "Cancellation reason must contain 5-500 characters.";
    });
    return;
  }

  Navigator.of(context).pop(value);
},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Cancel booking",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onMenu;

  const _Header({required this.title, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: "Poppins",
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
            fontSize: 20,
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onMenu,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.menu, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: "Poppins",
          color: Colors.black87,
          fontSize: 15,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: "$label ",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}

class _BookingCardFromApi extends StatelessWidget {
  final BookingResponse booking;
 final void Function(BookingResponse booking) onCancel;

const _BookingCardFromApi({
  required this.booking,
  required this.onCancel,
});

  @override
  Widget build(BuildContext context) {
    final title = (booking.spaceName ?? "").trim().isEmpty
    ? "Booked space"
    : booking.spaceName!.trim();

    final address = (booking.facilityAddress ?? "").trim();
    final status = (booking.statusName ?? "").trim();

    final canCancel =
    (booking.bookingStatusId == BookingStatusIds.pending ||
        booking.bookingStatusId == BookingStatusIds.approved) &&
    booking.startTime.isAfter(DateTime.now());

    final timeLine =
        "${_fmtDateTimeLocal(booking.startTime)} → ${_fmtDateTimeLocal(booking.endTime)}";

    final priceLine = "Total: ${booking.totalPrice.toStringAsFixed(2)}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: "Poppins",
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeLine,
            style: const TextStyle(
              fontFamily: "Poppins",
              color: Colors.black54,
              fontWeight: FontWeight.w300,
              fontSize: 14,
            ),
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              address,
              style: const TextStyle(
                fontFamily: "Poppins",
                color: Colors.black54,
                fontWeight: FontWeight.w300,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  priceLine,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          if (booking.isPaid) ...[
  const SizedBox(height: 8),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Text(
      "Paid",
      style: TextStyle(
        fontFamily: "Poppins",
        color: Color(0xFF2E7D32),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  ),
],
         if ((status.toLowerCase() == "rejected" ||
        status.toLowerCase() == "cancelled") &&
    booking.rejectionReason != null &&
    booking.rejectionReason!.trim().isNotEmpty) ...[
  const SizedBox(height: 10),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.red.shade200,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       Text(
  status.toLowerCase() == "cancelled"
      ? "Cancellation reason"
      : "Rejection reason",
  style: const TextStyle(
    fontFamily: "Poppins",
    color: Colors.red,
    fontWeight: FontWeight.w600,
    fontSize: 13,
  ),
),
        const SizedBox(height: 4),
        Text(
          booking.rejectionReason!,
          style: const TextStyle(
            fontFamily: "Poppins",
            color: Colors.black87,
            fontWeight: FontWeight.w300,
            fontSize: 13,
          ),
        ),
      ],
    ),
  ),
],
if (canCancel) ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: () => onCancel(booking),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        "Cancel booking",
        style: TextStyle(
          fontFamily: "Poppins",
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ),
],
        ],
      ),
    );
  }


  static String _fmtDateTimeLocal(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}";
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: "Poppins",
          color: Colors.black54,
          fontWeight: FontWeight.w300,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Failed to load bookings",
            style: TextStyle(
              fontFamily: "Poppins",
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: "Poppins",
              color: Colors.black54,
              fontWeight: FontWeight.w300,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
