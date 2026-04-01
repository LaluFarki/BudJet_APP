import 'package:flutter/material.dart';

// 🔥 Features yang dipakai
import 'package:budjet/features/input_budget/layar/layar_awal.dart';
import '../features/home/views/main_screen.dart';
import '../features/history/views/history_screen.dart';
import '../features/riwayat_transaksi/views/riwayat_transaksi_screen.dart';
import '../features/transaction/views/add_transaction_screen.dart';
import '../features/transaction/views/success_transaction_screen.dart';
import '../features/transaction/views/today_transactions_screen.dart';
import '../features/budget/views/budget_screen.dart';
import '../features/budget/views/edit_budget_screen.dart';
import '../features/profile/views/data_diri_screen.dart';

class AppRoutes {
  // Default route
  static const String home = '/';

  // Awal
  static const String awal = '/awal';

  // Route lain
  static const String history = '/history';
  static const String budget = '/budget';
  static const String editBudget = '/edit-budget';
  static const String dataDiri = '/data-diri';
  static const String riwayatTransaksi = '/riwayat-transaksi';
  static const String todayTx = '/today-tx';
  static const String addTx = '/add-tx';
  static const String successTx = '/success-tx';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      awal: (context) => LayarAwal(),

      home: (context) => const MainScreen(),

      history: (context) => const HistoryScreen(),

      budget: (context) => const BudgetScreen(),

      editBudget: (context) => const EditBudgetScreen(),

      dataDiri: (context) => const DataDiriScreen(),

      riwayatTransaksi: (context) => const RiwayatTransaksiScreen(),

      todayTx: (context) => const TodayTransactionsScreen(),

      addTx: (context) => AddTransactionScreen(),

      successTx: (context) => const SuccessTransactionScreen(),
    };
  }
}
