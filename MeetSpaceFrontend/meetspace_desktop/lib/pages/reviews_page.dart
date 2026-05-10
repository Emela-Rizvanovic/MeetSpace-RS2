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

  bool _loading = true;
  String _search = "";

  //int? _selectedRating; 
String _sort = "Newest";

int _page = 0;
final int _pageSize = 5;
int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

 Future<void> _load() async {
  try {
    final auth = context.read<AuthProvider>();
    final service = ReviewService(auth.api);

    final sort = _getSortParams();

    final result = await service.getPaged(
      page: _page,
      pageSize: _pageSize,
      search: _search.isNotEmpty ? _search : null,
      /*rating: _selectedRating,*/
      sortBy: sort["sortBy"],
      desc: sort["desc"],
    );

    setState(() {
     _reviews = result.items;
      _totalPages = result.totalPages;
      _loading = false;
    });
  } catch (e) {
    debugPrint(e.toString());
  }
}

Map<String, dynamic> _getSortParams() {
  String? sortBy;
  bool desc = false;

  switch (_sort) {
    case "Newest":
      sortBy = "CreatedAt";
      desc = true;
      break;
    case "Oldest":
      sortBy = "CreatedAt";
      desc = false;
      break;
  }

  return {
    "sortBy": sortBy,
    "desc": desc,
  };
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
            /// TOP BAR
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

const SizedBox(height: 30),
            /// TITLE
           Row(
  children: [
    const Text(
      "User reviews",
      style: TextStyle(
        color: brandOrange,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
    ),

    const Spacer(),

    /// ⭐ RATING
    /*Container(
      height: 52,
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
              child: Text("$value ★"),
            );
          })
        ],
        onChanged: (v) {
          setState(() {
            _selectedRating = v;
            _page = 0;
          });
          _load(); // 🔥 BITNO
        },
      ),
    ),

    const SizedBox(width: 12),*/

    /// SORT
    Container(
      height: 52,
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
            _page = 0;
          });
          _load(); // 🔥 BITNO
        },
      ),
    ),
  ],
),
const SizedBox(height: 20),

            /// SEARCH
            TextField(
          onChanged: (v) {
  setState(() {
    _search = v;
    _page = 0;  
  });
  _load();  
},
              decoration: InputDecoration(
                hintText: "Search reviews by user name or space name",
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

            /// LIST
          Expanded(
  child: _loading
      ? const Center(
          child: CircularProgressIndicator(color: brandOrange),
        )
      : _reviews.isEmpty
          ? const Center(
              child: Text(
                "No reviews found",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      return _reviewCard(_reviews[index]);
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
        GestureDetector(
          onTap: _page > 0
              ? () {
                  setState(() => _page--);
                  _load();
                }
              : null,
          child: Icon(
            Icons.chevron_left,
            color: _page > 0 ? Colors.white : Colors.white24,
          ),
        ),

        const SizedBox(width: 8),

        for (int i = 0; i < _totalPages; i++)
          GestureDetector(
            onTap: () {
              setState(() => _page = i);
              _load();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

        GestureDetector(
          onTap: _page < _totalPages - 1
              ? () {
                  setState(() => _page++);
                  _load();
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
                /*Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < r.rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 8),*/

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