import 'package:flutter/material.dart';
import 'admin_styles.dart';

class ConfirmDeleteDialog
    extends StatelessWidget {

  final String title;
  final String message;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor:
          AdminStyles.cardColor,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),

      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
        ),
      ),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              false,
            );
          },

          style:
              AdminStyles.cancelButton,

          child: const Text(
            "Cancel",
          ),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              true,
            );
          },

          style:
              AdminStyles.deleteButton,

          child: const Text(
            "Delete",
          ),
        ),
      ],
    );
  }
}