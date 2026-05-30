import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        title: 'Home',
        onTap: () => Navigator.pushReplacementNamed(context, '/home'),
      ),
      _MenuItem(
        title: 'Explore spaces',
         onTap: () {
          Navigator.pushNamed(context, '/explore-spaces');
        },
      ),
      _MenuItem(
        title: 'Extra services',
         onTap: () {
          Navigator.pushNamed(context, '/extra-services');
        },
      ),
      _MenuItem(
        title: 'My profile',
        onTap: () {
          Navigator.pushNamed(context, '/my-profile');
        },
      ),
      _MenuItem(
        title: 'About us',
        onTap: () {
         Navigator.pushNamed(context, '/about-us');
        },
      ),
      _MenuItem(
        title: 'Contact',
        onTap: () {
           Navigator.pushNamed(context, '/contact');
        },
      ),
      _MenuItem(
        title: 'Settings',
        onTap: () {
         Navigator.pushNamed(context, '/settings');
        },
      ),
    ];

    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 34),

              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 22),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return InkWell(
                      onTap: item.onTap,
                      splashColor: brandOrange.withOpacity(0.15),
                      highlightColor: brandOrange.withOpacity(0.08),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 18,
                            height: 1.3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.title, required this.onTap});
}
