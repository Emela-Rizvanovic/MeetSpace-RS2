import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking_status.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';

import '../widgets/admin_styles.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/booking_statuses_section.dart';

class BookingStatusesDialog
    extends StatefulWidget {
  const BookingStatusesDialog({
    super.key,
  });

  @override
  State<BookingStatusesDialog>
      createState() =>
          _BookingStatusesDialogState();
}

class _BookingStatusesDialogState
    extends State<
        BookingStatusesDialog> {

  List<BookingStatus>
      _bookingStatuses = [];

  bool _isLoadingBookingStatuses =
      false;

  String _bookingStatusSearch = "";

  int _bookingStatusPage = 0;

  final int _bookingStatusPageSize =
      3;

  int _bookingStatusTotalPages = 1;

  @override
  void initState() {
    super.initState();

    _loadBookingStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          AdminStyles.bgColor,

      insetPadding:
          const EdgeInsets.all(40),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
                24),
      ),

      child: SizedBox(
        width: 1000,
        height: 650,

        child: Padding(
          padding:
              const EdgeInsets.all(30),

          child: Column(
  children: [
    Row(
      children: [
        const Expanded(
          child: Text(
            "BOOKING STATUSES",
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 2,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white70),
          tooltip: "Close",
        ),
      ],
    ),

    const SizedBox(height: 20),

    Expanded(
      child:
          BookingStatusesSection(
                  bookingStatuses:
                      _bookingStatuses,

                  isLoading:
                      _isLoadingBookingStatuses,

                  currentPage:
                      _bookingStatusPage,

                  totalPages:
                      _bookingStatusTotalPages,

                  onSearch: (value) {
                    setState(() {
                      _bookingStatusSearch =
                          value;

                      _bookingStatusPage = 0;
                    });

                    _loadBookingStatuses();
                  },

                  onAdd: () async {
                    await _showBookingStatusDialog();
                  },

                  onEdit:
                      (status) async {
                    await _showBookingStatusDialog(
                      status:
                          status,
                    );
                  },

                  onDelete:
                      (status) async {
                    await _deleteBookingStatus(
                      status,
                    );
                  },

                  onPrevious:
                      _bookingStatusPage > 0
                          ? () {
                              setState(() {
                                _bookingStatusPage--;
                              });

                              _loadBookingStatuses();
                            }
                          : null,

                  onNext:
                      _bookingStatusPage <
                              _bookingStatusTotalPages -
                                  1
                          ? () {
                              setState(() {
                                _bookingStatusPage++;
                              });

                              _loadBookingStatuses();
                            }
                          : null,

                  onPageSelected:
                      (page) {
                    setState(() {
                      _bookingStatusPage =
                          page;
                    });

                    _loadBookingStatuses();
                  },
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: 150,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  style:
                      AdminStyles.primaryButton,

                  child:
                      const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void>
      _showBookingStatusDialog({
    BookingStatus? status,
  }) async {

    final formKey =
        GlobalKey<FormState>();

    final controller =
        TextEditingController(
      text: status?.name ?? "",
    );

    final result =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor:
              AdminStyles.cardColor,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
                    20),
          ),

          title: Row(
  children: [
    Expanded(
      child: Text(
        status == null ? "Add booking status" : "Edit booking status",
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    ),
    IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close, color: Colors.white70),
      tooltip: "Close",
    ),
  ],
),

          content: SizedBox(
            width: 400,

            child: Form(
              key: formKey,

              child: TextFormField(
                controller:
                    controller,

                autovalidateMode:
                    AutovalidateMode
                        .onUserInteraction,

                validator:
                    (value) =>
                        Validators
                            .required(
                  value,
                  "Booking status name",
                ),

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                ),

                decoration:
                    AdminStyles
                        .inputDecoration(
                  "Booking status name",
                ),
              ),
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                    context);
              },

              style: AdminStyles
                  .cancelButton,

              child: const Text(
                  "Cancel"),
            ),

            ElevatedButton(
              onPressed:
                  () async {

                if (!formKey
                    .currentState!
                    .validate()) {
                  return;
                }

                try {
                  final auth =
                      context.read<
                          AuthProvider>();

                  final body = {
                    "name":
                        controller
                            .text,
                  };

                  if (status ==
                      null) {

                    await auth
                        .bookingStatusService
                        .insert(
                            body);

                  } else {

                    await auth
                        .bookingStatusService
                        .update(
                      status.id,
                      body,
                    );
                  }

                  Navigator.pop(
                    context,
                    true,
                  );

              } catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Action failed")),
  );
}
              },

              style: AdminStyles
                  .primaryButton,

              child:
                  const Text(
                      "Save"),
            ),
          ],
        );
      },
    );

    if (result == true) {
  _bookingStatusPage = 0;
  await _loadBookingStatuses();

      if (mounted) {
        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          SnackBar(
            content: Text(
              status == null
                  ? "Booking status added successfully"
                  : "Booking status updated successfully",
            ),

            backgroundColor:
                Colors.green,
          ),
        );
      }
    }
  }

  Future<void>
      _deleteBookingStatus(
    BookingStatus status,
  ) async {

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (_) {
        return ConfirmDeleteDialog(
          title:
              "Delete booking status",

          message:
              "Are you sure you want to delete ${status.name}?",
        );
      },
    );

    if (confirmed == true) {
      try {
        final auth =
            context.read<
                AuthProvider>();

        await auth
            .bookingStatusService
            .delete(
          status.id,
        );

        await _loadBookingStatuses();

        if (mounted) {
          ScaffoldMessenger.of(
                  context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Booking status deleted successfully",
              ),

              backgroundColor:
                  Colors.red,
            ),
          );
        }

      } catch (e) {

        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Cannot delete booking status because it is required by the system or already in use.",
            ),

            backgroundColor:
                Colors.orange,
          ),
        );
      }
    }
  }

  Future<void>
      _loadBookingStatuses() async {

    try {
      setState(() {
        _isLoadingBookingStatuses =
            true;
      });

      final auth =
          context.read<
              AuthProvider>();

      final result =
         await auth
    .bookingStatusService
    .getPaged(
  page: _bookingStatusPage,

  pageSize:
      _bookingStatusPageSize,

  name:
      _bookingStatusSearch,

  sortBy: "Id",
  desc: true,
);

      final items =
          result["items"]
              as List;

      setState(() {
        _bookingStatuses = items
            .map(
              (e) =>
                  BookingStatus
                      .fromJson(
                          e),
            )
            .toList();

        _bookingStatusTotalPages =
            result["totalPages"] ??
                1;

        _isLoadingBookingStatuses =
            false;
      });

    } catch (e) {
      setState(() {
        _isLoadingBookingStatuses =
            false;
      });
    }
  }
}