import 'package:flutter/material.dart';
import '../models/space.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'calendar_page.dart';
import '../models/review.dart';

class SpaceDetailsPage extends StatefulWidget {
  final SpaceResponse space;

  const SpaceDetailsPage({super.key, required this.space});

  @override
  State<SpaceDetailsPage> createState() => _SpaceDetailsPageState();
}

class _SpaceDetailsPageState extends State<SpaceDetailsPage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

double _averageRating = 0;
int _totalReviews = 0;

  bool _isFavorite = false;
  bool _loadingFavorite = true;

  List<ReviewResponse> _reviews = [];
  ReviewResponse? _myReview;
  bool _loadingReviews = true;

  SpaceResponse? _space;
bool _loadingSpace = true;

  late final PageController _pageController;
  int _pageIndex = 0;

  List<String> get _imageUrls => widget.space.images
      .map((e) => e.imageUrl.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSpace();
    _checkIfFavorite();
    _loadReviews();
    _refreshSummary();
  }

  Future<void> _loadSpace() async {
  try {
    final auth = context.read<AuthProvider>();

    final data =
        await auth.spaceService.getById(widget.space.id);

    setState(() {
      _space = data;
      _loadingSpace = false;
    });
  } catch (e) {
    setState(() {
      _loadingSpace = false;
    });
  }
}

  Future<void> _checkIfFavorite() async {
    final auth = context.read<AuthProvider>();
    final favorites = await auth.getFavoriteSpaces();

    setState(() {
      _isFavorite = favorites.any((f) => f.id == widget.space.id);
      _loadingFavorite = false;
    });
  }

Future<void> _loadReviews() async {
  try {
    final auth = context.read<AuthProvider>();
    final data = await auth.getReviewsBySpace(widget.space.id);

    ReviewResponse? my;

    if (auth.user != null) {
      for (final r in data) {
        if (r.userId == auth.user!.id) {
          my = r;
          break;
        }
      }
    }

    setState(() {
      _reviews = data;
      _myReview = my;
      _loadingReviews = false;
    });
  } catch (e) {
    setState(() {
      _loadingReviews = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to load reviews: $e")),
    );
  }
}

  void _openReviewForm() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewForm(
      spaceId: widget.space.id,
      existingReview: _myReview,
      onSuccess: () async {
  await _loadReviews();
  await _refreshSummary();
},
    ),
  );
}

Future<void> _refreshSummary() async {
  final auth = context.read<AuthProvider>();

  final summary = await auth.getReviewSummary(widget.space.id);

  setState(() {
    _averageRating = (summary["averageRating"] ?? 0).toDouble();
    _totalReviews = summary["totalReviews"] ?? 0;
  });
}

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _imageUrls.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _openFullscreen(int initialIndex) {
    if (_imageUrls.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenGallery(
          imageUrls: _imageUrls,
          initialIndex: initialIndex.clamp(0, _imageUrls.length - 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
   if (_loadingSpace) {
  return const Scaffold(
    backgroundColor: bgGrey,
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}

final s = _space ?? widget.space;

    final address = (s.facilityAddress ?? '').trim().isEmpty
        ? 'Address not available'
        : s.facilityAddress!.trim();

    final capacityText =
        s.capacity > 0 ? 'Up to ${s.capacity} people' : 'Capacity not set';

    final priceText = s.pricePerHour > 0
        ? 'BAM ${s.pricePerHour.toStringAsFixed(0)}'
        : 'BAM -';

    final description = (s.description).trim().isEmpty
        ? 'No description available.'
        : s.description.trim();

    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// GALERIJA 
              _TopGallery(
                imageUrls: _imageUrls,
                pageController: _pageController,
                pageIndex: _pageIndex,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                onBack: () => Navigator.pop(context),
                onThumbTap: (i) {
                  _goTo(i);
                  _openFullscreen(i);
                },
                onMainTap: () => _openFullscreen(_pageIndex),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      s.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 34,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
  children: [
    Icon(
      Icons.star,
      color: _totalReviews > 0
          ? Colors.amber
          : Colors.white38,
      size: 20,
    ),
    const SizedBox(width: 6),
    Text(
      _totalReviews > 0
          ? '${_averageRating.toStringAsFixed(1)} ($_totalReviews)'
          : 'New',
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  ],
),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white70, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white60,
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            color: Colors.white70, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            capacityText,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 12),

                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white60,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Space amenities',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (s.amenities.isEmpty)
                      const Text(
                        'No amenities listed.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white60,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: s.amenities.map((a) {
                          final title =
                              a.name.trim().isEmpty ? 'Amenity' : a.name.trim();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E2E2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 28),

                    Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [

    const Text(
      'Reviews',
      style: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    ),

  TextButton.icon(
  onPressed: _loadingReviews ? null : _openReviewForm,
  icon: Icon(
    _myReview == null
        ? Icons.rate_review_outlined
        : Icons.edit_outlined,
    size: 18,
    color: brandOrange,
  ),
  label: Text(
    _myReview == null
        ? "Leave review"
        : "Edit review",
    style: const TextStyle(
      fontFamily: 'Poppins',
      color: brandOrange,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
  ),
  style: TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8),
  ),
),
  ],
),

const SizedBox(height: 12),

                    if (_loadingReviews)
                      const Center(
                        child:
                            CircularProgressIndicator(color: brandOrange),
                      )
                    else if (_reviews.isEmpty)
                      const Text(
                        'No reviews yet. Be the first to review this space.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white60,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      )
                    else
                      Column(
                        children: _reviews.map((r) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E2E2E),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < r.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  r.userName ?? "Anonymous",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (r.comment != null &&
                                    r.comment!.trim().isNotEmpty)
                                  Text(
                                    r.comment!.trim(),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

    
      bottomNavigationBar: Container(
        color: const Color(0xFF2E2E2E),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 16),
                        children: [
                          TextSpan(
                            text: priceText,
                            style: const TextStyle(
                              color: brandOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(
                            text: ' / hour',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        _isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                            _isFavorite ? Colors.red : brandOrange,
                      ),
                      label: Text(
                        _isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: _loadingFavorite
                          ? null
                          : () async {
                              final auth =
                                  context.read<AuthProvider>();

                              try {
                                if (_isFavorite) {
                                  await auth.removeFavorite(
                                      widget.space.id);
                                  setState(
                                      () => _isFavorite = false);

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Removed from favorites')),
                                  );
                                } else {
                                  await auth.addFavorite(
                                      widget.space.id);
                                  setState(
                                      () => _isFavorite = true);

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Added to favorites')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Error: $e')),
                                );
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isFavorite
                            ? Colors.red
                            : brandOrange,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _isFavorite
                              ? Colors.red
                              : brandOrange,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CalendarPage(space: _space ?? widget.space),
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
                  'See available dates',
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
    );
  }
}

class _TopGallery extends StatelessWidget {
  const _TopGallery({
    required this.imageUrls,
    required this.pageController,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onBack,
    required this.onThumbTap,
    required this.onMainTap, // ✅ NEW
  });

  final List<String> imageUrls;
  final PageController pageController;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final ValueChanged<int> onThumbTap;
  final VoidCallback onMainTap; // ✅ NEW

  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    final hasImages = imageUrls.isNotEmpty;

    return Column(
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: hasImages
                  ? GestureDetector(
                      onTap: onMainTap, // ✅ NEW: tap main image opens fullscreen
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: imageUrls.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, i) {
                          final url = imageUrls[i];
                          return Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFEDEDED),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.black45,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    )
                  : Container(
                      color: const Color(0xFFEDEDED),
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: Colors.black45),
                      ),
                    ),
            ),

            Positioned(
              left: 12,
              top: 12,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
            ),

            if (hasImages && imageUrls.length > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${pageIndex + 1}/${imageUrls.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),

        if (hasImages)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: List.generate(
                imageUrls.length >= 2 ? 2 : 1,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: i == 0 && (imageUrls.length >= 2) ? 10 : 0),
                    child: InkWell(
                      onTap: () => onThumbTap(i), // opens fullscreen too
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: i == pageIndex
                                ? brandOrange
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrls[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEDEDED),
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined,
                                    color: Colors.black45),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ✅ NEW: Fullscreen gallery
class _FullscreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullscreenGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = urls[i];
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: Colors.white70, size: 40),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Back
            Positioned(
              left: 12,
              top: 12,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),

            // Counter
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_index + 1}/${urls.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  final int spaceId;
  final ReviewResponse? existingReview;
  final VoidCallback onSuccess;

  const _ReviewForm({
    required this.spaceId,
    required this.onSuccess,
    this.existingReview,
  });

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  int? _rating;
  final _commentController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  bool get _isEdit => widget.existingReview != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      _rating = widget.existingReview!.rating;
      _commentController.text =
          widget.existingReview!.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: Text(
                _isEdit ? "Edit your review" : "Leave a review!",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Rating",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                      _errorMessage = null;
                    });
                  },
                  icon: Icon(
                    index < (_rating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: "Write your experience (optional)",
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEdit ? "Update" : "Submit",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            if (_isEdit) ...[
  const SizedBox(height: 10),
  SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      onPressed: _loading ? null : _deleteReview,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        "Delete review",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

Future<void> _deleteReview() async {
  final confirmed = await showDialog<bool>(
  context: context,
  builder: (_) => Dialog(
    backgroundColor: const Color(0xFF2E2E2E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Delete review?",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Are you sure? This action cannot be undone.",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.5,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [

              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFA56E09), // brandOrange
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
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

  setState(() => _loading = true);

  try {
    final auth = context.read<AuthProvider>();

    await auth.deleteReview(widget.existingReview!.id);

    widget.onSuccess();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review deleted"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
    });
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}


  Future<void> _submit() async {
    if (_rating == null) {
      setState(() {
        _errorMessage = "Rating is required.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      if (_isEdit) {
        await auth.updateReview(
          reviewId: widget.existingReview!.id,
          rating: _rating!,
          comment: _commentController.text.trim(),
        );
      } else {
        await auth.createReview(
          spaceId: widget.spaceId,
          rating: _rating!,
          comment: _commentController.text.trim(),
        );
      }

      widget.onSuccess();

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? "Review updated" : "Review submitted"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}