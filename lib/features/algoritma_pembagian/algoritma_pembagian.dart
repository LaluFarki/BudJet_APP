/// Barrel export untuk fitur algoritma pembagian budget.
///
/// Fitur lain cukup import file ini satu kali:
/// ```dart
/// import 'package:nama_app/features/algoritma-pembagian/algoritma_pembagian.dart';
/// ```
///
/// ─────────────────────────────────────────
/// MODELS
/// ─────────────────────────────────────────
/// [BudgetModel]          — Data budget bulanan + kalkulasi harian & sisa
/// [TransactionModel]     — Data satu transaksi pengeluaran
/// [KategoriTransaksi]    — Enum kategori (makanan, transportasi, dll)
/// [CategoryBudgetModel]  — Alokasi + realisasi budget per kategori
///
/// ─────────────────────────────────────────
/// SERVICES (logika murni, tanpa state)
/// ─────────────────────────────────────────
/// [BudgetCalculatorService] — Hitung budget harian, sisa, kumulatif
/// [SpendingTrackerService]  — Lacak & rangkum pengeluaran
/// [CategoryService]         — Hitung alokasi & realisasi per kategori
///
/// ─────────────────────────────────────────
/// CONTROLLERS (kelola state, koordinasi)
/// ─────────────────────────────────────────
/// [BudgetController]      — State budget aktif bulan ini
/// [TransactionController] — Tambah/hapus transaksi, ringkasan
/// [CategoryController]    — Atur alokasi & realisasi per kategori
library;

// Models
export 'models/budget_model.dart';
export 'models/transaction_model.dart';
export 'models/category_budget_model.dart';

// Services
export 'services/budget_calculator_service.dart';
export 'services/spending_tracker_service.dart';
export 'services/category_service.dart';

// Controllers
export 'controllers/budget_controller.dart';
export 'controllers/transaction_controller.dart';
export 'controllers/category_controller.dart';

// Utils
export 'utils/date_formatter.dart';
