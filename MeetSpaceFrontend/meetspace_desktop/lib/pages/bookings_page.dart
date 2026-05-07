import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/booking.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  int _page = 0;
final int _pageSize = 6;

int _totalPages = 1;
bool _isLoading = false;

List<BookingResponse> _bookings = [];

 @override
void initState() {
  super.initState();
  _loadBookings();
}

 void refresh() {
  _loadBookings();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B3B3B),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "MEETSPACE",
              style: TextStyle(
                color: Colors.white70,
                letterSpacing: 4,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Upcoming bookings and reminders",
              style: TextStyle(
                color: Color(0xFFA56E09),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
Expanded(
  child: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _bookings.isEmpty
          ? const Center(
              child: Text(
                "No upcoming bookings",
                style: TextStyle(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _bookings.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 25,
                      mainAxisSpacing: 25,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      return BookingCard(
                        booking: _bookings[index],
                        onRefresh: refresh,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildPagination(),
                ],
              ),
            ),
),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBookings() async {
  setState(() => _isLoading = true);

  final result = await context
      .read<AuthProvider>()
      .bookingService
      .getPaged(
        page: _page,
        pageSize: _pageSize,
      );

  setState(() {
    _bookings = result.items;
    _totalPages = result.totalPages;
    _isLoading = false;
  });
}

Widget _buildPagination() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// PREV
        GestureDetector(
          onTap: _page > 0
              ? () {
                  setState(() => _page--);
                  _loadBookings();
                }
              : null,
          child: Icon(
            Icons.chevron_left,
            color: _page > 0 ? Colors.white : Colors.white24,
          ),
        ),

        const SizedBox(width: 8),

        /// PAGE NUMBERS
        for (int i = 0; i < _totalPages; i++)
          GestureDetector(
            onTap: () {
              setState(() => _page = i);
              _loadBookings();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _page == i
                    ? const Color(0xFFA56E09)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${i + 1}",
                style: TextStyle(
                  fontSize: 13,
                  color: _page == i ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        const SizedBox(width: 8),

        /// NEXT
        GestureDetector(
          onTap: _page < _totalPages - 1
              ? () {
                  setState(() => _page++);
                  _loadBookings();
                }
              : null,
          child: Icon(
            Icons.chevron_right,
            color: _page < _totalPages - 1
                ? Colors.white
                : Colors.white24,
          ),
        ),
      ],
    ),
  );
}
}



class BookingCard extends StatefulWidget {
  final BookingResponse booking;
  final VoidCallback onRefresh;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onRefresh,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _hover = false;
  bool? hasConflict;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _openDetails(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(_hover ? 1.02 : 1.0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.2 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE
              Text(
                booking.spaceName ?? "Space",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              /// IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 10, // 🔥 manja visina
                  child: booking.spaceImageUrl == null ||
                          booking.spaceImageUrl!.isEmpty
                      ? Container(
                          color: const Color(0xFFEDEDED),
                          child: const Icon(Icons.image_not_supported),
                        )
                      : Image.network(
                          booking.spaceImageUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),

              const SizedBox(height: 10),

              /// MIN INFO
              _infoRow(
                "Time",
                "${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}",
              ),
              _infoRow(
                "Price",
                "${booking.totalPrice.toStringAsFixed(2)} BAM",
              ),

              const SizedBox(height: 6),

              const SizedBox(height: 6),

              _statusBadge(),

              if (booking.bookingStatusId == 3 && booking.rejectionReason != null)
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      "Reason: ${booking.rejectionReason}",
      style: const TextStyle(
        fontSize: 12,
        color: Colors.redAccent,
        fontStyle: FontStyle.italic,
      ),
    ),
  ),

              const SizedBox(height: 10),

              /// 🔥 hint da je klikabilno
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    "View details →",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadConflict() async {
  final booking = widget.booking;

  final result = await context
      .read<AuthProvider>()
      .bookingService
      .checkConflict(
        spaceId: booking.spaceId,
        start: booking.startTime,
        end: booking.endTime,
        ignoreId: booking.id,
      );

  setState(() {
    hasConflict = result;
  });

  
}

  /// 🔥 MODAL FIX (NO OVERFLOW)
Future<void> _openDetails(BuildContext context) async {
  final booking = widget.booking;
  final isPending = booking.bookingStatusId == 1;
  await _loadConflict();

  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 550,
          maxHeight: 700,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              /// 🔥 SCROLLABLE CONTENT
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.spaceName ?? "Space",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        booking.facilityAddress ?? "",
                        style: const TextStyle(color: Colors.black54),
                      ),

                      const SizedBox(height: 18),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: booking.spaceImageUrl == null ||
                                booking.spaceImageUrl!.isEmpty
                            ? Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              )
                            : Image.network(
                                booking.spaceImageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),

                      const SizedBox(height: 18),

                      _infoRow("Date", _formatDate(booking.startTime)),
                      _infoRow(
                        "Time",
                        "${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}",
                      ),
                      _infoRow("User", booking.username ?? "-"),
                      _infoRow(
                        "Price",
                        "${booking.totalPrice.toStringAsFixed(2)} BAM",
                      ),

                      _infoRow("Payment", booking.paymentStatusName ?? "-"),

                      const SizedBox(height: 10),

                      _statusBadge(),

                     if (booking.lastAction != null)
  Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        const Icon(Icons.history, size: 16, color: Colors.black45),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "${booking.lastAction} by ${booking.lastAdminName ?? '-'}",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    ),
  ),

                      if (hasConflict != null)
  Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: hasConflict!
          ? Colors.red.withOpacity(0.1)
          : Colors.green.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          hasConflict! ? Icons.warning : Icons.check_circle,
          color: hasConflict! ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 8),
        Text(
          hasConflict!
              ? "Time conflict exists"
              : "Time slot available",
          style: TextStyle(
            color: hasConflict! ? Colors.red : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),

                      /// 🔥 REJECTION REASON
                      if (booking.bookingStatusId == 3 &&
                          booking.rejectionReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "Reason: ${booking.rejectionReason}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      /// 🔥 USER INFO TITLE (MEETSPACE STYLE)
                      const Text(
                        "User information",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA56E09),
                        ),
                      ),

                      const SizedBox(height: 8),

                      _infoRow("Name", booking.userFullName ?? "-"),
                      _infoRow("Email", booking.userEmail ?? "-"),
                      _infoRow("Phone", booking.userPhone ?? "-"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 🔥 BUTTONS
              if (isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: _mainButton(
                        text: "Approve",
                        color: const Color(0xFF4CAF50),
                       onTap: () async {
  if (booking.paymentStatusName?.toLowerCase() != "completed") {
    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
    backgroundColor: const Color(0xFFE53935),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    content: Row(
      children: const [
        Icon(Icons.warning_amber_rounded, color: Colors.white),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "Payment must be completed before approval",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
    duration: const Duration(seconds: 3),
  ),
);
    return;
  }

  if (hasConflict == true) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
      backgroundColor: const Color(0xFFE53935),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Cannot approve due to time conflict",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
  return;
}

  await context
      .read<AuthProvider>()
      .bookingService
      .approve(booking.id);

  Navigator.pop(context);
  widget.onRefresh();
},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _mainButton(
                        text: "Reject",
                        color: const Color(0xFFE53935),
                        onTap: () async {
                          final controller = TextEditingController();

                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) {
                           return AlertDialog(
  backgroundColor: const Color(0xFFF8F8F8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  title: const Text(
    "Reject booking",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFFA56E09),
    ),
  ),
  content: TextField(
    controller: controller,
    maxLines: 3,
    cursorColor: const Color(0xFFA56E09),
    decoration: InputDecoration(
      hintText: "Enter rejection reason...",
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFA56E09)),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        "Cancel",
        style: TextStyle(color: Colors.grey),
      ),
    ),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        if (controller.text.trim().isEmpty) return;
        Navigator.pop(context, controller.text.trim());
      },
      child: const Text("Reject"),
    ),
  ],
);
                            },
                          );

                          if (result == null) return;

                          await context
                              .read<AuthProvider>()
                              .bookingService
                              .rejectWithReason(booking.id, result);

                          Navigator.pop(context);
                          widget.onRefresh();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              /// 🔥 REMINDER (NE ZA REJECTED)
              if (booking.bookingStatusId != 3)
                _secondaryButton(
                  text: "Send reminder",
                 onTap: () async {
  await context
      .read<AuthProvider>()
      .bookingService
      .sendReminder(booking.id);

      Navigator.pop(context);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        bottom: 40,
        left: 20,
        right: 20,
      ),
      backgroundColor: const Color(0xFFA56E09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Row(
        children: const [
          Icon(Icons.notifications_active,
              color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Reminder sent successfully",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
},
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    Color color;
    String text = widget.booking.statusName ?? "";

    switch (text.toLowerCase()) {
      case "approved":
        color = Colors.green;
        break;
      case "rejected":
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _mainButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

 Widget _secondaryButton({
  required String text,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFA56E09),
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

  String _formatDate(DateTime dt) =>
      "${dt.day}.${dt.month}.${dt.year}";

  String _formatTime(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

}