import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool loading = false;

  late AnimationController _fadeController;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && _emailController.text.isEmpty) {
      _emailController.text = arg;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final res = await Provider.of<AuthProvider>(context, listen: false)
          .resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: const Color.fromARGB(255, 165, 110, 9),
        ),
      );

      if (res.success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 59, 59, 59),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const Text(
                  "MEETSPACE",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w300,
                    fontSize: 34,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Enter the code from your email and set a new password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: _input("Email"),
                         validator: (v) {
  if (v == null || v.trim().isEmpty) {
    return "Email is required.";
  }

  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  if (!emailRegex.hasMatch(v.trim())) {
    return "Email must be in a valid format, e.g. example@mail.com.";
  }

  return null;
},
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _input("Reset code"),
                        validator: (v) {
  if (v == null || v.trim().isEmpty) {
    return "Reset code is required.";
  }

  if (v.trim().length < 4 || v.trim().length > 10) {
    return "Reset code must contain 4-10 characters.";
  }

  return null;
},
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _input("New password"),
                         validator: (v) {
  if (v == null || v.isEmpty) {
    return "New password is required.";
  }

  final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{6,}$');

  if (!regex.hasMatch(v)) {
    return "New password must contain at least 6 characters, one uppercase letter and one number.";
  }

  return null;
},
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : _reset,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor:
                                  const Color.fromARGB(255, 165, 110, 9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "Reset password",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
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
        ),
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white70, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 165, 110, 9),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
