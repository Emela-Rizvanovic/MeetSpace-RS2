import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/space.dart';
import 'menu_page.dart';
import 'space_details_page.dart';
import '../providers/notification_provider.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  List<SpaceResponse> _spaces = [];

  @override
  void initState() {
    super.initState();
    _loadSpaces();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
    final auth = context.read<AuthProvider>();

    final token = auth.token;

    if (token == null) return;

    await context.read<NotificationProvider>().connect(
          token: token,
          navigatorKey: navigatorKey,
        );
  });
  }

  Future<void> _loadSpaces() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.getSpaces();
    setState(() {
      _spaces = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Scaffold(
  body: GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: bgGrey);
              },
            ),
          ),

          /// DARK OVERLAY
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          /// CONTENT
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// HEADER
                  Row(
                    children: [
                      const Text(
                        'MEETSPACE',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MenuPage()),
                          );
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/icons/menu.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.menu,
                                  color: Colors.white);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  /// AUTOCOMPLETE SEARCH
                  Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 720),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
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
  displayStringForOption: (space) => space.name,

  optionsBuilder: (TextEditingValue textEditingValue) {
    if (_spaces.isEmpty) {
      return const Iterable<SpaceResponse>.empty();
    }

    if (textEditingValue.text.isEmpty) {
      return _spaces;
    }

    return _spaces.where((space) =>
        space.name.toLowerCase().startsWith(
              textEditingValue.text.toLowerCase(),
            ));
  },

  onSelected: (SpaceResponse selection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpaceDetailsPage(space: selection),
      ),
    );
  },

  fieldViewBuilder:
      (context, controller, focusNode, onFieldSubmitted) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
      ),
      decoration: const InputDecoration(
        hintText: 'Explore spaces',
        border: InputBorder.none,
      ),
    );
  },

  optionsViewBuilder:
      (context, onSelected, options) {

    final optionList = options.toList();

    return GestureDetector(
      onTap: () {}, // da klik unutar ne zatvori
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            width: MediaQuery.of(context).size.width - 40,
            constraints: BoxConstraints(
              maxHeight: optionList.length * 55,
            ),
            decoration: BoxDecoration(
              color: bgGrey,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: index == optionList.length - 1
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
      ),
    );
  },
)

                    ),
                  ),

                  const Spacer(),

                  /// SLOGAN
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Work.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: media.width * 0.10,
                          ),
                        ),
                        Text(
                          'Collaborate.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: media.width * 0.10,
                          ),
                        ),
                        Text(
                          'Find the perfect',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: media.width * 0.10,
                          ),
                        ),
                        Text(
                          'space.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: brandOrange,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: media.width * 0.10,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
  ),
    );
  }
}
