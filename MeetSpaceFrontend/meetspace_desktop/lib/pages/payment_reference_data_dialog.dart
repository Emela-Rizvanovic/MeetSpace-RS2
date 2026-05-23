import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_status.dart';
import '../models/payment_method.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../widgets/admin_styles.dart';
import '../widgets/payment_statuses_section.dart';
import '../widgets/payment_methods_section.dart';
import '../widgets/confirm_delete_dialog.dart';

class PaymentReferenceDataDialog
    extends StatefulWidget {
  const PaymentReferenceDataDialog({
    super.key,
  });

  @override
  State<PaymentReferenceDataDialog>
      createState() =>
          _PaymentReferenceDataDialogState();
}

class _PaymentReferenceDataDialogState
    extends State<
        PaymentReferenceDataDialog> {

  /// PAYMENT STATUSES

  List<PaymentStatus>
      _paymentStatuses = [];

  bool _isLoadingStatuses =
      false;

  String _paymentStatusSearch =
      "";

  int _paymentStatusPage = 0;

  final int
      _paymentStatusPageSize = 4;

  int _paymentStatusTotalPages =
      1;

  /// PAYMENT METHODS

  List<PaymentMethod>
      _paymentMethods = [];

  bool _isLoadingMethods =
      false;

  String _paymentMethodSearch =
      "";

  int _paymentMethodPage = 0;

  final int
      _paymentMethodPageSize = 4;

  int _paymentMethodTotalPages =
      1;

  @override
  void initState() {
    super.initState();

    _loadPaymentStatuses();
    _loadPaymentMethods();
  }

  String _selected =
      "Payment statuses";

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
        width: 1200,
        height: 700,

        child: Row(
          children: [

            /// SIDEBAR

            Container(
              width: 240,

              decoration:
                  const BoxDecoration(
                color:
                    AdminStyles
                        .cardColor,

                borderRadius:
                    BorderRadius.only(
                  topLeft:
                      Radius.circular(
                          24),

                  bottomLeft:
                      Radius.circular(
                          24),
                ),
              ),

              child: Column(
                children: [

                  const SizedBox(
                      height: 30),

                  const Text(
                    "PAYMENT DATA",

                    style: TextStyle(
                      color:
                          Colors.white70,

                      letterSpacing:
                          2,

                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(
                      height: 40),

                  _buildMenuItem(
                    "Payment statuses",
                  ),

                  _buildMenuItem(
                    "Payment methods",
                  ),

                  const Spacer(),

                  Padding(
                    padding:
                        const EdgeInsets.all(
                            20),

                    child: SizedBox(
                      width:
                          double.infinity,

                      child:
                          ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                              context);
                        },

                        style:
                            AdminStyles
                                .primaryButton,

                        child:
                            const Text(
                          "Close",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// CONTENT

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                        30),

                child:
                    _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      String title) {

    final selected =
        _selected == title;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
                14),

        onTap: () {
          setState(() {
            _selected = title;
          });
        },

        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),

          decoration:
              BoxDecoration(
            color: selected
                ? AdminStyles
                    .brandOrange
                : Colors.transparent,

            borderRadius:
                BorderRadius.circular(
                    14),
          ),

          child: Row(
            children: [

              Expanded(
                child: Text(
                  title,

                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white70,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {

    switch (_selected) {

      case "Payment statuses":

        return PaymentStatusesSection(
          paymentStatuses:
              _paymentStatuses,

          isLoading:
              _isLoadingStatuses,

          currentPage:
              _paymentStatusPage,

          totalPages:
              _paymentStatusTotalPages,

          onSearch: (value) {
            setState(() {
              _paymentStatusSearch =
                  value;

              _paymentStatusPage =
                  0;
            });

            _loadPaymentStatuses();
          },

          onAdd: () async {
            await _showPaymentStatusDialog();
          },

          onEdit: (status) async {
            await _showPaymentStatusDialog(
              status: status,
            );
          },

          onDelete:
              (status) async {
            await _deletePaymentStatus(
              status,
            );
          },

          onPrevious:
              _paymentStatusPage > 0
                  ? () {
                      setState(() {
                        _paymentStatusPage--;
                      });

                      _loadPaymentStatuses();
                    }
                  : null,

          onNext:
              _paymentStatusPage <
                      _paymentStatusTotalPages -
                          1
                  ? () {
                      setState(() {
                        _paymentStatusPage++;
                      });

                      _loadPaymentStatuses();
                    }
                  : null,

          onPageSelected:
              (page) {
            setState(() {
              _paymentStatusPage =
                  page;
            });

            _loadPaymentStatuses();
          },
        );

      case "Payment methods":

        return PaymentMethodsSection(
          paymentMethods:
              _paymentMethods,

          isLoading:
              _isLoadingMethods,

          currentPage:
              _paymentMethodPage,

          totalPages:
              _paymentMethodTotalPages,

          onSearch: (value) {
            setState(() {
              _paymentMethodSearch =
                  value;

              _paymentMethodPage =
                  0;
            });

            _loadPaymentMethods();
          },

          onAdd: () async {
            await _showPaymentMethodDialog();
          },

          onEdit: (method) async {
            await _showPaymentMethodDialog(
              method: method,
            );
          },

          onDelete:
              (method) async {
            await _deletePaymentMethod(
              method,
            );
          },

          onPrevious:
              _paymentMethodPage > 0
                  ? () {
                      setState(() {
                        _paymentMethodPage--;
                      });

                      _loadPaymentMethods();
                    }
                  : null,

          onNext:
              _paymentMethodPage <
                      _paymentMethodTotalPages -
                          1
                  ? () {
                      setState(() {
                        _paymentMethodPage++;
                      });

                      _loadPaymentMethods();
                    }
                  : null,

          onPageSelected:
              (page) {
            setState(() {
              _paymentMethodPage =
                  page;
            });

            _loadPaymentMethods();
          },
        );

      default:
        return const SizedBox();
    }
  }

  Future<void>
      _showPaymentStatusDialog({
    PaymentStatus? status,
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

          title: Text(
            status == null
                ? "Add payment status"
                : "Edit payment status",

            style:
                const TextStyle(
              color: Colors.white,
            ),
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
                  "Payment status name",
                ),

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                ),

                decoration:
                    AdminStyles
                        .inputDecoration(
                  "Payment status name",
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
                        .paymentStatusService
                        .insert(
                            body);

                  } else {

                    await auth
                        .paymentStatusService
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
      await _loadPaymentStatuses();

      if (mounted) {
        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          SnackBar(
            content: Text(
              status == null
                  ? "Payment status added successfully"
                  : "Payment status updated successfully",
            ),

            backgroundColor:
                Colors.green,
          ),
        );
      }
    }
  }

  Future<void>
      _showPaymentMethodDialog({
    PaymentMethod? method,
  }) async {

    final formKey =
        GlobalKey<FormState>();

    final controller =
        TextEditingController(
      text: method?.name ?? "",
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

          title: Text(
            method == null
                ? "Add payment method"
                : "Edit payment method",

            style:
                const TextStyle(
              color: Colors.white,
            ),
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
                  "Payment method name",
                ),

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                ),

                decoration:
                    AdminStyles
                        .inputDecoration(
                  "Payment method name",
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

                  if (method ==
                      null) {

                    await auth
                        .paymentMethodService
                        .insert(
                            body);

                  } else {

                    await auth
                        .paymentMethodService
                        .update(
                      method.id,
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
      await _loadPaymentMethods();

      if (mounted) {
        ScaffoldMessenger.of(
                context)
            .showSnackBar(
          SnackBar(
            content: Text(
              method == null
                  ? "Payment method added successfully"
                  : "Payment method updated successfully",
            ),

            backgroundColor:
                Colors.green,
          ),
        );
      }
    }
  }

  Future<void>
      _deletePaymentStatus(
    PaymentStatus status,
  ) async {

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (_) {
        return ConfirmDeleteDialog(
          title:
              "Delete payment status",

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
            .paymentStatusService
            .delete(
          status.id,
        );

        await _loadPaymentStatuses();

        if (mounted) {
          ScaffoldMessenger.of(
                  context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Payment status deleted successfully",
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
              "Cannot delete payment status because it is in use.",
            ),

            backgroundColor:
                Colors.orange,
          ),
        );
      }
    }
  }

  Future<void>
      _deletePaymentMethod(
    PaymentMethod method,
  ) async {

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (_) {
        return ConfirmDeleteDialog(
          title:
              "Delete payment method",

          message:
              "Are you sure you want to delete ${method.name}?",
        );
      },
    );

    if (confirmed == true) {
      try {
        final auth =
            context.read<
                AuthProvider>();

        await auth
            .paymentMethodService
            .delete(
          method.id,
        );

        await _loadPaymentMethods();

        if (mounted) {
          ScaffoldMessenger.of(
                  context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Payment method deleted successfully",
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
              "Cannot delete payment method because it is in use.",
            ),

            backgroundColor:
                Colors.orange,
          ),
        );
      }
    }
  }

  Future<void>
      _loadPaymentStatuses() async {

    try {
      setState(() {
        _isLoadingStatuses =
            true;
      });

      final auth =
          context.read<
              AuthProvider>();

      final result =
          await auth
              .paymentStatusService
              .getPaged(
        page:
            _paymentStatusPage,

        pageSize:
            _paymentStatusPageSize,

        name:
            _paymentStatusSearch,
      );

      final items =
          result["items"]
              as List;

      setState(() {
        _paymentStatuses =
            items
                .map(
                  (e) =>
                      PaymentStatus
                          .fromJson(
                              e),
                )
                .toList();

        _paymentStatusTotalPages =
            result["totalPages"] ??
                1;

        _isLoadingStatuses =
            false;
      });

    } catch (e) {

      setState(() {
        _isLoadingStatuses =
            false;
      });
    }
  }

  Future<void>
      _loadPaymentMethods() async {

    try {
      setState(() {
        _isLoadingMethods =
            true;
      });

      final auth =
          context.read<
              AuthProvider>();

      final result =
          await auth
              .paymentMethodService
              .getPaged(
        page:
            _paymentMethodPage,

        pageSize:
            _paymentMethodPageSize,

        name:
            _paymentMethodSearch,
      );

      final items =
          result["items"]
              as List;

      setState(() {
        _paymentMethods =
            items
                .map(
                  (e) =>
                      PaymentMethod
                          .fromJson(
                              e),
                )
                .toList();

        _paymentMethodTotalPages =
            result["totalPages"] ??
                1;

        _isLoadingMethods =
            false;
      });

    } catch (e) {

      setState(() {
        _isLoadingMethods =
            false;
      });
    }
  }
}