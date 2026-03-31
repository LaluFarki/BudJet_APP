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

  /// Menentukan Icon berdasarkan Kategori atau Judul Transaksi otomatis
  static IconData getCategoryIcon(String category, String title) {
    final lowerTitle = title.toLowerCase();
    
    // Pengecekan Khusus berdasarkan Judul (Koreksi & Top-Up)
    if (lowerTitle.contains('koreksi')) return Icons.price_change_outlined;
    if (lowerTitle.contains('top-up') || lowerTitle.contains('gaji') || lowerTitle.contains('tambah saldo')) {
      return Icons.monetization_on; // Ikon koin mata uang
    }

    // Pengecekan Standar berdasarkan Kategori dari Form AddTransaction
    switch (category) {
      case 'Makanan & Minuman':
        return Icons.restaurant_outlined;
      case 'Transportasi':
        return Icons.directions_car_outlined;
      case 'Belanja':
        return Icons.shopping_bag_outlined;
      case 'Hiburan':
        return Icons.sports_esports_outlined;
      case 'Lainnya':
      default:
        return Icons.category_outlined;
    }
  }

  /// Menentukan Warna Icon berdasarkan Kategori atau Judul Transaksi
  static Color getCategoryColor(String category, String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('koreksi')) return Colors.red; // Koreksi saldo selalu merah/pink
    if (lowerTitle.contains('top-up') || lowerTitle.contains('gaji') || lowerTitle.contains('tambah saldo')) {
      return Colors.green; // Uang masuk hijau
    }

    switch (category) {
      case 'Makanan & Minuman':
        return Colors.orange;
      case 'Transportasi':
        return Colors.blue;
      case 'Belanja':
        return Colors.purple;
      case 'Hiburan':
        return Colors.pink;
      case 'Lainnya':
      default:
        return Colors.grey.shade600;
    }
  }
}
