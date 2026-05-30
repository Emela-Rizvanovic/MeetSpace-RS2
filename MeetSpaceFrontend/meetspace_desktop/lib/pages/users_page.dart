import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'user_details_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../utils/pdf_helper.dart';
 
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
 
  @override
  State<UsersPage> createState() => _UsersPageState();
}
 
class _UsersPageState extends State<UsersPage> {
  static const bgColor = Color(0xFF3B3B3B);
  static const brandOrange = Color.fromARGB(255, 165, 110, 9);
 
  List<UserResponse> _users = [];
 
  bool _isLoading = true;
 
  String _search = "";
  int _page = 0;
final int _pageSize = 6;
int _totalPages = 1;

String _sort = "Name ↑";
 
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
 
Future<void> _loadUsers() async {
  try {
    final auth = context.read<AuthProvider>();

    final sort = _getSortParams();

    final result = await auth.userService.getPaged(
      page: _page,
      pageSize: _pageSize,
      search: _search.isNotEmpty ? _search : null,
      sortBy: sort["sortBy"],
      desc: sort["desc"],
    );

    setState(() {
      _users = result.items;
      _totalPages = result.totalPages;
      _isLoading = false;
    });
 } catch (_) {
  if (!mounted) return;
  setState(() {
    _isLoading = false;
  });
}
}


  Map<String, dynamic> _getSortParams() {
  String? sortBy;
  bool desc = false;

  switch (_sort) {
    case "Name ↑":
      sortBy = "FirstName";
      desc = false;
      break;

    case "Name ↓":
      sortBy = "FirstName";
      desc = true;
      break;
  }

  return {
    "sortBy": sortBy,
    "desc": desc,
  };
}

Future<void> _generatePdf() async {
  try {
    final pdf = await PdfHelper.generateUsersPdf(_users);

    final bytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();

    final file = File("${dir.path}/users_report.pdf");

    await file.writeAsBytes(bytes);

    await OpenFile.open(file.path);

 } catch (_) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Failed to generate PDF")),
  );
}
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
Row(
  children: [
    InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
      ),
    ),

    const SizedBox(width: 16),

    const Text(
      "MEETSPACE",
      style: TextStyle(
        color: Colors.white70,
        letterSpacing: 4,
        fontSize: 18,
      ),
    ),
  ],
),

const SizedBox(height: 10),
      Row(
  children: [
    const Text(
      "Users",
      style: TextStyle(
        color: brandOrange,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
    ),

    const Spacer(),

    Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<String>(
        value: _sort,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: "Name ↑", child: Text("Name ↑")),
          DropdownMenuItem(value: "Name ↓", child: Text("Name ↓")),
        ],
        onChanged: (value) {
          setState(() {
            _sort = value!;
            _page = 0;
          });
          _loadUsers();
        },
      ),
    ),
  ],
),

const SizedBox(height: 10),
 
            TextField(
              onChanged: (value) {
  setState(() {
    _search = value;
    _page = 0;
  });
  _loadUsers();
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
 
            const SizedBox(height: 10),
 
Expanded(
  child: _isLoading
      ? const Center(
          child: CircularProgressIndicator(color: brandOrange),
        )
      : SingleChildScrollView(
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final user = _users[index];

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

              const SizedBox(height: 12),

              _buildPagination(),

              const SizedBox(height: 20),

Align(
  alignment: Alignment.centerRight,
  child: ElevatedButton.icon(
    onPressed: _generatePdf,
    icon: const Icon(Icons.picture_as_pdf),
    label: const Text("Generate PDF"),
    style: ElevatedButton.styleFrom(
      backgroundColor: brandOrange,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
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

    Widget _buildPagination() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _page > 0
              ? () {
                  setState(() => _page--);
                  _loadUsers();
                }
              : null,
          child: Icon(
            Icons.chevron_left,
            color: _page > 0 ? Colors.white : Colors.white24,
          ),
        ),

        const SizedBox(width: 8),

        for (int i = 0; i < _totalPages; i++)
          GestureDetector(
            onTap: () {
              setState(() => _page = i);
              _loadUsers();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _page == i
                    ? const Color(0xFFA56E09)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${i + 1}",
                style: TextStyle(
                  fontSize: 13,
                  color: _page == i ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        const SizedBox(width: 8),

        GestureDetector(
          onTap: _page < _totalPages - 1
              ? () {
                  setState(() => _page++);
                  _loadUsers();
                }
              : null,
          child: Icon(
            Icons.chevron_right,
            color: _page < _totalPages - 1
                ? Colors.white
                : Colors.white24,
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image == null || image.isEmpty
                ? Container(
                    height: 130, 
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

          Text(
            "${user.firstName ?? ""} ${user.lastName ?? ""}",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            user.username,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),

          const Spacer(),

          Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              height: 36, 
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDetailsPage(user: user),
                    ),
                  );

                  onResult(result); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.black, 
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