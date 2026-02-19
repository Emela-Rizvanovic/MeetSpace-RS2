import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color bgGrey = Color.fromARGB(255, 59, 59, 59);
  static const Color brandOrange = Color.fromARGB(255, 165, 110, 9);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  File? _previewImage;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _changePassword = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user =
        Provider.of<AuthProvider>(context, listen: false).user!;

    _firstNameController =
        TextEditingController(text: user.firstName);
    _lastNameController =
        TextEditingController(text: user.lastName);
    _usernameController =
        TextEditingController(text: user.username);
    _phoneController =
        TextEditingController(text: user.phoneNumber ?? '');
    _emailController =
        TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _pickedImage = picked;
        _previewImage = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();

      await auth.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        newPassword: _changePassword
            ? _newPasswordController.text.trim()
            : null,
        profileImage: _pickedImage,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully."),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update failed: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Text(
              "Edit Profile",
              style: TextStyle(
                fontFamily: "Poppins",
                color: brandOrange,
                fontWeight: FontWeight.w700,
                fontSize: 32,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      // PROFILE IMAGE
                      Center(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(14),
                              child: Container(
                                width: 140,
                                height: 140,
                                color: const Color(0xFFE9E9E9),
                                child: _previewImage != null
                                    ? Image.file(
                                        _previewImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 80,
                                        color:
                                            Color(0xFFB0B0B0),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _pickImage,
                              child: const Text(
                                "Change photo",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: brandOrange,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _InputField(
                        label: "First name",
                        controller:
                            _firstNameController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? "First name is required."
                                : null,
                      ),
                      const SizedBox(height: 18),

                      _InputField(
                        label: "Last name",
                        controller:
                            _lastNameController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? "Last name is required."
                                : null,
                      ),
                      const SizedBox(height: 18),

                      _InputField(
                        label: "Username",
                        controller:
                            _usernameController,
                        validator: (v) =>
                            v == null || v.trim().length < 3
                                ? "Username must contain at least 3 characters."
                                : null,
                      ),
                      const SizedBox(height: 18),

                      _InputField(
                        label: "Phone number",
                        controller:
                            _phoneController,
                        validator: (v) {
                          if (v == null ||
                              v.trim().isEmpty) {
                            return "Phone number is required.";
                          }
                          if (!RegExp(
                                  r'^[0-9]{6,15}$')
                              .hasMatch(v.trim())) {
                            return "Enter a valid phone number (6–15 digits).";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _InputField(
                        label: "Email",
                        controller:
                            _emailController,
                        validator: (v) {
                          if (v == null ||
                              v.trim().isEmpty) {
                            return "Email is required.";
                          }
                          if (!RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return "Enter a valid email address.";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      CheckboxListTile(
                        value: _changePassword,
                        onChanged: (val) {
                          setState(() =>
                              _changePassword =
                                  val ?? false);
                        },
                        activeColor: brandOrange,
                        title: const Text(
                          "Change password",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                        controlAffinity:
                            ListTileControlAffinity
                                .leading,
                      ),

                      if (_changePassword) ...[
                        const SizedBox(height: 18),
                        _InputField(
                          label: "New password",
                          controller:
                              _newPasswordController,
                          obscure: true,
                          validator: (v) {
                            if (_changePassword &&
                                (v == null ||
                                    v.length < 6)) {
                              return "Password must contain at least 6 characters.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _InputField(
                          label: "Confirm password",
                          controller:
                              _confirmPasswordController,
                          obscure: true,
                          validator: (v) {
                            if (_changePassword &&
                                v !=
                                    _newPasswordController
                                        .text) {
                              return "Passwords do not match.";
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                brandOrange,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                            ),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Save changes",
                                  style: TextStyle(
                                    fontFamily:
                                        "Poppins",
                                    fontSize: 16,
                                    color:
                                        Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscure;

  const _InputField({
    required this.label,
    required this.controller,
    this.validator,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
