import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/amenity.dart';
import '../providers/auth_provider.dart';
import 'add_amenity_dialog.dart';

class AmenitiesPage extends StatefulWidget {
  const AmenitiesPage({super.key});

  @override
  State<AmenitiesPage> createState() => _AmenitiesPageState();
}

class _AmenitiesPageState extends State<AmenitiesPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  List<AmenityResponse> _amenities = [];
  List<AmenityResponse> _filtered = [];

  bool _isLoading = true;

  String _search = "";
  String _sort = "Name ↑";

  @override
  void initState() {
    super.initState();
    _loadAmenities();
  }

  Future<void> _loadAmenities() async {
    try {
      final auth = context.read<AuthProvider>();
      final data = await auth.getAmenities();

      setState(() {
        _amenities = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _applyFilters() {
    List<AmenityResponse> temp = [..._amenities];

    /// SEARCH
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();

      temp = temp.where((a) {
        final words = a.name.toLowerCase().split(' ');
        return words.any((w) => w.startsWith(query));
      }).toList();
    }

    /// SORT
    switch (_sort) {
      case "Name ↑":
        temp.sort((a, b) => a.name.compareTo(b.name));
        break;
      case "Name ↓":
        temp.sort((a, b) => b.name.compareTo(a.name));
        break;
      case "Price ↑":
        temp.sort((a, b) => a.price.compareTo(b.price));
        break;
      case "Price ↓":
        temp.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    _filtered = temp;
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
            const Text(
              "MEETSPACE",
              style: TextStyle(
                color: Colors.white70,
                letterSpacing: 4,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 30),

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
  final result = await showDialog(
    context: context,
    builder: (_) => const AddAmenityDialog(),
  );

  if (result == "created") {
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
                          DropdownMenuItem(value: "Name ↑", child: Text("Name ↑")),
                          DropdownMenuItem(value: "Name ↓", child: Text("Name ↓")),
                          DropdownMenuItem(value: "Price ↑", child: Text("Price ↑")),
                          DropdownMenuItem(value: "Price ↓", child: Text("Price ↓")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sort = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// SEARCH
            TextField(
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _applyFilters();
                });
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

            const SizedBox(height: 30),

            /// LIST
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandOrange),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final amenity = _filtered[index];

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

                                /// PRICE
                                Text(
                                  "${amenity.price.toStringAsFixed(0)} BAM",
                                  style: const TextStyle(
                                    color: brandOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                /// EDIT
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () async {
  final result = await showDialog(
    context: context,
    builder: (_) => AddAmenityDialog(amenity: amenity),
  );

  if (result == "updated") {
    await _loadAmenities();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Amenity updated successfully"),
        backgroundColor: Colors.orange,
      ),
    );
  }
},
                                ),

                                /// DELETE
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
            ),
          ],
        ),
      ),
    );
  }
}