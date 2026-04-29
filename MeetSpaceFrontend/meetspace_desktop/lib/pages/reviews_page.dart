import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../services/review_service.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const cardColor = Color(0xFF2E2E2E);
  static const brandOrange = Color(0xFFA56E09);

  List<ReviewResponse> _reviews = [];
  List<ReviewResponse> _filtered = [];

  bool _loading = true;
  String _search = "";

  int? _selectedRating; // null = svi
String _sort = "Newest";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      final service = ReviewService(auth.api);

      final data = await service.getAllReviews();

      setState(() {
        _reviews = data;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _applyFilters() {
  var temp = [..._reviews];

  /// SEARCH
  if (_search.isNotEmpty) {
    final q = _search.toLowerCase();

    temp = temp.where((r) {
      return (r.spaceName ?? "").toLowerCase().contains(q) ||
          (r.userName ?? "").toLowerCase().contains(q) ||
          (r.comment ?? "").toLowerCase().contains(q);
    }).toList();
  }

  /// ⭐ FILTER
  if (_selectedRating != null) {
    temp = temp.where((r) => r.rating == _selectedRating).toList();
  }

  /// 📅 SORT
  if (_sort == "Newest") {
    temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  } else {
    temp.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  _filtered = temp;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            const Text(
              "User reviews",
              style: TextStyle(
                color: brandOrange,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// SEARCH
            TextField(
              onChanged: (v) {
                setState(() {
                  _search = v;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: "Search reviews...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

Row(
  children: [
    /// ⭐ RATING FILTER
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<int?>(
        value: _selectedRating,
        underline: const SizedBox(),
        hint: const Text("Rating"),
        items: [
          const DropdownMenuItem(value: null, child: Text("All")),
          ...List.generate(5, (i) {
            final value = 5 - i;
            return DropdownMenuItem(
              value: value,
              child: Row(
                children: [
                  Text("$value"),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 16, color: Colors.orange),
                ],
              ),
            );
          })
        ],
        onChanged: (v) {
          setState(() {
            _selectedRating = v;
            _applyFilters();
          });
        },
      ),
    ),

    const SizedBox(width: 16),

    /// 📅 SORT
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<String>(
        value: _sort,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: "Newest", child: Text("Newest")),
          DropdownMenuItem(value: "Oldest", child: Text("Oldest")),
        ],
        onChanged: (v) {
          setState(() {
            _sort = v!;
            _applyFilters();
          });
        },
      ),
    ),
  ],
),
const SizedBox(height: 20),

            /// LIST
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: brandOrange,
                      ),
                    )
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No reviews found",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final r = _filtered[index];
                            return _reviewCard(r);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(ReviewResponse r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          /// LEFT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// SPACE
                Text(
                  r.spaceName ?? "Unknown space",
                  style: const TextStyle(
                    color: brandOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                /// USER
                Text(
                  r.userName ?? "Unknown user",
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 6),

                /// STARS
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < r.rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                /// COMMENT
                Text(
                  r.comment ?? "",
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 6),

                /// DATE
                Text(
                  "${r.createdAt.day}.${r.createdAt.month}.${r.createdAt.year}",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          /// DELETE
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(r),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ReviewResponse r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ICON
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 28,
                ),
              ),

              const SizedBox(height: 20),

              /// TITLE
              const Text(
                "Delete review?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              /// DESC
              const Text(
                "This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              /// ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
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
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final auth = context.read<AuthProvider>();
      final service = ReviewService(auth.api);

      await service.deleteReview(r.id);

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review deleted successfully"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}