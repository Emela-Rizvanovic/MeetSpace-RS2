import 'package:flutter/material.dart';
import 'menu_page.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Column(
          children: [
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

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 20),

                    const Text(
                      "Contact Us",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Have questions about bookings, spaces, or your account? "
                      "Our team is here to help you.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Email Support",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: brandOrange,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const _ContactCard(
                      icon: Icons.email_outlined,
                      title: "General & Technical Support",
                      text: "meetspace.app@gmail.com",
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Working Hours",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: brandOrange,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const _ContactCard(
                      icon: Icons.access_time,
                      title: "Customer Support",
                      text: "Monday – Friday\n08:00 – 18:00",
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Need Help Quickly?",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: brandOrange,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "For password recovery and account-related issues, "
                        "please use the in-app 'Forgot Password' option.\n\n"
                        "We typically respond to emails within 24 hours.",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.white70,
                        ),
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

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ContactCard({
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
