import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../providers/auth_provider.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({
    super.key,
  });

  @override
  State<BookingHistoryPage> createState() =>
      _BookingHistoryPageState();
}

class _BookingHistoryPageState
    extends State<BookingHistoryPage> {

  static const bgColor =
      Color(0xFF3B3B3B);

  static const brandOrange =
      Color.fromARGB(
          255, 165, 110, 9);

  List<BookingResponse>
      _bookings = [];

  bool _isLoading = false;

  String _search = "";

  int? _selectedStatusId;

  int _page = 0;

  final int _pageSize = 10;

  int _totalPages = 1;

  @override
  void initState() {
    super.initState();

    _loadBookings();
  }

  Future<void>
      _loadBookings() async {

    setState(() {
      _isLoading = true;
    });

    final result = await context
        .read<AuthProvider>()
        .bookingService
        .getPaged(
          page: _page,
          pageSize: _pageSize,
          name:
              _search.isNotEmpty
                  ? _search
                  : null,
          isUpcoming: false,
          bookingStatusId: _selectedStatusId,
        );

    setState(() {
      _bookings = result.items;

      _totalPages =
          result.totalPages;

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          bgColor,

      body: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 60,
          vertical: 40,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            /// TOP BAR
            Row(
              children: [
                InkWell(
                  onTap: () =>
                      Navigator.pop(
                          context),

                  borderRadius:
                      BorderRadius.circular(
                          12),

                  child: Container(
                    padding:
                        const EdgeInsets
                            .all(10),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                              0xFF2E2E2E),

                      borderRadius:
                          BorderRadius
                              .circular(
                                  12),
                    ),

                    child: const Icon(
                      Icons.arrow_back,
                      color:
                          Colors.white,
                    ),
                  ),
                ),

                const SizedBox(
                    width: 16),

                const Text(
                  "MEETSPACE",

                  style: TextStyle(
                    color:
                        Colors.white70,
                    letterSpacing: 4,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(
                height: 30),

            /// TITLE
           Row(
  mainAxisAlignment:
      MainAxisAlignment.spaceBetween,

  crossAxisAlignment:
      CrossAxisAlignment.center,

  children: [

    const Text(
      "Booking history",

      style: TextStyle(
        color: brandOrange,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
    ),

    SizedBox(
      width: 240,

      child: DropdownButtonFormField<int?>(
        value: _selectedStatusId,

        dropdownColor: Colors.white,

        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,

          prefixIcon: const Icon(
            Icons.filter_alt_outlined,
          ),

          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),

            borderSide: const BorderSide(
              color: brandOrange,
              width: 1.2,
            ),
          ),
        ),

        items: const [

          DropdownMenuItem(
            value: null,
            child: Text("All statuses"),
          ),

          DropdownMenuItem(
            value: 1,
            child: Text("Pending"),
          ),

          DropdownMenuItem(
            value: 2,
            child: Text("Approved"),
          ),

          DropdownMenuItem(
            value: 3,
            child: Text("Rejected"),
          ),
        ],

        onChanged: (value) {
          setState(() {
            _selectedStatusId = value;
            _page = 0;
          });

          _loadBookings();
        },
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

              decoration:
                  InputDecoration(
                hintText:
                    "Quick search",

                prefixIcon:
                    const Icon(
                        Icons.search),

                filled: true,

                fillColor:
                    Colors.white,

                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              14),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
                height: 30),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            brandOrange,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 10,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          16),
                            ),

                            child: Column(
                              children: [

                                /// HEADER
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        20,
                                    vertical:
                                        16,
                                  ),

                                  decoration:
                                      const BoxDecoration(
                                    border:
                                        Border(
                                      bottom:
                                          BorderSide(
                                        color:
                                            Colors.black12,
                                      ),
                                    ),
                                  ),

                                  child:
                                      const Row(
                                    children: [

                                      Expanded(
                                        flex: 2,
                                        child:
                                            Text(
                                          "Space",

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          "User",

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          "Date",

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          "Status",

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          "Price",

                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /// LIST
                                ListView.builder(
                                  shrinkWrap:
                                      true,

                                  physics:
                                      const NeverScrollableScrollPhysics(),

                                  itemCount:
                                      _bookings
                                          .length,

                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    final b =
                                        _bookings[
                                            index];

                                    return Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal:
                                            20,
                                        vertical:
                                            16,
                                      ),

                                      decoration:
                                          const BoxDecoration(
                                        border:
                                            Border(
                                          bottom:
                                              BorderSide(
                                            color:
                                                Colors.black12,
                                          ),
                                        ),
                                      ),

                                      child:
                                          Row(
                                        children: [

                                          Expanded(
                                            flex:
                                                2,

                                            child:
                                                Text(
                                              b.spaceName ??
                                                  "-",
                                            ),
                                          ),

                                          Expanded(
                                            child:
                                                Text(
                                              b.username ??
                                                  "-",
                                            ),
                                          ),

                                          Expanded(
                                            child:
                                                Text(
                                              _formatDate(
                                                  b.startTime),
                                            ),
                                          ),

                                          Expanded(
                                            child:
                                                Text(
                                              b.statusName ??
                                                  "-",
                                            ),
                                          ),

                                          Expanded(
                                            child:
                                                Text(
                                              "${b.totalPrice.toStringAsFixed(2)} BAM",
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                              height:
                                  12),

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

  Widget _buildPagination() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color:
            Colors.black.withOpacity(
                0.2),

        borderRadius:
            BorderRadius.circular(
                20),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          GestureDetector(
            onTap: _page > 0
                ? () {
                    setState(() =>
                        _page--);

                    _loadBookings();
                  }
                : null,

            child: Icon(
              Icons.chevron_left,
              color: _page > 0
                  ? Colors.white
                  : Colors.white24,
            ),
          ),

          const SizedBox(width: 8),

          for (int i = 0;
              i < _totalPages;
              i++)
            GestureDetector(
              onTap: () {
                setState(() =>
                    _page = i);

                _loadBookings();
              },

              child: Container(
                margin:
                    const EdgeInsets
                        .symmetric(
                            horizontal:
                                4),

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      _page == i
                          ? brandOrange
                          : Colors
                              .transparent,

                  borderRadius:
                      BorderRadius
                          .circular(
                              10),
                ),

                child: Text(
                  "${i + 1}",

                  style: TextStyle(
                    fontSize: 13,
                    color: _page == i
                        ? Colors.white
                        : Colors.white70,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap:
                _page <
                        _totalPages - 1
                    ? () {
                        setState(() =>
                            _page++);

                        _loadBookings();
                      }
                    : null,

            child: Icon(
              Icons.chevron_right,
              color: _page <
                      _totalPages - 1
                  ? Colors.white
                  : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(
      DateTime dt) {
    return "${dt.day}.${dt.month}.${dt.year}";
  }
}