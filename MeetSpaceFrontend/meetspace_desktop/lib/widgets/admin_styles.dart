import 'package:flutter/material.dart';

class AdminStyles {
  static const bgColor = Color(0xFF3B3B3B);

  static const cardColor = Color(0xFF2E2E2E);

  static const brandOrange =
      Color.fromARGB(255, 165, 110, 9);

 static InputDecoration inputDecoration(
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Colors.white54,
      ),

      errorStyle: const TextStyle(
        color: Colors.redAccent,
      ),

      filled: true,
      fillColor: bgColor,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  static InputDecoration searchDecoration(
  String hint,
) {
  return InputDecoration(
    hintText: hint,

    prefixIcon: const Icon(
      Icons.search,
      color: Colors.black54,
    ),

    filled: true,
    fillColor: Colors.white,

    contentPadding:
        const EdgeInsets.symmetric(
      vertical: 14,
    ),

    border: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

  static ButtonStyle primaryButton =
      ElevatedButton.styleFrom(
    backgroundColor: brandOrange,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 16,
    ),
    shape: RoundedRectangleBorder(
      borderRadius:
          BorderRadius.circular(14),
    ),
  );

  static ButtonStyle deleteButton =
      ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
  );

  static ButtonStyle cancelButton =
      ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
  );
}