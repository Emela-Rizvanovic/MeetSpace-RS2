import 'package:flutter/material.dart';

class AdminPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  final Function(int page) onPageSelected;

  const AdminPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    this.onPrevious,
    this.onNext,
  });

  static const brandOrange =
      Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [

        /// PREVIOUS
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.white,
          ),
        ),

        /// PAGES
        for (int i = 0; i < totalPages; i++)

          GestureDetector(
            onTap: () {
              onPageSelected(i);
            },
            child: Container(
              margin:
                  const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: currentPage == i
                    ? brandOrange
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Text(
                "${i + 1}",
                style: TextStyle(
                  color: currentPage == i
                      ? Colors.white
                      : Colors.white70,
                ),
              ),
            ),
          ),

        /// NEXT
        IconButton(
          onPressed: onNext,
          icon: const Icon(
            Icons.chevron_right,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}