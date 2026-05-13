import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

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

class RupiahInputFormatter extends TextInputFormatter {
  final double? max;
  final VoidCallback? onMaxExceeded;

  RupiahInputFormatter({this.max, this.onMaxExceeded});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (newValue.text.compareTo(oldValue.text) != 0) {
      int selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;
      
      final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (digits.isEmpty) {
        return const TextEditingValue(text: '');
      }
      
      int number = int.tryParse(digits) ?? 0;

      if (max != null && number > max!) {
        number = max!.toInt();
        if (onMaxExceeded != null) onMaxExceeded!();
      }
      
      final newString = intl.NumberFormat('#,###', 'id_ID').format(number).replaceAll(',', '.');
      
      int newSelectionIndex = newString.length - selectionIndexFromTheRight;
      if (newSelectionIndex < 0) newSelectionIndex = 0;
      if (newSelectionIndex > newString.length) newSelectionIndex = newString.length;
      
      return TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(offset: newSelectionIndex),
      );
    }
    return newValue;
  }
}
