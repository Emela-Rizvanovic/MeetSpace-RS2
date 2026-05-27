import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/amenity.dart';
import '../providers/auth_provider.dart';
import 'add_amenity_dialog.dart';
import 'amenity_categories_dialog.dart';

class AmenitiesPage extends StatefulWidget {
  const AmenitiesPage({super.key});

  @override
  State<AmenitiesPage> createState() => _AmenitiesPageState();
}

class _AmenitiesPageState extends State<AmenitiesPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  List<AmenityResponse> _amenities = [];

  bool _isLoading = true;

  String _search = "";
  String _sort = "Newest first";

  int _page = 0;
final int _pageSize = 10; 

int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadAmenities();
  }

  Future<void> _loadAmenities() async {
  try {
    final auth = context.read<AuthProvider>();

    final sort = _getSortParams();

final result = await auth.amenityService.getPaged(
  page: _page,
  pageSize: _pageSize,
  name: _search.isNotEmpty ? _search : null,
  sortBy: sort["sortBy"],
  desc: sort["desc"],
);

    setState(() {
      _amenities = result.items;
      _totalPages = result.totalPages;
      _isLoading = false;
    });
  } catch (_) {
  if (!mounted) return;
  setState(() {
    _isLoading = false;
  });
}
}

  Map<String, dynamic> _getSortParams() {
  String? sortBy;
  bool desc = false;

  switch (_sort) {
    case "Newest first":
  sortBy = "Id";
  desc = true;
  break;
    case "Name ↑":
      sortBy = "Name";
      desc = false;
      break;
    case "Name ↓":
      sortBy = "Name";
      desc = true;
      break;
    case "Price ↑":
      sortBy = "Price";
      desc = false;
      break;
    case "Price ↓":
      sortBy = "Price";
      desc = true;
      break;
  }

  return {
    "sortBy": sortBy,
    "desc": desc,
  };
}

Future<void> _deleteAmenity(AmenityResponse amenity) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
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
              "Delete amenity?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            /// DESCRIPTION
            Text(
              "This action cannot be undone.\n'${amenity.name}' will be permanently removed.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            /// ACTIONS
            Row(
              children: [
                /// CANCEL
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),

                const SizedBox(width: 12),

                /// DELETE
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

    await auth.amenityService.deleteAmenity(amenity.id);

    await _loadAmenities(); // refresh (za razliku od spaces)

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Amenity deleted successfully"),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
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
            /// LOGO
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

            const SizedBox(height: 10),

            /// HEADER
            Row(
              children: [
                const Text(
                  "Modern amenities",
                  style: TextStyle(
                    color: brandOrange,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    /// ADD BUTTON
                    ElevatedButton(
                  onPressed: () async {
  final auth = context.read<AuthProvider>();

  final categoriesResult =
      await auth.amenityCategoryService.getPaged(
    page: 0,
    pageSize: 1,
  );

  final hasCategories =
      (categoriesResult["items"] as List).isNotEmpty;

  if (!hasCategories) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Add at least one amenity category before creating an amenity.",
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final result = await showDialog(
    context: context,
    builder: (_) => const AddAmenityDialog(),
  );

  if (result == "created") {
  setState(() {
    _sort = "Newest first";
    _page = 0;
  });

  await _loadAmenities();

  ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Amenity added successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }
},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Add new amenity"),
                    ),

                  const SizedBox(width: 16),

OutlinedButton.icon(
  onPressed: () async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AmenityCategoriesDialog(),
    );
  },
  icon: const Icon(Icons.settings),
  label: const Text("Manage categories"),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white24),
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    minimumSize: const Size(0, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),

        const SizedBox(width: 16),

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
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: const [
                          DropdownMenuItem(value: "Newest first", child: Text("Newest first")),
                          DropdownMenuItem(value: "Name ↑", child: Text("Name ↑")),
                          DropdownMenuItem(value: "Name ↓", child: Text("Name ↓")),
                          DropdownMenuItem(value: "Price ↑", child: Text("Price ↑")),
                          DropdownMenuItem(value: "Price ↓", child: Text("Price ↓")),
                        ],
                       onChanged: (value) {
  setState(() {
    _sort = value!;
    _page = 0;
  });

  _loadAmenities();
},
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// SEARCH
            TextField(
             onChanged: (value) {
  setState(() {
    _search = value;
    _page = 0; 
  });
  _loadAmenities();
},
              decoration: InputDecoration(
                hintText: "Quick search",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// LIST
          Expanded(
  child: _isLoading
      ? const Center(
          child: CircularProgressIndicator(color: brandOrange),
        )
      : SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _amenities.length,
                  itemBuilder: (context, index) {
                    final amenity = _amenities[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.black54),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  amenity.name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (amenity.description != null)
                                  Text(
                                    amenity.description!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Text(
                            "${amenity.price.toStringAsFixed(0)} BAM",
                            style: const TextStyle(
                              color: brandOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 10),

                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (_) =>
                                    AddAmenityDialog(amenity: amenity),
                              );

                              if (result == "updated") {
                                await _loadAmenities();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Amenity updated successfully"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAmenity(amenity),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
                  _loadAmenities();
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
              _loadAmenities();
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
                  _loadAmenities();
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
}