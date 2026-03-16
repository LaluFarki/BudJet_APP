import 'package:flutter/material.dart';

// Mengimpor file MainScreen yang ada di folder features/home/views
// File ini berisi tampilan halaman utama aplikasi
import '../features/home/views/main_screen.dart';

// Mengimpor file HistoryScreen yang ada di folder features/history/views
// File ini berisi tampilan halaman riwayat transaksi
import '../features/history/views/history_screen.dart';

// Class AppRoutes digunakan sebagai pusat pengaturan navigasi aplikasi
// Semua halaman (screen) yang bisa dibuka di aplikasi didaftarkan di sini
class AppRoutes {
  // Membuat nama route untuk halaman home
  // '/' adalah route default saat aplikasi pertama kali dibuka
  static const String home = '/';

  // Membuat nama route untuk halaman history
  // route ini akan digunakan ketika ingin membuka halaman riwayat
  static const String history = '/history';

  // Method ini mengembalikan Map yang berisi daftar route aplikasi
  // Map ini berisi pasangan antara nama route (String)
  // dengan WidgetBuilder (fungsi untuk membangun halaman)
  static Map<String, WidgetBuilder> getRoutes() {
    // Map<String, WidgetBuilder>
    // Key   = nama route
    // Value = widget halaman yang akan ditampilkan

    return {
      // Saat aplikasi memanggil route '/'
      // Flutter akan membuka widget MainScreen
      // MainScreen biasanya berisi layout utama aplikasi
      // seperti BottomNavigationBar atau halaman utama

      // Di file main_screen.dart ada:
      // class MainScreen extends StatelessWidget
      home: (context) => const MainScreen(),

      // Saat aplikasi memanggil route '/history'
      // Flutter akan membuka halaman HistoryScreen
      // Di file history_screen.dart ada:
      // class HistoryScreen extends StatelessWidget
      history: (context) => const HistoryScreen(),
    };
  }
}
