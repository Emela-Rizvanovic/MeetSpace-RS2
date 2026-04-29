import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'user_details_page.dart';
 
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
 
  @override
  State<UsersPage> createState() => _UsersPageState();
}
 
class _UsersPageState extends State<UsersPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);
 
  List<UserResponse> _users = [];
  List<UserResponse> _filtered = [];
 
  bool _isLoading = true;
 
  String _search = "";
 
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
 
 Future<void> _loadUsers() async {
  
  try {
    final auth = context.read<AuthProvider>();
    
    final data = await auth.userService.getUsers();

    setState(() {
      _users = data;
      _applyFilters();
      _isLoading = false;
    });
    
  } catch (e) {
    debugPrint(e.toString());
  }
}
 
  void _applyFilters() {
    List<UserResponse> temp = [..._users];
 
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
 
      temp = temp.where((u) {
        final fullName =
            "${u.firstName ?? ""} ${u.lastName ?? ""}".toLowerCase();
 
        return fullName.contains(query) ||
            u.username.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query);
      }).toList();
    }
 
    _filtered = temp;
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
            /// TITLE
            const Text(
              "Users",
              style: TextStyle(
                color: brandOrange,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
 
            const SizedBox(height: 20),
 
            /// SEARCH
            TextField(
              onChanged: (value) {
                setState(() {
                  _search = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: "Quick search",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
 
            const SizedBox(height: 30),
 
            /// GRID
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandOrange),
                    )
                  : GridView.builder(
                    
                      itemCount: _filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final user = _filtered[index];
 
                     return _UserCard(
  user: user,
  onResult: (result) async {
    if (result == "updated") {
      await _loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User updated successfully"),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (result == "deleted") {
      await _loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User deleted successfully"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (result == "activated") {
  await _loadUsers();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("User activated"),
      backgroundColor: Colors.green,
    ),
  );
}

if (result == "deactivated") {
  await _loadUsers();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("User deactivated"),
      backgroundColor: Colors.red,
    ),
  );
}
  },
);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _UserCard extends StatelessWidget {
  final UserResponse user;
  final Function(String?) onResult;

  const _UserCard({
    required this.user,
    required this.onResult,
  });

  static const brandOrange = Color.fromARGB(255, 165, 110, 9);

  @override
  Widget build(BuildContext context) {
    final image = user.profileImageUrl;

    return Container(
      padding: const EdgeInsets.all(12), // 🔥 manji padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // 🔥 malo manji radius
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image == null || image.isEmpty
                ? Container(
                    height: 130, // 🔥 manja slika
                    color: const Color(0xFFEDEDED),
                    child: const Center(
                      child: Icon(Icons.person),
                    ),
                  )
                : Image.network(
                    image,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),

          const SizedBox(height: 10),

          /// NAME
          Text(
            "${user.firstName ?? ""} ${user.lastName ?? ""}",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 2),

          /// USERNAME
          Text(
            user.username,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),

          const Spacer(),

          /// BUTTON (FIGMA STYLE)
          Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              height: 36, // 🔥 manji button
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDetailsPage(user: user),
                    ),
                  );

                  onResult(result); // 🔥 vrati parentu
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.black, // 🔥 kao na slici
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "See profile details",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}