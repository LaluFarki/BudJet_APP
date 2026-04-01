import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  /// Mengubah angka (double) menjadi format Rupiah dengan pemisah ribuan (titik)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Menentukan Icon berdasarkan Kategori (Keyword Based)
  static IconData getCategoryIcon(String category, [dynamic titleOrNothing]) {
    final k = category.toLowerCase();
    if (k.contains('makan') || k.contains('minum')) return Icons.fastfood;
    if (k.contains('transport')) return Icons.directions_bus;
    if (k.contains('hibur')) return Icons.movie;
    if (k.contains('tabung')) return Icons.savings;
    if (k.contains('belanja')) return Icons.shopping_bag;
    if (k.contains('pendidik')) return Icons.school;
    if (k.contains('kesehat')) return Icons.local_hospital;
    return Icons.category; // Default for others
  }

  /// Menentukan Warna Icon berdasarkan Kategori (Keyword Based)
  static Color getCategoryColor(String category, [dynamic indexOrTitle]) {
    final k = category.toLowerCase();
    if (k.contains('makan') || k.contains('minum')) return Colors.orange;
    if (k.contains('transport')) return Colors.blue;
    if (k.contains('hibur')) return Colors.purple;
    if (k.contains('tabung')) return Colors.green;
    if (k.contains('belanja')) return Colors.pink;
    if (k.contains('pendidik')) return Colors.teal;
    if (k.contains('kesehat')) return Colors.red;

    // Fallback for custom categories using dynamic colors
    // Use hashCode for stability across different screens if no index is provided
    int index = (indexOrTitle is int) ? indexOrTitle : category.hashCode.abs();
    const cols = [
      Color(0xFFFF7B33), Color(0xFF1D9CCB), Color(0xFFBCE037), Color(0xFFAB6AEA), Color(0xFFFC5A8D),
    ];
    return cols[index % cols.length];
  }

  /// Menentukan Warna Background berdasarkan Kategori (Keyword Based)
  static Color getCategoryColorBg(String category, [dynamic indexOrTitle]) {
    final k = category.toLowerCase();
    if (k.contains('makan') || k.contains('minum')) return Colors.orange.shade50;
    if (k.contains('transport')) return Colors.blue.shade50;
    if (k.contains('hibur')) return Colors.purple.shade50;
    if (k.contains('tabung')) return Colors.green.shade50;
    if (k.contains('belanja')) return Colors.pink.shade50;
    if (k.contains('pendidik')) return Colors.teal.shade50;
    if (k.contains('kesehat')) return Colors.red.shade50;

    // Fallback for custom categories using dynamic colors
    int index = (indexOrTitle is int) ? indexOrTitle : category.hashCode.abs();
    const bgs = [
      Color(0xFFFFEAE0), Color(0xFFDCF3FB), Color(0xFFE9F8C6), Color(0xFFF0E5FA), Color(0xFFFFE4EE),
    ];
    return bgs[index % bgs.length];
  }
}
