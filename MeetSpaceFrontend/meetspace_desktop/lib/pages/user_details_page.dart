import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../models/booking.dart';
 
class UserDetailsPage extends StatefulWidget {
  final UserResponse user;
 
  const UserDetailsPage({super.key, required this.user});
 
  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}
 
class _UserDetailsPageState extends State<UserDetailsPage> {
  static const Color bgColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2E2E2E);
  static const Color brandOrange = Color(0xFFA56E09);
 
 List<BookingResponse> _bookings = [];
bool _isBookingsLoading = true;

  late UserResponse user;
 
  @override
  void initState() {
    super.initState();
    user = widget.user;
    _loadBookings();
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
            /// HEADER
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
 
                const SizedBox(width: 16),
 
                Expanded(
                  child: Text(
                    "${user.firstName ?? ""} ${user.lastName ?? ""}",
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: brandOrange,
                    ),
                  ),
                ),
 
                _actionButton("Edit", Colors.black, () async {
                  _showEditDialog(context);
                }),
 
                const SizedBox(width: 12),
 
                _actionButton(
                  user.isActive ? "Deactivate" : "Activate",
                  user.isActive ? Colors.red : Colors.green,
                  () => _confirmToggle(context),
                ),
 
                const SizedBox(width: 12),
 
                _actionButton(
                  "Delete",
                  Colors.red,
                  () => _confirmDelete(context),
                ),
              ],
            ),
 
            const SizedBox(height: 30),
 
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _infoBox("Username", user.username),
                              _infoBox("Email", user.email),
                              _infoBox("Phone", user.phoneNumber ?? "N/A"),
                              _infoBox("Role", user.roleName),
                              _infoBox(
                                "Status",
                                user.isActive ? "Active" : "Inactive",
                              ),
                            ],
                          ),
 
                          const SizedBox(height: 30),

/// 🔥 BOOKINGS
const Text(
  "Bookings",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
),
const SizedBox(height: 12),

_isBookingsLoading
    ? const Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      )
    : _bookings.isEmpty
    ? Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.event_busy,
              color: Colors.white38,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              "No bookings yet",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
        : Column(
            children: _bookings.map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.spaceName ?? "Unknown space",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${b.startTime.toLocal().toString().split(' ')[0]} | "
                            "${b.startTime.hour.toString().padLeft(2, '0')}:${b.startTime.minute.toString().padLeft(2, '0')} - "
                            "${b.endTime.hour.toString().padLeft(2, '0')}:${b.endTime.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b.statusName ?? "",
                            style: TextStyle(
                              color: b.statusName == "Approved"
                                  ? Colors.green
                                  : b.statusName == "Rejected"
                                      ? Colors.red
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      "${b.totalPrice.toStringAsFixed(0)} BAM",
                      style: const TextStyle(
                        color: brandOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
 
                          const Text(
                            "Account details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
 
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Created at: ${user.createdAt ?? "-"}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Updated at: ${user.updatedAt ?? "-"}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
 
                  const SizedBox(width: 40),
 
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Profile image",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
 
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: user.profileImageUrl == null ||
                                      user.profileImageUrl!.isEmpty
                                  ? Container(
                                      color: Colors.grey[800],
                                      child: const Center(
                                        child: Icon(Icons.person,
                                            size: 60, color: Colors.white54),
                                      ),
                                    )
                                  : Image.network(
                                      user.profileImageUrl!,
                                      fit: BoxFit.cover,
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
          ],
        ),
      ),
    );
  }

  Future<void> _loadBookings() async {
  try {
    final auth = context.read<AuthProvider>();

    final data =
        await auth.bookingService.getBookingsByUser(user.id);

    if (!mounted) return;

    setState(() {
      _bookings = data;
      _isBookingsLoading = false;
    });
  } catch (_) {
  if (!mounted) return;
  setState(() {
    _isBookingsLoading = false;
  });
}
}
 
  Widget _actionButton(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text),
    );
  }
 
  Widget _infoBox(String title, String value) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
 
  // ─── EDIT ─────────────────────────────────────────────────────────────────
  // Pattern identičan AddSpaceDialog:
  //   showDialog čeka result string
  //   Unutar dijaloga: API poziv → Navigator.pop(dialogContext, "updated")
  //   Ovdje: if result == "updated" → Navigator.pop(context, "updated")
  //   UsersPage hvata "updated" → _loadUsers() + snackbar
  void _showEditDialog(BuildContext context) async {
    final firstNameCtrl = TextEditingController(text: user.firstName);
    final lastNameCtrl = TextEditingController(text: user.lastName);
    final emailCtrl = TextEditingController(text: user.email);
 
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String localRole = user.roleName;
 
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Edit user",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
 
                  const SizedBox(height: 20),
 
                  _input(firstNameCtrl, "First name"),
                  const SizedBox(height: 12),
 
                  _input(lastNameCtrl, "Last name"),
                  const SizedBox(height: 12),
 
                  _input(emailCtrl, "Email"),
                  const SizedBox(height: 12),
 
                  DropdownButtonFormField<String>(
                    value: localRole,
                    items: const [
                      DropdownMenuItem(value: "Admin", child: Text("Admin")),
                      DropdownMenuItem(value: "Client", child: Text("Client")),
                    ],
                    onChanged: (v) => setDialogState(() => localRole = v!),
                    decoration: _inputDecoration("Role"),
                  ),
 
                  const SizedBox(height: 20),
 
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final auth = ctx.read<AuthProvider>();
                          await auth.userService.updateUserAdmin(
                            userId: user.id,
                            firstName: firstNameCtrl.text,
                            lastName: lastNameCtrl.text,
                            username: user.username,
                            email: emailCtrl.text,
                            phone: user.phoneNumber ?? "",
                            isActive: user.isActive,
                            roleId: localRole == "Admin" ? 1 : 2,
                          );
                          // API ok → zatvori modal s "updated"
                          Navigator.pop(dialogContext, "updated");
                        } catch (e) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
 
    // Identično SpaceDetailsPage edit handler:
    // if (result == "updated") { Navigator.pop(context, "updated"); }
    if (result == "updated") {
      Navigator.pop(context, "updated");
    }
  }
 
  // ─── TOGGLE ACTIVE ────────────────────────────────────────────────────────
  void _confirmToggle(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? Colors.red.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user.isActive ? Icons.block : Icons.check_circle_outline,
                  color: user.isActive ? Colors.red : Colors.green,
                  size: 28,
                ),
              ),
 
              const SizedBox(height: 20),
 
              Text(
                user.isActive ? "Deactivate user?" : "Activate user?",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
 
              const SizedBox(height: 10),
 
              Text(
                user.isActive
                    ? "User will not be able to use the platform."
                    : "User will regain access.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
 
              const SizedBox(height: 24),
 
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            user.isActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Confirm"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
 
    if (confirmed != true) return;
 
    try {
      final auth = context.read<AuthProvider>();
      final newStatus = !user.isActive;

await auth.userService.updateUserAdmin(
  userId: user.id,
  firstName: user.firstName ?? "",
  lastName: user.lastName ?? "",
  username: user.username,
  email: user.email,
  phone: user.phoneNumber ?? "",
  isActive: newStatus,
);

if (mounted) {
  Navigator.pop(
    context,
    newStatus ? "activated" : "deactivated",
  );
}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
 
  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 28),
              ),
 
              const SizedBox(height: 20),
 
              const Text(
                "Delete user?",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
 
              const SizedBox(height: 10),
 
              Text(
                "This action cannot be undone.\n'${user.username}' will be permanently removed.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
 
              const SizedBox(height: 24),
 
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
 
    if (confirmed != true) return;
 
    try {
      final auth = context.read<AuthProvider>();
      await auth.userService.deleteUser(user.id);
 
      if (mounted) Navigator.pop(context, "deleted");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
 
  Widget _input(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hint),
    );
  }
 
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}