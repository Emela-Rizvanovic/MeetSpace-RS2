import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/space.dart';
import 'menu_page.dart';
import 'space_details_page.dart';

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

  bool _showFavorites = false;

  Future<List<SpaceResponse>>? _future;
  List<SpaceResponse> _spaces = [];

  @override
  void initState() {
    super.initState();
    _future = _loadSpaces();
  }

  Future<List<SpaceResponse>> _loadSpaces() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.getSpaces();
    _spaces = data;
    return data;
  }

  Future<List<SpaceResponse>> _loadFavorites() async {
    final auth = context.read<AuthProvider>();
    return auth.getFavoriteSpaces();
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets
                          .symmetric(
                          horizontal: 18,
                          vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                                14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.12),
                            blurRadius: 12,
                            offset:
                                const Offset(0, 6),
                          ),
                        ],
                      ),
                      child:
                          Autocomplete<SpaceResponse>(
                        displayStringForOption:
                            (space) => space.name,

                        optionsBuilder:
                            (TextEditingValue
                                textEditingValue) {
                          if (_spaces.isEmpty) {
                            return const Iterable<
                                SpaceResponse>.empty();
                          }

                          if (textEditingValue
                              .text.isEmpty) {
                            return _spaces;
                          }

                          return _spaces.where(
                            (space) => space.name
                                .toLowerCase()
                                .startsWith(
                                  textEditingValue
                                      .text
                                      .toLowerCase(),
                                ),
                          );
                        },

                        onSelected:
                            (SpaceResponse
                                selection) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SpaceDetailsPage(
                                      space:
                                          selection),
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
                            style:
                                const TextStyle(
                              fontFamily:
                                  'Poppins',
                              fontSize: 15,
                            ),
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'Find a space',
                              border:
                                  InputBorder
                                      .none,
                            ),
                          );
                        },

                        optionsViewBuilder:
                            (context,
                                onSelected,
                                options) {
                          final optionList =
                              options.toList();

                          return Align(
                            alignment:
                                Alignment
                                    .topLeft,
                            child: Material(
                              color: Colors
                                  .transparent,
                              child: Container(
                                margin:
                                    const EdgeInsets
                                            .only(
                                        top: 8),
                                width: MediaQuery.of(
                                            context)
                                        .size
                                        .width -
                                    44,
                                constraints:
                                    const BoxConstraints(
                                        maxHeight:
                                            250),
                                decoration:
                                    BoxDecoration(
                                  color: bgGrey,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withOpacity(
                                              0.3),
                                      blurRadius:
                                          12,
                                    ),
                                  ],
                                ),
                                child:
                                    ListView.builder(
                                  padding:
                                      EdgeInsets
                                          .zero,
                                  shrinkWrap:
                                      true,
                                  itemCount:
                                      optionList
                                          .length,
                                  itemBuilder:
                                      (context,
                                          index) {
                                    final space =
                                        optionList[
                                            index];

                                    return InkWell(
                                      onTap: () =>
                                          onSelected(
                                              space),
                                      child:
                                          Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal:
                                              18,
                                          vertical:
                                              14,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          border:
                                              Border(
                                            bottom:
                                                BorderSide(
                                              color: index ==
                                                      optionList.length -
                                                          1
                                                  ? Colors
                                                      .transparent
                                                  : Colors
                                                      .white12,
                                            ),
                                          ),
                                        ),
                                        child:
                                            Text(
                                          space.name,
                                          style:
                                              const TextStyle(
                                            fontFamily:
                                                'Poppins',
                                            color:
                                                Colors.white,
                                            fontSize:
                                                14,
                                            fontWeight:
                                                FontWeight.w500,
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

                    const SizedBox(height: 12),

                    /// FILTER BUTTONS
                    Row(
                      children: [
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showFavorites =
                                    false;
                                _future =
                                    _loadSpaces();
                              });
                            },
                            style: ElevatedButton
                                .styleFrom(
                              backgroundColor:
                                  !_showFavorites
                                      ? brandOrange
                                      : Colors
                                          .white,
                              foregroundColor:
                                  !_showFavorites
                                      ? Colors
                                          .white
                                      : Colors
                                          .black87,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            12),
                              ),
                            ),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontFamily:
                                    'Poppins',
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showFavorites =
                                    true;
                                _future =
                                    _loadFavorites();
                              });
                            },
                            style: ElevatedButton
                                .styleFrom(
                              backgroundColor:
                                  _showFavorites
                                      ? brandOrange
                                      : Colors
                                          .white,
                              foregroundColor:
                                  _showFavorites
                                      ? Colors
                                          .white
                                      : Colors
                                          .black87,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            12),
                              ),
                            ),
                            child: const Text(
                              'See favorites',
                              style: TextStyle(
                                fontFamily:
                                    'Poppins',
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SpaceDetailsPage(
                                          space:
                                              s),
                                ),
                              );
                            },
                            child:
                                _SpaceCard(
                                    space: s),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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
