import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/space.dart';
import '../providers/auth_provider.dart';
import 'add_space_dialog.dart';
import 'space_details_page.dart';
import 'reference_data_dialog.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  List<SpaceResponse> _spaces = [];

  bool _isLoading = true;

  String _search = "";
  final _minPriceController =
    TextEditingController();

final _maxPriceController =
    TextEditingController();

final _minCapacityController =
    TextEditingController();

final _maxCapacityController =
    TextEditingController();

  String _sort = "Price ↑";

  int _page = 0;
final int _pageSize = 6;

int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

 Future<void> _loadSpaces() async {
  try {
    final auth = context.read<AuthProvider>();

    final sort = _getSortParams();

final result = await auth.spaceService.getPaged(
  page: _page,
  pageSize: _pageSize,
  name: _search.isNotEmpty ? _search : null,
  sortBy: sort["sortBy"],
  desc: sort["desc"],
  minPrice:
    _minPriceController.text.isNotEmpty
        ? double.tryParse(
            _minPriceController.text)
        : null,

maxPrice:
    _maxPriceController.text.isNotEmpty
        ? double.tryParse(
            _maxPriceController.text)
        : null,

minCapacity:
    _minCapacityController.text.isNotEmpty
        ? int.tryParse(
            _minCapacityController.text)
        : null,

maxCapacity:
    _maxCapacityController.text.isNotEmpty
        ? int.tryParse(
            _maxCapacityController.text)
        : null,
);

    setState(() {
      _spaces = result.items;
      _totalPages = result.totalPages;
      _isLoading = false;
    });
  } catch (e) {
    debugPrint(e.toString());
  }
}

  Map<String, dynamic> _getSortParams() {
  String? sortBy;
  bool desc = false;

  switch (_sort) {
    case "Price ↑":
      sortBy = "PricePerHour";
      desc = false;
      break;
    case "Price ↓":
      sortBy = "PricePerHour";
      desc = true;
      break;
    case "Capacity ↑":
      sortBy = "Capacity";
      desc = false;
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
  /// HEADER
Row(
  children: [

    /// BACK BUTTON
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

    /// LOGO
    const Text(
      "MEETSPACE",
      style: TextStyle(
        color: Colors.white70,
        letterSpacing: 4,
        fontSize: 18,
      ),
    ),

     const SizedBox(height: 10),

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
    "Add new space",
    style: TextStyle(
      fontWeight: FontWeight.w600,
    ),
  ),
),

const SizedBox(width: 16),

OutlinedButton.icon(
  onPressed: () async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ReferenceDataDialog(),
    );
  },
  icon: const Icon(Icons.settings),
  label: const Text("Manage data"),
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
  child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      isDense: true,
      value: _sort,
      icon: const Icon(Icons.keyboard_arrow_down),

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
        setState(() {
          _sort = value!;
          _page = 0;
        });

        _loadSpaces();
      },
    ),
  ),
),
      ],
    ),
  ],
),

 const SizedBox(width: 30),

    /// PAGE TITLE
    const Text(
      "Available locations",
      style: TextStyle(
        color: brandOrange,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
    ),

            const SizedBox(height: 20),

            /// SEARCH BAR
 /// SEARCH + FILTERS
Row(
  children: [
    /// SEARCH
    Expanded(
      child: TextField(
        onChanged: (value) {
          setState(() {
            _search = value;
            _page = 0;
          });

          _loadSpaces();
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
    ),

    const SizedBox(width: 18),

    /// FILTERS
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          /// MIN PRICE
          SizedBox(
            width: 95,
            child: TextField(
              controller: _minPriceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Min",
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                _page = 0;
                _loadSpaces();
              },
            ),
          ),

          const SizedBox(width: 10),

          /// MAX PRICE
          SizedBox(
            width: 95,
            child: TextField(
              controller: _maxPriceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Max",
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                _page = 0;
                _loadSpaces();
              },
            ),
          ),

          const SizedBox(width: 10),

          /// CAPACITY
          SizedBox(
            width: 120,
            child: TextField(
              controller: _minCapacityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Min people",
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                _page = 0;
                _loadSpaces();
              },
            ),
          ),
        ],
      ),
    ),
  ],
),

const SizedBox(height: 30),

            /// GRID
           Expanded(
  child: _isLoading
      ? const Center(
          child: CircularProgressIndicator(color: brandOrange),
        )
      : SingleChildScrollView(
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _spaces.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 25,
                  mainAxisSpacing: 25,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final s = _spaces[index];

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
        /// PREV
        GestureDetector(
          onTap: _page > 0
              ? () {
                  setState(() => _page--);
                  _loadSpaces();
                }
              : null,
          child: Icon(
            Icons.chevron_left,
            color: _page > 0 ? Colors.white : Colors.white24,
          ),
        ),

        const SizedBox(width: 8),

        /// PAGE NUMBERS
        for (int i = 0; i < _totalPages; i++)
          GestureDetector(
            onTap: () {
              setState(() => _page = i);
              _loadSpaces();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

        /// NEXT
        GestureDetector(
          onTap: _page < _totalPages - 1
              ? () {
                  setState(() => _page++);
                  _loadSpaces();
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