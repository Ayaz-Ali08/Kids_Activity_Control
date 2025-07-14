// constant.dart

import 'package:flutter/material.dart';

/// A reusable custom text field widget for consistent styling across the app.
///
/// Parameters:
/// - [controller]: A TextEditingController to manage the input.
/// - [label]: Label text displayed above the input.
/// - [obscureText]: Whether to hide the input (e.g., for passwords).
/// - [suffixIcon]: Optional widget to appear at the end of the text field.
Widget customTextField({
  required TextEditingController controller,
  required String label,
  required bool obscureText,
  Widget? suffixIcon,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25.0), // Horizontal padding around text field
    child: TextField(
      controller: controller,
      obscureText: obscureText, // Hide input if true (for passwords)
      cursorColor: const Color(0xffF9F6EE), // Custom cursor color
      style: const TextStyle(
        color: Color(0xffFCF5E5), // Input text color
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label, // Label for the text field
        labelStyle: const TextStyle(
          color: Color(0xffFCF5E5), // Label color
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          fontFamily: "Sevillana", // Custom font family (make sure it's added in pubspec.yaml)
        ),
        suffixIcon: suffixIcon, // Optional icon at the end (e.g., visibility toggle)
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffFCF5E5)), // Border color when enabled
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFFF5EE)), // Border color when focused
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
