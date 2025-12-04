import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // boje iz tvog dizajna
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1) Pozadinska slika
         Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,            // slika pokriva cijeli ekran
            alignment: Alignment.centerRight, // desna strana slike
            errorBuilder: (context, error, stackTrace) {
              return Container(color: bgGrey);
            },
          ),
        ),


          // 2) Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          // 3) Sadržaj
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------------------------------------------------------
                  // **HEADER** (ISPRAVLJENO: MEETSPACE lijevo, menu desno)
                  // ---------------------------------------------------------
                  Row(
                    children: [
                      // LOGO TEKST (lijevo)
                      Text(
                        'MEETSPACE',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3,
                          fontSize: 20,
                        ),
                      ),

                      const Spacer(),

                      // Menu dugme (desno)
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Menu tapped')),
                          );
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          /*decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),*/
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/icons/menu.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.menu, color: Colors.white);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  // ---------------------------------------------------------

                  const SizedBox(height: 28),

                  // WHITE SEARCH BOX / EXPLORE SPACES
                  Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 720),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Explore spaces',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: bgGrey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                const Icon(Icons.search, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // FOOTER / SLOGAN
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
                            fontWeight: FontWeight.w900,     // deblje
                            letterSpacing: 1.2,              // malo šire
                            fontSize: media.width * 0.10,    // veće
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
    );
  }
}
