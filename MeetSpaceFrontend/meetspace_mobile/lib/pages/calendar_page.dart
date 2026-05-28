import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/space.dart';
import '../providers/auth_provider.dart';
import 'booking_page.dart';
import '../constants/app_constants.dart';

class CalendarPage extends StatefulWidget {
  final SpaceResponse space;

  const CalendarPage({super.key, required this.space});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  Map<DateTime, Set<int>> _bookedHoursPerDay = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

 Future<void> _loadBookings() async {
  final auth = context.read<AuthProvider>();

  final bookings =
      await auth.getBookingsForSpace(widget.space.id);

  final Map<DateTime, Set<int>> bookedMap = {};

  for (var b in bookings) {
    final blocksAvailability =
    b.bookingStatusId == BookingStatusIds.pending ||
    b.bookingStatusId == BookingStatusIds.approved;

if (!blocksAvailability) continue;

    final date = DateTime(
      b.startTime.year,
      b.startTime.month,
      b.startTime.day,
    );

    bookedMap.putIfAbsent(date, () => {});

    for (int h = b.startTime.hour; h < b.endTime.hour; h++) {
      bookedMap[date]!.add(h);
    }
  }

  setState(() {
    _bookedHoursPerDay = bookedMap;
    _loading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    final s = widget.space;

    final address = (s.facilityAddress ?? '').trim().isEmpty
        ? 'Address not available'
        : s.facilityAddress!.trim();

    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER IMAGE
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.25,
                  child: s.firstImageOrEmpty.isEmpty
                      ? Container(color: Colors.grey)
                      : Image.network(
                          s.firstImageOrEmpty,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white60,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    /// CALENDAR
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: brandOrange,
                              ),
                            )
                          : Column(
                              children: [
                                /// MONTH NAVIGATION
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _focusedMonth = DateTime(
                                              _focusedMonth.year,
                                              _focusedMonth.month - 1);
                                        });
                                      },
                                      icon: const Icon(Icons.chevron_left),
                                    ),
                                    Text(
                                      "${_monthName(_focusedMonth.month)} ${_focusedMonth.year}",
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _focusedMonth = DateTime(
                                              _focusedMonth.year,
                                              _focusedMonth.month + 1);
                                        });
                                      },
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                /// GRID
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: _daysInMonth(
                                      _focusedMonth.year,
                                      _focusedMonth.month),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                  ),
                                  itemBuilder: (context, index) {
                                    final day = index + 1;

                                    final dayDate = DateTime(
                                      _focusedMonth.year,
                                      _focusedMonth.month,
                                      day,
                                    );

                                    final today = DateTime.now();
                                    final todayOnly = DateTime(
                                        today.year, today.month, today.day);

                                    final isPast =
                                        dayDate.isBefore(todayOnly);
                                    final bookedHours = _bookedHoursPerDay[dayDate] ?? {};

final now = DateTime.now();

final isToday =
    dayDate.year == now.year &&
    dayDate.month == now.month &&
    dayDate.day == now.day;

/// prošli sati danas
final pastHoursToday = isToday
    ? List.generate(
        now.hour - 8 > 0 ? now.hour - 8 : 0,
        (i) => i + 8,
      ).toSet()
    : <int>{};

/// booked + prošli sati
final unavailableHours = {
  ...bookedHours,
  ...pastHoursToday,
};

final isFullDay = unavailableHours.length >= 8;
                                    final isSelected =
                                        _selectedDate == dayDate;

                                    Color bgColor;

                                    if (isPast) {
                                      bgColor = Colors.grey.shade400;
                                    } else if (isSelected) {
                                      bgColor = brandOrange;
                                    } else if (isFullDay) {
  bgColor = Colors.red;
}else {
                                      bgColor = Colors.green;
                                    }

                                    return GestureDetector(
                                      onTap: (isPast || isFullDay)
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedDate = dayDate;
                                              });
                                            },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "$day",
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                       onPressed: _selectedDate == null
    ? null
    : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingPage(
              space: widget.space,
              selectedDate: _selectedDate!,
            ),
          ),
        );
      },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String _monthName(int month) {
    const months = [
      "",
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
    return months[month];
  }
}