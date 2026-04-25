import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/space.dart';
import '../providers/auth_provider.dart';
import 'add_space_dialog.dart';
import 'space_details_page.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  List<SpaceResponse> _spaces = [];
  List<SpaceResponse> _filtered = [];

  bool _isLoading = true;

  String _search = "";
  String _sort = "Price ↑";

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    try {
      final auth = context.read<AuthProvider>();
      final data = await auth.getSpaces();

      setState(() {
        _spaces = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _applyFilters() {
    List<SpaceResponse> temp = [..._spaces];

    /// SEARCH
   if (_search.isNotEmpty) {
  final query = _search.toLowerCase();

  temp = temp.where((s) {
    final nameWords = s.name.toLowerCase().split(' ');
    final facilityWords = (s.facilityName ?? '').toLowerCase().split(' ');

    return nameWords.any((w) => w.startsWith(query)) ||
        facilityWords.any((w) => w.startsWith(query));
  }).toList();
}

    /// SORT
    switch (_sort) {
      case "Price ↑":
        temp.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case "Price ↓":
        temp.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
        break;
      case "Capacity":
        temp.sort((a, b) => b.capacity.compareTo(a.capacity));
        break;
      case "Rating":
        temp.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
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
            /// HEADER
           Row(
  children: [
    const Text(
      "Available locations",
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
    builder: (_) => const AddSpaceDialog(),
  );

  if (result == "created") {
    await _loadSpaces();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Space added successfully"),
        backgroundColor: Colors.green,
      ),
    );
  } 
},
  style: ElevatedButton.styleFrom(
    backgroundColor: brandOrange,
    foregroundColor: Colors.white, 
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
     minimumSize: const Size(0, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
  child: const Text(
    "Add new location",
    style: TextStyle(
      fontWeight: FontWeight.w600,
    ),
  ),
),

        const SizedBox(width: 16),

        /// SORT
    Container(
  height: 52, // 👈 isto kao button visina
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
      DropdownMenuItem(value: "Price ↑", child: Text("Price ↑")),
      DropdownMenuItem(value: "Price ↓", child: Text("Price ↓")),
      DropdownMenuItem(value: "Capacity", child: Text("Capacity")),
      DropdownMenuItem(value: "Rating", child: Text("Rating")),
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

            /// SEARCH BAR
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
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// GRID
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandOrange),
                    )
                  : GridView.builder(
                      itemCount: _filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 25,
                        mainAxisSpacing: 25,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final s = _filtered[index];

                        return GestureDetector(
                      onTap: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SpaceDetailsPage(space: s),
    ),
  );

  if (result == "updated") {
    await _loadSpaces();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Space updated successfully"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  if (result == "deleted") {
    await _loadSpaces();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Space deleted successfully"),
        backgroundColor: Colors.red,
      ),
    );
  }
},
                          child: _AdminSpaceCard(space: s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSpaceCard extends StatelessWidget {
  final SpaceResponse space;

  const _AdminSpaceCard({required this.space});

  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    final imageUrl = space.firstImageOrEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isEmpty
                ? Container(
                    height: 120,
                    color: const Color(0xFFEDEDED),
                    child: const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),

          const SizedBox(height: 12),

          /// NAME
          Text(
            space.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          /// ADDRESS
          Text(
            space.facilityAddress ?? "No address",
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          /// CAPACITY
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16),
              const SizedBox(width: 6),
              Text("up to ${space.capacity} people"),
            ],
          ),

          const Spacer(),

          /// PRICE
          Text(
            "BAM ${space.pricePerHour.toStringAsFixed(0)} / hour",
            style: const TextStyle(
              color: brandOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}