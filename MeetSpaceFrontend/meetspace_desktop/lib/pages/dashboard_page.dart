import 'package:flutter/material.dart';
import 'bookings_page.dart';
import 'locations_page.dart';
import 'amenities_page.dart';
import 'revenue_page.dart';
import 'users_page.dart';
import 'reviews_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B3B3B),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LOGO
           Row(
  children: [
    const Text(
      "MEETSPACE",
      style: TextStyle(
        color: Colors.white70,
        letterSpacing: 4,
        fontSize: 18,
      ),
    ),
    const Spacer(),
    TextButton.icon(
      onPressed: () async {
        await context.read<AuthProvider>().logout();

        if (!context.mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
          (route) => false,
        );
      },
      icon: const Icon(
        Icons.logout,
        color: Colors.redAccent,
      ),
      label: const Text(
        "Logout",
        style: TextStyle(color: Colors.white),
      ),
    ),
  ],
),

            const SizedBox(height: 40),

            /// TITLE
            const Text(
              "Welcome to Admin Dashboard!",
              style: TextStyle(
                color: Color.fromARGB(255, 165, 110, 9),
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            /// GRID
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 25,
                mainAxisSpacing: 25,
                childAspectRatio: 1.6,
               children: [
  GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookingsPage()),
      );
    },
    child: const DashboardCard(
      title: "Upcoming bookings and reminders",
      description:
          "Stay on top of scheduled reservations. View all upcoming bookings and prepare in advance.",
      iconPath: "assets/icons/notepad.png",
    ),
  ),

GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationsPage()),
    );
  },
  child: const DashboardCard(
    title: "Available locations",
    description:
        "Browse and manage all co-working spaces and meeting venues currently open for booking.",
    iconPath: "assets/icons/hut.png",
  ),
),

  GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AmenitiesPage(),
      ),
    );
  },
  child: const DashboardCard(
    title: "Modern amenities",
    description:
        "Take a quick overview of additional services and equipment available to enhance user experience.",
    iconPath: "assets/icons/wand.png",
  ),
),

  GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RevenuePage(),
      ),
    );
  },
  child: const DashboardCard(
    title: "Revenue history",
    description:
        "Track overall earnings from all bookings and additional services in one place.",
    iconPath: "assets/icons/tag.png",
  ),
),

  GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UsersPage()),
    );
  },
  child: const DashboardCard(
    title: "Users",
    description:
        "Keep track of user activity and platform engagement.",
    iconPath: "assets/icons/globe.png",
  ),
),

 GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewsPage()),
    );
  },
  child: const DashboardCard(
    title: "User reviews",
    description:
        "Access and monitor all reviews to improve service quality.",
    iconPath: "assets/icons/like.png",
  ),
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

class DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final String iconPath;

  const DashboardCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON
          Image.asset(
            iconPath,
            width: 30,
            height: 30,
            color: const Color.fromARGB(255, 165, 110, 9),
          ),

          const SizedBox(height: 18),

          /// TITLE
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          /// DESCRIPTION
          Text(
            description,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}