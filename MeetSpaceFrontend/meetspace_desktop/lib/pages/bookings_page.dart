import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/booking.dart';
import 'booking_status_dialog.dart';
import 'booking_history_page.dart';
import '../constants/app_constants.dart';

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

String _search = "";

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
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

  /// 🔥 HEADER
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

  Row(
  children: [
    const Text(
      "Upcoming bookings and reminders",
      style: TextStyle(
        color: Color(0xFFA56E09),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),

    const Spacer(),

    /// HISTORY
    OutlinedButton.icon(
     onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const BookingHistoryPage(),
    ),
  );
},
      icon: const Icon(Icons.history),
      label:
          const Text("See booking history"),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(
          color: Colors.white24,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        minimumSize:
            const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    ),

    const SizedBox(width: 16),

    /// STATUSES
    OutlinedButton.icon(
      onPressed: () async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        const BookingStatusesDialog(),
  );
},
      icon:
          const Icon(Icons.settings),
      label: const Text(
        "Manage booking statuses",
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(
          color: Colors.white24,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        minimumSize:
            const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    ),
  ],
),

const SizedBox(height: 20),

/// SEARCH
TextField(
  onChanged: (value) {
    setState(() {
      _search = value;
      _page = 0;
    });

    _loadBookings();
  },
  decoration: InputDecoration(
    hintText: "Quick search",
    prefixIcon:
        const Icon(Icons.search),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
        const EdgeInsets.symmetric(
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  ),
),

const SizedBox(height: 10),
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
      name: _search.isNotEmpty
          ? _search
          : null,
      isUpcoming: true,
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
    fontSize: 22,
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

              if (booking.bookingStatusId == BookingStatusIds.rejected && booking.rejectionReason != null)
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

Future<bool> _confirmSendReminder(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFA56E09).withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFFA56E09),
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Send reminder?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "The user will receive a booking reminder notification.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA56E09),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Send"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return confirmed == true;
}

  /// 🔥 MODAL FIX (NO OVERFLOW)
Future<void> _openDetails(BuildContext context) async {
  final booking = widget.booking;
  final isPending = booking.bookingStatusId == BookingStatusIds.pending;
   final isReminderAvailable =
    booking.bookingStatusId == BookingStatusIds.approved &&
    booking.startTime.isAfter(DateTime.now());
  await _loadConflict();

  final isPaymentCompleted =
    booking.paymentStatusName?.toLowerCase() == "completed";

String? approveDisabledReason;

if (!isPaymentCompleted) {
  approveDisabledReason =
      "Payment must be completed before approval.";
} else if (hasConflict == true) {
  approveDisabledReason =
      "Cannot approve because this time slot is already booked.";
}

final canApprove = isPending && approveDisabledReason == null;

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
                      Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Text(
        booking.spaceName ?? "Space",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close),
      tooltip: "Close",
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    ),
  ],
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
                      if (booking.bookingStatusId == BookingStatusIds.rejected &&
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
                       onTap: canApprove
    ? () async {

 await context
    .read<AuthProvider>()
    .bookingService
    .approve(booking.id);

Navigator.pop(context);
widget.onRefresh();

if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(
      bottom: 40,
      left: 20,
      right: 20,
    ),
    backgroundColor: const Color(0xFF4CAF50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    content: Row(
      children: const [
        Icon(Icons.check_circle, color: Colors.white),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "Booking approved successfully",
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
}
      : null,
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
title: Row(
  children: [
    const Expanded(
      child: Text(
        "Reject booking",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFA56E09),
        ),
      ),
    ),
    IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close),
      tooltip: "Close",
    ),
  ],
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

if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(
      bottom: 40,
      left: 20,
      right: 20,
    ),
    backgroundColor: const Color(0xFFE53935),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    content: Row(
      children: const [
        Icon(Icons.cancel, color: Colors.white),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "Booking rejected successfully",
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
                    ),
                  ],
                ),

                if (approveDisabledReason != null) ...[
  const SizedBox(height: 8),
  Align(
    alignment: Alignment.centerLeft,
    child: Text(
      approveDisabledReason,
      style: const TextStyle(
        color: Color(0xFFE53935),
        fontSize: 13,
        fontStyle: FontStyle.italic,
      ),
    ),
  ),
],
                const SizedBox(height: 12),
              ],

              /// 🔥 REMINDER (NE ZA REJECTED)
              if (isReminderAvailable)
                _secondaryButton(
                  text: "Send reminder",
                 onTap: () async {
                  final confirmed = await _confirmSendReminder(context);
if (!confirmed) return;
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
  required VoidCallback? onTap,
}) {
  final isDisabled = onTap == null;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDisabled ? color.withOpacity(0.35) : color,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(isDisabled ? 0.75 : 1),
          fontWeight: FontWeight.bold,
        ),
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