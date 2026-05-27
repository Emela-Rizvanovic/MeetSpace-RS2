import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/space.dart';
import '../models/amenity.dart';
import '../providers/auth_provider.dart';
import 'payment_page.dart';

class BookingPage extends StatefulWidget {
  final SpaceResponse space;
  final DateTime selectedDate;

  const BookingPage({
    super.key,
    required this.space,
    required this.selectedDate,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  int? _startHour;
  int? _endHour;

  String? _timeError;

  Set<int> _bookedHours = {};

  List<AmenityResponse> _amenities = [];
  final Map<int, bool> _selectedAmenities = {};

  bool _loading = true;
  bool _booking = false;

  final List<int> _hoursList =
      List.generate(9, (index) => 8 + index);

  @override
  void initState() {
    super.initState();
    _loadAmenities();
    _loadBookedHours();
  }

  Future<void> _loadAmenities() async {
  setState(() {
    _amenities = widget.space.amenities; // koristi već učitane amenities tog spacea
    _loading = false;
  });
}

  Future<void> _loadBookedHours() async {
    final auth = context.read<AuthProvider>();
    final bookings =
        await auth.getBookingsForSpace(widget.space.id);

    final Set<int> hours = {};

    for (var b in bookings) {
      if (b.startTime.year == widget.selectedDate.year &&
          b.startTime.month == widget.selectedDate.month &&
          b.startTime.day == widget.selectedDate.day) {
        for (int h = b.startTime.hour;
            h < b.endTime.hour;
            h++) {
          hours.add(h);
        }
      }
    }

    setState(() {
      _bookedHours = hours;
    });
  }

  int get _hours {
    if (_startHour == null || _endHour == null) return 0;
    return _endHour! - _startHour!;
  }

  double get _baseTotal =>
      _hours * widget.space.pricePerHour;

  double get _amenitiesTotal {
    double total = 0;
    for (var a in _amenities) {
      if (_selectedAmenities[a.id] == true) {
        total += a.price;
      }
    }
    return total;
  }

  double get _finalTotal =>
      _baseTotal + _amenitiesTotal;

  Future<void> _book() async {
   if (_startHour == null || _endHour == null) {
  setState(() {
    _timeError = "Select both start time and end time.";
  });
  return;
}

if (_endHour! <= _startHour!) {
  setState(() {
    _timeError = "End time must be after start time.";
  });
  return;
}

    // CHECK PREKLAPANJA
    for (int h = _startHour!; h < _endHour!; h++) {
   if (_bookedHours.contains(h)) {
  setState(() {
    _timeError = "Selected time overlaps with an existing booking.";
  });
  return;
}
    }

    setState(() {
  _timeError = null;
});

    final start = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startHour!,
    );

    final end = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endHour!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          space: widget.space,
          startTime: start,
          endTime: end,
          selectedAmenities: _selectedAmenities,
          amenities: _amenities,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(color: brandOrange),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
      "Please select",
      style: TextStyle(
        color: Colors.white70,
        fontFamily: "Poppins",
        fontSize: 16,
      ),
    ),
  ],
),

const SizedBox(height: 18),

                    _inputBox(
                        "BAM ${widget.space.pricePerHour.toStringAsFixed(0)} per hour – starter"),

                    const SizedBox(height: 14),

                    _inputBox(
                        "Date\n${widget.selectedDate.day}.${widget.selectedDate.month}.${widget.selectedDate.year}"),

                    const SizedBox(height: 20),

                    const Text(
                      "Start time",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildHourSelector(isStart: true),

                    const SizedBox(height: 20),

                    const Text(
                      "End time",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildHourSelector(isStart: false),

                    if (_timeError != null) ...[
  const SizedBox(height: 8),
  Text(
    _timeError!,
    style: const TextStyle(
      color: Colors.red,
      fontSize: 13,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w500,
    ),
  ),
],

                    const SizedBox(height: 28),

                    const Text(
                      "Add-ons (optional)",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._amenities.map(
                      (a) => CheckboxListTile(
                        value:
                            _selectedAmenities[a.id] == true,
                        onChanged: (val) {
                          setState(() {
                            _selectedAmenities[a.id] =
                                val ?? false;
                          });
                        },
                        activeColor: brandOrange,
                        title: Text(
                          a.name,
                          style: const TextStyle(
                              color: Colors.white),
                        ),
                        subtitle: Text(
                          "BAM ${a.price.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.white54),
                        ),
                        controlAffinity:
                            ListTileControlAffinity
                                .trailing,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 🔥 PRICING DETAILS
                    const Text(
                      "Pricing details",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _priceRow(
                        "BAM ${widget.space.pricePerHour.toStringAsFixed(0)} x $_hours hours",
                        "BAM ${_baseTotal.toStringAsFixed(2)}"),

                    ..._amenities
                        .where((a) =>
                            _selectedAmenities[a.id] ==
                            true)
                        .map((a) => _priceRow(
                            a.name,
                            "BAM ${a.price.toStringAsFixed(2)}")),

                    const Divider(color: Colors.white24),

                    _priceRow(
                      "Total",
                      "BAM ${_finalTotal.toStringAsFixed(2)}",
                      bold: true,
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _booking ? null : _book,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                        ),
                        child: const Text(
                          "Book it",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHourSelector({required bool isStart}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _hoursList.map((hour) {
        final isSelected =
            isStart ? _startHour == hour : _endHour == hour;
        final isBooked =
            _bookedHours.contains(hour);
        final isInvalidEnd = !isStart &&
            _startHour != null &&
            hour <= _startHour!;
        final now = DateTime.now();

final isToday =
    widget.selectedDate.year == now.year &&
    widget.selectedDate.month == now.month &&
    widget.selectedDate.day == now.day;

final isPastHour =
    isToday && hour <= now.hour;

        return GestureDetector(
          onTap: (isBooked || isInvalidEnd || isPastHour)
              ? null
              : () {
                  setState(() {
                    _timeError = null;
                    if (isStart) {
                      _startHour = hour;
                      if (_endHour != null &&
                          _endHour! <=
                              _startHour!) {
                        _endHour = null;
                      }
                    } else {
                      _endHour = hour;
                    }
                  });
                },
          child: Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: isBooked || isPastHour
                  ? Colors.black38
                  : isInvalidEnd
                      ? Colors.black45
                      : isSelected
                          ? brandOrange
                          : const Color(0xFF2E2E2E),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "${hour.toString().padLeft(2, '0')}:00",
                style: TextStyle(
                  fontFamily: "Poppins",
                  color: isBooked || isPastHour
                      ? Colors.white30
                      : isInvalidEnd
                          ? Colors.white38
                          : isSelected
                              ? Colors.white
                              : Colors.white70,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _inputBox(String text) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
              horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: "Poppins",
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _priceRow(String left, String right,
      {bool bold = false}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(
              fontFamily: "Poppins",
              color: Colors.white70,
              fontWeight:
                  bold
                      ? FontWeight.w700
                      : FontWeight.w400,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontFamily: "Poppins",
              color: Colors.white,
              fontWeight:
                  bold
                      ? FontWeight.w700
                      : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}