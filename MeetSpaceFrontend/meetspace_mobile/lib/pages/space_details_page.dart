import 'package:flutter/material.dart';
import '../models/space.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'calendar_page.dart';

class SpaceDetailsPage extends StatefulWidget {
  final SpaceResponse space;

  const SpaceDetailsPage({super.key, required this.space});

  @override
  State<SpaceDetailsPage> createState() => _SpaceDetailsPageState();
}

class _SpaceDetailsPageState extends State<SpaceDetailsPage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);
 
  bool _isFavorite = false;
bool _loadingFavorite = true;


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
  _checkIfFavorite();
}

Future<void> _checkIfFavorite() async {
  final auth = context.read<AuthProvider>();

  final favorites = await auth.getFavoriteSpaces();

  setState(() {
    _isFavorite =
        favorites.any((f) => f.id == widget.space.id);
    _loadingFavorite = false;
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

  // ✅ NEW: otvori fullscreen galeriju
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
    final s = widget.space;

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
        child: Column(
          children: [
            // TOP: images + thumbnails
            _TopGallery(
              imageUrls: _imageUrls,
              pageController: _pageController,
              pageIndex: _pageIndex,
              onPageChanged: (i) => setState(() => _pageIndex = i),
              onBack: () => Navigator.pop(context),
              onThumbTap: (i) {
                _goTo(i);
                _openFullscreen(i); // ✅ NEW: tap thumb opens fullscreen
              },
              onMainTap: () => _openFullscreen(_pageIndex), // ✅ NEW
            ),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
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
                    const SizedBox(height: 18), // prostor zbog bottom bara
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
      final title = a.name.trim().isEmpty ? 'Amenity' : a.name.trim();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

     bottomNavigationBar: Container(
  color: const Color(0xFF2E2E2E),
  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [

      /// TOP ROW (price + favorite)
      Row(
        children: [

          // PRICE
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

          // FAVORITES WITH HEART ICON
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _isFavorite
                      ? Colors.red
                      : brandOrange,
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

      /// SEE AVAILABLE DATES BUTTON
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CalendarPage(
        space: widget.space,
      ),
    ),
  );
},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
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
                              debugPrint('DETAIL IMAGE ERROR url=$url → $error');
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
