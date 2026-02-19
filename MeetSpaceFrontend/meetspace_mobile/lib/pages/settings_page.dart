import 'package:flutter/material.dart';
import 'menu_page.dart';
import 'my_profile_page.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  bool _notificationsEnabled = true;
  String _selectedLanguage = "English";

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
                        MaterialPageRoute(builder: (_) => const MenuPage()),
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

                    const Text(
                      "Settings",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // -------------------------
                    // PREFERENCES
                    // -------------------------
                    const Text(
                      "Preferences",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: brandOrange,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [

                          SwitchListTile(
                            value: _notificationsEnabled,
                            activeColor: brandOrange,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                            title: const Text(
                              "Enable notifications",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              "Receive booking updates and reminders",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          const Divider(color: Colors.white12, height: 1),

                          ListTile(
                            title: const Text(
                              "Language",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                            trailing: DropdownButton<String>(
                              dropdownColor: const Color(0xFF2E2E2E),
                              value: _selectedLanguage,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "English",
                                  child: Text("English"),
                                ),
                                DropdownMenuItem(
                                  value: "Bosnian",
                                  child: Text("Bosnian"),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedLanguage = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // -------------------------
                    // ACCOUNT
                    // -------------------------
                    const Text(
                      "Account",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: brandOrange,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [

                          ListTile(
                            leading: const Icon(Icons.person_outline,
                                color: brandOrange),
                            title: const Text(
                              "My Profile",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MyProfilePage()),
                              );
                            },
                          ),

                          const Divider(color: Colors.white12, height: 1),

                          ListTile(
                            leading: const Icon(Icons.logout,
                                color: Colors.redAccent),
                            title: const Text(
                              "Log out",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                            onTap: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                                (route) => false,
                              );
                            },
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
