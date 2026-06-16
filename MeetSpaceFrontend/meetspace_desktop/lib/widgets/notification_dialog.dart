import 'package:flutter/material.dart';

class NotificationDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isWarning;

  const NotificationDialog({
    super.key,
    required this.title,
    required this.message,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E1E1E),
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF5F5F5F),
                fontSize: 16,
                height: 1.45,
              ),
            ),
         const SizedBox(height: 28),

SizedBox(
  width: double.infinity,
  height: 52,
  child: OutlinedButton(
    onPressed: () => Navigator.pop(context),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: Color(0xFF1E1E1E),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: const Text(
      "Got it!",
      style: TextStyle(
        color: Color(0xFF1E1E1E),
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  ),
),

const SizedBox(height: 14),

SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
    onPressed: () => Navigator.pop(context),
    style: ElevatedButton.styleFrom(
      backgroundColor: isWarning
          ? const Color(0xFFB3261E)
          : const Color(0xFFB87900),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: const Text(
      "Dismiss",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
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