import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/amenity.dart';
import 'menu_page.dart';

class ExtraServicesPage extends StatefulWidget {
  const ExtraServicesPage({super.key});

  @override
  State<ExtraServicesPage> createState() => _ExtraServicesPageState();
}

class _ExtraServicesPageState extends State<ExtraServicesPage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  Future<List<AmenityResponse>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAmenities();
  }

  Future<List<AmenityResponse>> _loadAmenities() async {
    final auth = context.read<AuthProvider>();

    // Ako želiš filtrirati samo "extra services" kategoriju, ovdje postavi ID:
    // return auth.getAmenities(amenityCategoryId: 1);

    return auth.getAmenities();
  }

  IconData _iconForAmenityName(String name) {
    final n = name.toLowerCase().trim();

    if (n.contains('phone') || n.contains('telefon')) {
      return Icons.phone_outlined;
    }
    if (n.contains('printer') || n.contains('print')) {
      return Icons.print_outlined;
    }
    if (n.contains('coffee') || n.contains('kafa') || n.contains('cafe')) {
      return Icons.coffee_outlined;
    }
    if (n.contains('flat screen') || n.contains('monitor') || n.contains('tv')) {
      return Icons.tv_outlined;
    }
    if (n.contains('air') ||
        n.contains('ac') ||
        n.contains('conditioning') ||
        n.contains('klima')) {
      return Icons.ac_unit_outlined;
    }
    if (n.contains('furniture') ||
        n.contains('chair') ||
        n.contains('namještaj')) {
      return Icons.chair_outlined;
    }
    if (n.contains('catering') || n.contains('food') || n.contains('hrana')) {
      return Icons.restaurant_outlined;
    }
    if (n.contains('flip') || n.contains('chart') || n.contains('whiteboard')) {
      return Icons.co_present_outlined;
    }

    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: 'MEETSPACE',
                onMenu: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuPage()),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Browse our\nadditional\namenities and\nextra services.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 46,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  color: brandOrange,
                ),
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<AmenityResponse>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingCard();
                  }

                  if (snapshot.hasError) {
                    return _ErrorCard(
                      message: snapshot.error.toString(),
                      onRetry: () {
                        setState(() {
                          _future = _loadAmenities();
                        });
                      },
                    );
                  }

                  final amenities = snapshot.data ?? [];
                  if (amenities.isEmpty) {
                    return const _EmptyCard();
                  }

                  final items = amenities
                      .map(
                        (a) => _ExtraServiceItem(
                          title: a.name,
                          icon: _iconForAmenityName(a.name),
                        ),
                      )
                      .toList();

                  return _ServicesCard(items: items);
                },
              ),
              const Spacer(),
              const SizedBox(height: 18),
              const _Footer(),
            ],
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Loading amenities...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Failed to load amenities',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Text(
        'No amenities available.',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _ServicesCard extends StatelessWidget {
  const _ServicesCard({required this.items});

  final List<_ExtraServiceItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isAlt = i.isEven;
            return _ServiceRow(
              title: item.title,
              icon: item.icon,
              background: isAlt
                  ? const Color(0xFFF7F1E7)
                  : const Color(0xFFFFFFFF),
              showDivider: i != items.length - 1,
            );
          }),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.title,
    required this.icon,
    required this.background,
    required this.showDivider,
  });

  final String title;
  final IconData icon;
  final Color background;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.black87, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(height: 1, thickness: 1, color: Color(0xFFE6E6E6)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'MEETSPACE',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26,
            letterSpacing: 6,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'meetspace.app@gmail.com',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _ExtraServiceItem {
  final String title;
  final IconData icon;

  const _ExtraServiceItem({required this.title, required this.icon});
}
