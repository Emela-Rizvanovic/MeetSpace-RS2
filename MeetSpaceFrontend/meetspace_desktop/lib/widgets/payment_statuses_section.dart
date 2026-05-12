import 'package:flutter/material.dart';
import '../../../models/payment_status.dart';
import 'admin_pagination.dart';
import 'admin_styles.dart';

class PaymentStatusesSection extends StatelessWidget {
  final List<PaymentStatus> paymentStatuses;

  final bool isLoading;

  final int currentPage;
  final int totalPages;

  final Function(String) onSearch;

  final VoidCallback onAdd;

  final Function(PaymentStatus) onEdit;
  final Function(PaymentStatus) onDelete;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  final Function(int) onPageSelected;

  const PaymentStatusesSection({
    super.key,
    required this.paymentStatuses,
    required this.isLoading,
    required this.currentPage,
    required this.totalPages,
    required this.onSearch,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        /// HEADER
        Row(
          children: [

            const Text(
              "Payment statuses",
              style: TextStyle(
                color:
                    AdminStyles.brandOrange,
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label:
                  const Text("Add status"),
              style:
                  AdminStyles.primaryButton,
            ),
          ],
        ),

        const SizedBox(height: 24),

        /// SEARCH
        TextField(
          onChanged: onSearch,
          decoration:
              AdminStyles.searchDecoration(
            "Search payment statuses...",
          ),
        ),

        const SizedBox(height: 24),

        /// TABLE
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color:
                  AdminStyles.cardColor,
              borderRadius:
                  BorderRadius.circular(
                      20),
            ),
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: AdminStyles
                          .brandOrange,
                    ),
                  )
                : Column(
                    children: [

                      /// HEADER
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        decoration:
                            const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  Colors.white12,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [

                            Expanded(
                              child: Text(
                                "Status name",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white70,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(
                              width: 120,
                              child: Text(
                                "Actions",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white70,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// LIST
                      Expanded(
                        child:
                            ListView.separated(
                          itemCount:
                              paymentStatuses.length,
                          separatorBuilder:
                              (_, __) =>
                                  const Divider(
                            height: 1,
                            color:
                                Colors.white12,
                          ),
                          itemBuilder:
                              (context, index) {
                            final type =
                                paymentStatuses[index];

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [

                                  Expanded(
                                    child: Text(
                                      type.name,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      children: [

                                        IconButton(
                                          onPressed:
                                              () {
                                            onEdit(
                                                type);
                                          },
                                          icon:
                                              const Icon(
                                            Icons.edit,
                                            color:
                                                Colors.orange,
                                          ),
                                        ),

                                        IconButton(
                                          onPressed:
                                              () {
                                            onDelete(
                                                type);
                                          },
                                          icon:
                                              const Icon(
                                            Icons.delete,
                                            color:
                                                Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                          height: 10),

                      AdminPagination(
                        currentPage:
                            currentPage,
                        totalPages:
                            totalPages,
                        onPrevious:
                            onPrevious,
                        onNext: onNext,
                        onPageSelected:
                            onPageSelected,
                      ),

                      const SizedBox(
                          height: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}