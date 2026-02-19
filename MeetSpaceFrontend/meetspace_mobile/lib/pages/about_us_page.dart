import 'package:flutter/material.dart';
import 'menu_page.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Column(
          children: [

            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  const Text(
                    'MEETSPACE',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
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
                    child: const Icon(Icons.menu,
                        color: Colors.white, size: 26),
                  )
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 20),

                    // TITLE
                    const Text(
                      "About MeetSpace",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "MeetSpace is a modern platform designed to simplify the way people discover, book, and manage professional spaces.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // MISSION
                    const Text(
                      "Our Mission",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: brandOrange,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "We aim to connect professionals, teams, and businesses with high-quality spaces that foster productivity, collaboration, and creativity.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // WHY CHOOSE US
                    const Text(
                      "Why Choose MeetSpace?",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: brandOrange,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _FeatureCard(
                      icon: Icons.location_on_outlined,
                      title: "Premium Locations",
                      text:
                          "Discover carefully selected spaces in top business areas.",
                    ),

                    const SizedBox(height: 14),

                    _FeatureCard(
                      icon: Icons.flash_on_outlined,
                      title: "Instant Booking",
                      text:
                          "Book your ideal workspace in just a few clicks.",
                    ),

                    const SizedBox(height: 14),

                    _FeatureCard(
                      icon: Icons.groups_outlined,
                      title: "Collaboration Focused",
                      text:
                          "Spaces designed to encourage teamwork and innovation.",
                    ),

                    const SizedBox(height: 14),

                    _FeatureCard(
                      icon: Icons.verified_outlined,
                      title: "Trusted & Reliable",
                      text:
                          "Verified spaces with transparent pricing and amenities.",
                    ),

                    const SizedBox(height: 40),

                    // CTA SECTION
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            "Work. Collaborate. Create.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Find the perfect space today.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brandOrange, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
