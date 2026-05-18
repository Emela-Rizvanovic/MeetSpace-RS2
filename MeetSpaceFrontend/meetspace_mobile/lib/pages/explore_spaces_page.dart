import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/space.dart';
import 'menu_page.dart';
import 'space_details_page.dart';

enum ExploreMode { recommended, all, favorites }

class ExploreSpacesPage extends StatefulWidget {
  const ExploreSpacesPage({super.key});

  @override
  State<ExploreSpacesPage> createState() =>
      _ExploreSpacesPageState();
}

class _ExploreSpacesPageState
    extends State<ExploreSpacesPage> {
  static const Color bgGrey =
      Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange =
      Color.fromARGB(255, 165, 110, 9);
      ExploreMode _mode = ExploreMode.recommended;

  //bool _showFavorites = false;

  int _page = 0;
final int _pageSize = 5;
int _totalPages = 1;

  Future<List<SpaceResponse>>? _future;
  List<SpaceResponse> _spaces = [];
  List<SpaceResponse> _allSpaces = [];

  final _minPriceController = TextEditingController();
final _maxPriceController = TextEditingController();
final _minCapacityController = TextEditingController();

String _sort = "Price ↑";

  @override
  void initState() {
    super.initState();
    _future = _loadRecommended();
    _loadAllSpacesForSearch();
  }

Map<String, dynamic> _getSortParams() {
  String? sortBy;
  bool desc = false;

  switch (_sort) {
    case "Price ↑":
      sortBy = "PricePerHour";
      break;

    case "Price ↓":
      sortBy = "PricePerHour";
      desc = true;
      break;

    case "Capacity ↑":
      sortBy = "Capacity";
      break;

    case "Capacity ↓":
      sortBy = "Capacity";
      desc = true;
      break;
  }

  return {
    "sortBy": sortBy,
    "desc": desc,
  };
}

  Future<void> _loadAllSpacesForSearch() async {
  final auth = context.read<AuthProvider>();
  final data = await auth.getSpaces(); 
  setState(() {
    _allSpaces = data;
  });
}

Future<List<SpaceResponse>> _loadSpaces() async {
  final auth = context.read<AuthProvider>();
  
  if (_mode == ExploreMode.all) {
 final sort = _getSortParams();

final result = await auth.spaceService.getPaged(
  page: _page,
  pageSize: _pageSize,

  minPrice:
      _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text)
          : null,

  maxPrice:
      _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text)
          : null,

  minCapacity:
      _minCapacityController.text.isNotEmpty
          ? int.tryParse(_minCapacityController.text)
          : null,

  sortBy: sort["sortBy"],
  desc: sort["desc"],
);
_spaces = result.items;
_totalPages = result.totalPages;

return _spaces;
  }
  
  final data = await auth.getSpaces();
  _spaces = data;
  return data;
}

  Future<List<SpaceResponse>> _loadFavorites() async {
    final auth = context.read<AuthProvider>();
    return auth.getFavoriteSpaces();
  }
  
  Future<List<SpaceResponse>> _loadRecommended() async {
  final auth = context.read<AuthProvider>();
  return auth.recommendationService.getRecommendedSpaces();
}

Widget _buildFilterButton({
  required String text,
  required bool active,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 40,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? brandOrange : Colors.white,
        foregroundColor: active ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

void _showFilters() {
  showModalBottomSheet(
    context: context,
    backgroundColor: bgGrey,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),

    builder: (_) {
  return StatefulBuilder(
    builder: (context, setModalState) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          40,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// TITLE
            const Text(
              "Filters",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),

            const SizedBox(height: 22),

            /// MIN PRICE
            TextField(
              controller: _minPriceController,
              keyboardType: TextInputType.number,

              decoration:
                  _filterDecoration("Min price"),
            ),

            const SizedBox(height: 14),

            /// MAX PRICE
            TextField(
              controller: _maxPriceController,
              keyboardType: TextInputType.number,

              decoration:
                  _filterDecoration("Max price"),
            ),

            const SizedBox(height: 14),

            /// MIN CAPACITY
            TextField(
              controller: _minCapacityController,
              keyboardType: TextInputType.number,

              decoration:
                  _filterDecoration("Min people"),
            ),

            const SizedBox(height: 14),

            /// SORT
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: DropdownButton<String>(
                value: _sort,
                isExpanded: true,
                underline: const SizedBox(),

                items: const [
                  DropdownMenuItem(
                    value: "Price ↑",
                    child: Text("Price ↑"),
                  ),
                  DropdownMenuItem(
                    value: "Price ↓",
                    child: Text("Price ↓"),
                  ),
                  DropdownMenuItem(
                    value: "Capacity ↑",
                    child: Text("Capacity ↑"),
                  ),
                  DropdownMenuItem(
                    value: "Capacity ↓",
                    child: Text("Capacity ↓"),
                  ),
                ],

                onChanged: (value) {
               setModalState(() {
  _sort = value!;
});
                },
              ),
            ),

            const SizedBox(height: 22),

            /// APPLY BUTTON
        SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {
      Navigator.pop(context);

      setState(() {
        _page = 0;
        _future = _loadSpaces();
      });
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: brandOrange,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: const Text(
      "Apply filters",
      style: TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),
          ],
        ),
      );
    },
  );
},
  );
}

InputDecoration _filterDecoration(String hint) {
  return InputDecoration(
    hintText: hint,

    filled: true,
    fillColor: Colors.white,

    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 16,
    ),

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: FutureBuilder<List<SpaceResponse>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: brandOrange),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                          22, 18, 22, 18),
                  child: _ErrorBox(
                    message:
                        snapshot.error.toString(),
                    onRetry: () {
                      setState(() {
                        _future = _loadSpaces();
                      });
                    },
                  ),
                );
              }

              final spaces = snapshot.data ?? [];

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                        22, 18, 22, 18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    /// HEADER
                    _Header(
                      title: 'MEETSPACE',
                      onMenu: () =>
                          Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const MenuPage()),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Browse our\navailable spaces\nand book in\nminutes.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 44,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        color: brandOrange,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// AUTOCOMPLETE SEARCH (IDENTICAL TO HOME)
              Row(
  children: [

    /// SEARCH
    Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Autocomplete<SpaceResponse>(
          displayStringForOption:
              (space) => space.name,

          optionsBuilder:
              (TextEditingValue textEditingValue) {
            if (_allSpaces.isEmpty) {
              return const Iterable<SpaceResponse>.empty();
            }

            if (textEditingValue.text.isEmpty) {
              return _allSpaces;
            }

            return _allSpaces.where(
              (space) => space.name
                  .toLowerCase()
                  .startsWith(
                    textEditingValue.text.toLowerCase(),
                  ),
            );
          },

          onSelected: (SpaceResponse selection) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SpaceDetailsPage(
                  space: selection,
                ),
              ),
            );
          },

          fieldViewBuilder:
              (context,
                  controller,
                  focusNode,
                  onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                hintText: 'Find a space',
                border: InputBorder.none,
              ),
            );
          },

          optionsViewBuilder:
              (context, onSelected, options) {
            final optionList = options.toList();

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width:
                      MediaQuery.of(context).size.width - 90,

                  constraints:
                      const BoxConstraints(maxHeight: 250),

                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius:
                        BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),

                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: optionList.length,
                    itemBuilder: (context, index) {
                      final space = optionList[index];

                      return InkWell(
                        onTap: () => onSelected(space),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),

                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index ==
                                        optionList.length - 1
                                    ? Colors.transparent
                                    : Colors.white12,
                              ),
                            ),
                          ),

                          child: Text(
                            space.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),

    const SizedBox(width: 10),
    

    /// FILTER BUTTON
if (_mode == ExploreMode.all) ...[
  const SizedBox(width: 10),

  InkWell(
    onTap: _showFilters,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: brandOrange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.tune,
        color: Colors.white,
      ),
    ),
  ),
],
  ],
),

                    const SizedBox(height: 12),

                    /// FILTER BUTTONS
                 Row(
  children: [

    /// RECOMMENDED
    Expanded(
      child: _buildFilterButton(
        text: "Recommended",
        active: _mode == ExploreMode.recommended,
        onTap: () {
          setState(() {
            _mode = ExploreMode.recommended;
            _future = _loadRecommended();
          });
        },
      ),
    ),

    const SizedBox(width: 8),

    /// SEE ALL
    Expanded(
      child: _buildFilterButton(
        text: "See all",
        active: _mode == ExploreMode.all,
        onTap: () {
  setState(() {
    _mode = ExploreMode.all;
    _page = 0;  // 👈 resetuj
    _future = _loadSpaces();
  });
},
      ),
    ),

    const SizedBox(width: 8),

    /// FAVORITES
    Expanded(
      child: _buildFilterButton(
        text: "Favorites",
        active: _mode == ExploreMode.favorites,
        onTap: () {
          setState(() {
            _mode = ExploreMode.favorites;
            _future = _loadFavorites();
          });
        },
      ),
    ),
  ],
),

                    const SizedBox(height: 16),

                    if (spaces.isEmpty)
                      const _EmptyBox(
                          text:
                              "No spaces available.")
                    else
                      ...spaces.map(
                        (s) => Padding(
                          padding:
                              const EdgeInsets.only(
                                  bottom: 18),
                          child: InkWell(
                            borderRadius:
                                BorderRadius
                                    .circular(16),
                                    
                            onTap: () async {
  final auth = context.read<AuthProvider>();

  if (_mode == ExploreMode.recommended) {
    try {
      await auth.recommendationService.markClicked(s.id);
    } catch (e) {
      debugPrint("Click tracking failed: $e");
    }
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SpaceDetailsPage(space: s),
    ),
  );

  setState(() {
    switch (_mode) {
      case ExploreMode.recommended:
        _future = _loadRecommended();
        break;
      case ExploreMode.all:
        _future = _loadSpaces();
        break;
      case ExploreMode.favorites:
        _future = _loadFavorites();
        break;
    }
  });
},
                            child:
                                _SpaceCard(
                                    space: s),
                          ),
                        ),
                      ),
                       if (_mode == ExploreMode.all) ...[
                      const SizedBox(height: 8),
                      _buildPagination(),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
  return Center(
    child: Container(
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
                    _future = _loadSpaces();
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
                _future = _loadSpaces();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _page == i ? brandOrange : Colors.transparent,
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
                    _future = _loadSpaces();
                  }
                : null,
            child: Icon(
              Icons.chevron_right,
              color: _page < _totalPages - 1 ? Colors.white : Colors.white24,
            ),
          ),
        ],
      ),
    ),
  );
}
}


class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onMenu;

  const _Header({required this.title, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: "Poppins",
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
            fontSize: 20,
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onMenu,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.menu, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({required this.space});

  final SpaceResponse space;


  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {

     debugPrint(
    'SPACE ${space.id} → images=${space.images.length}, '
    'first="${space.firstImageOrEmpty}"'
  );

    final imageUrl = space.firstImageOrEmpty;
    
    final price = space.pricePerHour > 0
    ? "BAM ${space.pricePerHour.toStringAsFixed(0)}"
    : "BAM -";

final capacityText = space.capacity > 0
    ? "Up to ${space.capacity} people"
    : "Capacity not set";

final address = (space.facilityAddress ?? '').trim().isEmpty
    ? 'Address not available'
    : space.facilityAddress!.trim();

final rating = space.averageRating;
final reviewCount = space.totalReviews;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFEDEDED),
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: Colors.black45),
                      ),
                    )
                  : Image.network(
    imageUrl,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      debugPrint(
        'IMAGE ERROR space=${space.id} url=$imageUrl → $error',
      );
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
  ),

            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),

Row(
  children: [
    const Icon(
      Icons.star,
      size: 18,
      color: Color(0xFFFFB300),
    ),
    const SizedBox(width: 6),
    Text(
      reviewCount > 0
          ? rating.toStringAsFixed(1)
          : "New",
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    if (reviewCount > 0) ...[
      const SizedBox(width: 6),
      Text(
        "($reviewCount)",
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6D6D6D),
        ),
      ),
    ],
  ],
),
                  const SizedBox(height: 10),
                  Text(
  address,
  style: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6D6D6D),
  ),
),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 18, color: Color(0xFF6D6D6D)),
                      const SizedBox(width: 8),
                      Text(
                        capacityText,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: brandOrange,
                        ),
                      ),
                      const Text(
                        ' / hour',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: "Poppins",
          color: Colors.black54,
          fontWeight: FontWeight.w300,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Failed to load spaces",
            style: TextStyle(
              fontFamily: "Poppins",
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: "Poppins",
              color: Colors.black54,
              fontWeight: FontWeight.w300,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
