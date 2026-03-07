import 'package:flutter/material.dart';
// PENTING: Import MainScreen, BUKAN HomeScreen
import '../features/home/views/main_screen.dart';
import '../features/history/views/history_screen.dart';

class AppRoutes {
  // Mendaftarkan nama jalan
  static const String home = '/';
  static const String history = '/history';

  // Buku daftar peta jalan
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Saat aplikasi memanggil '/', yang dibuka adalah MainScreen (Bingkai Fotonya)
      home: (context) => const MainScreen(),
      history: (context) => const HistoryScreen(),
    };
  }
}
