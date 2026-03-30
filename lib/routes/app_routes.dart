import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/algoritma_pembagian/algoritma_playground.dart';

// Mengimpor file MainScreen yang ada di folder features/home/views
// File ini berisi tampilan halaman utama aplikasi
import '../features/home/views/main_screen.dart';

// Mengimpor file HistoryScreen yang ada di folder features/history/views
// File ini berisi tampilan halaman riwayat transaksi
import '../features/history/views/history_screen.dart';
import '../features/riwayat_transaksi/views/riwayat_transaksi_screen.dart';
import '../features/transaction/views/add_transaction_screen.dart';
import '../features/transaction/views/success_transaction_screen.dart';
import '../features/transaction/views/today_transactions_screen.dart';
import '../features/budget/views/budget_screen.dart';
import '../features/profile/views/data_diri_screen.dart';

class AppRoutes {
  // Membuat nama route untuk halaman home
  // '/' adalah route default saat aplikasi pertama kali dibuka
  static const String home = '/';

  // Membuat nama route untuk halaman history
  // route ini akan digunakan ketika ingin membuka halaman riwayat
  static const String history = '/history';
  static const String budget = '/budget';
  static const String dataDiri = '/data-diri';
  // [PLAYGROUND] Route sementara — hapus setelah frontend jadi
  static const String playground = '/playground';
  static const String riwayatTransaksi = '/riwayat-transaksi';
  static const String todayTx = '/today-tx';
  static const String addTx = '/add-tx';
  static const String successTx = '/success-tx';

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

      // [PLAYGROUND] Hapus baris ini setelah frontend jadi
      // playground: (context) => const AlgoritmaPlayground(),
      budget: (context) => const BudgetScreen(),
      dataDiri: (context) => const DataDiriScreen(),
      riwayatTransaksi: (context) => const RiwayatTransaksiScreen(),
      todayTx: (context) => const TodayTransactionsScreen(),
      addTx: (context) => AddTransactionScreen(),
      successTx: (context) => const SuccessTransactionScreen(),
    };
  }
}
