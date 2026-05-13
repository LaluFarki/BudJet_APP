import 'package:flutter/material.dart';

class ValidationHelper {
  static Widget buildLabelWithWarning({
    required String label,
    required String warning,
    required bool showWarning,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showWarning)
          Text(
            warning,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  static bool isLengthExceeded(String text, int max) {
    return text.length > max;
  }

  static bool isAmountExceeded(double amount, double max) {
    return amount > max;
  }

  static bool isNominalExceeded(String? text, double max) {
    if (text == null) return false;
    return parseRupiah(text) > max;
  }

  static double parseRupiah(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0;
  }
}
