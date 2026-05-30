import 'package:flutter/material.dart';
import '../../../models/facility.dart';
import 'admin_pagination.dart';
import 'admin_styles.dart';

class FacilitiesSection extends StatelessWidget {
  final List<Facility> facilities;

  final bool isLoading;

  final int currentPage;
  final int totalPages;

  final Function(String) onSearch;

  final VoidCallback onAdd;

  final Function(Facility) onEdit;
  final Function(Facility) onDelete;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  final Function(int) onPageSelected;

  const FacilitiesSection({
    super.key,
    required this.facilities,
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

        Row(
          children: [

            const Text(
              "Facilities",
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
                  const Text("Add facility"),
              style:
                  AdminStyles.primaryButton,
            ),
          ],
        ),

        const SizedBox(height: 24),

        TextField(
          onChanged: onSearch,
          decoration:
              AdminStyles.searchDecoration(
            "Search facilities...",
          ),
        ),

        const SizedBox(height: 24),

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
                              flex: 2,
                              child: Text(
                                "Facility",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white70,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Text(
                                "City",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white70,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Text(
                                "Country",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white70,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            Expanded(
                              flex: 2,
                              child: Text(
                                "Address",
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

                      Expanded(
                        child:
                            ListView.separated(
                          itemCount:
                              facilities.length,
                          separatorBuilder:
                              (_, __) =>
                                  const Divider(
                            height: 1,
                            color:
                                Colors.white12,
                          ),
                          itemBuilder:
                              (context, index) {
                            final facility =
                                facilities[index];

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [

                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      facility.name,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Text(
                                      facility
                                          .cityName,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white70,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Text(
                                      facility
                                          .countryName,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white70,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      facility
                                          .address,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white70,
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
                                                facility);
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
                                                facility);
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