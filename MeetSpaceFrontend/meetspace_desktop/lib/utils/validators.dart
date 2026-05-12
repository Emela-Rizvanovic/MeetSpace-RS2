class Validators {
  static String? required(
    String? value,
    String fieldName,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return "$fieldName is required.";
    }

    return null;
  }

  static String? email(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return null;
    }

    final regex = RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    );

    if (!regex.hasMatch(value)) {
      return "Enter a valid email address (example: name@email.com).";
    }

    return null;
  }

  static String? phone(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return null;
    }

    final regex = RegExp(
      r'^\+?[0-9 ]{6,20}$',
    );

    if (!regex.hasMatch(value)) {
      return "Enter a valid phone number (example: +387 61 123 456).";
    }

    return null;
  }

  static String? minLength(
    String? value,
    String fieldName,
    int length,
  ) {
    if (value == null ||
        value.trim().length < length) {
      return "$fieldName must contain at least $length characters.";
    }

    return null;
  }
}