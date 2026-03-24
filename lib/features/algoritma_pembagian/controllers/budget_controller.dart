import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/budget_calculator_service.dart';

/// Controller yang mengelola state budget aktif.
///
/// Bertanggung jawab untuk:
/// - Menyimpan budget bulan ini
/// - Memicu kalkulasi ulang saat ada perubahan
/// - Menyediakan data siap pakai ke UI
///
/// Controller ini **tidak bergantung pada framework state management tertentu**,
/// sehingga mudah diadaptasi ke Provider, GetX, Riverpod, maupun BLoC.
///
/// Contoh penggunaan dengan setState (Flutter biasa):
/// ```dart
/// final controller = BudgetController();
/// await controller.inisialisasi(budgetBulanan: 3000000, bulan: DateTime.now());
/// print(controller.budgetHarian); // Rp 96.774
/// ```
class BudgetController {
  final BudgetCalculatorService _calculatorService;

  BudgetController({
    BudgetCalculatorService? calculatorService,
  }) : _calculatorService = calculatorService ?? const BudgetCalculatorService();

  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────

  BudgetModel? _budget;
  List<TransactionModel> _transaksi = [];

  /// Budget aktif bulan ini. Null jika belum diinisialisasi.
  BudgetModel? get budget => _budget;

  /// Apakah budget sudah diinisialisasi.
  bool get sudahDiinisialisasi => _budget != null;

  // ─────────────────────────────────────────
  // GETTER SIAP PAKAI UNTUK UI
  // ─────────────────────────────────────────

  /// Budget harian (rupiah). Returns 0 jika belum diinisialisasi.
  double get budgetHarian => _budget?.budgetHarian ?? 0;

  /// Total pengeluaran bulan ini (rupiah).
  double get totalPengeluaran => _budget?.totalPengeluaran ?? 0;

  /// Sisa budget bulan ini (rupiah). Bisa negatif jika over budget.
  double get sisaBudget => _budget?.sisaBudget ?? 0;

  /// Apakah pengeluaran sudah melebihi budget bulanan.
  bool get isMelebihiBudget => _budget?.isMelebihiBudget ?? false;

  /// Persentase pemakaian budget (0.0 - 1.0+).
  double get persentasePemakaian => _budget?.persentasePemakaian ?? 0;

  /// Budget kumulatif yang seharusnya terpakai sampai hari ini.
  double get budgetKumulatifSeharusnya {
    if (_budget == null) return 0;
    return _calculatorService.hitungBudgetKumulatifSampaiHariIni(
      budgetBulanan: _budget!.budgetBulanan,
      bulan: _budget!.bulan,
    );
  }

  /// Selisih pengeluaran hari ini vs budget harian.
  /// Positif = over, negatif = masih aman.
  double get selisihBudgetHariIni {
    if (_budget == null) return 0;
    return _calculatorService.hitungSelisihBudgetHarian(
      budgetBulanan: _budget!.budgetBulanan,
      transaksi: _transaksi,
      bulan: _budget!.bulan,
    );
  }

  // ─────────────────────────────────────────
  // GETTER UNTUK 3 WIDGET UTAMA
  // ─────────────────────────────────────────

  /// [Widget 1 — Saldo Saya]
  /// Budget awal dikurangi total pengeluaran bulan ini.
  /// Otomatis berubah real-time setiap kali ada transaksi baru.
  ///
  /// Contoh: budget Rp 3.000.000, sudah keluar Rp 500.000
  /// → tampilkan Rp 2.500.000
  double get saldoSaya => sisaBudget;

  /// [Widget 2 — Budget Hari Ini]
  /// Sisa jatah uang jajan untuk hari ini.
  /// Dihitung dari: budget harian - pengeluaran hari ini.
  ///
  /// Otomatis berkurang real-time setiap kali ada transaksi baru.
  /// Bisa negatif jika pengeluaran hari ini sudah melebihi jatah.
  ///
  /// Contoh: jatah harian Rp 96.774, sudah keluar Rp 30.000
  /// → tampilkan Rp 66.774
  double get sisaBudgetHariIni => -(selisihBudgetHariIni);

  /// Apakah budget hari ini sudah habis / over.
  /// Gunakan ini untuk ubah warna widget jadi merah sebagai peringatan.
  ///
  /// Contoh di UI:
  /// ```dart
  /// color: _budgetCtrl.isOverBudgetHariIni ? Colors.red : Colors.green,
  /// ```
  bool get isOverBudgetHariIni => sisaBudgetHariIni < 0;

  /// [Widget 3 — Total Pengeluaran]
  /// Total yang sudah dihabiskan dalam periode bulan ini.
  ///
  /// Contoh: sudah keluar Rp 500.000 dari budget Rp 3.000.000
  /// → tampilkan Rp 500.000
  double get totalPengeluaranBulanIni => totalPengeluaran;

  // ─────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────

  /// Menginisialisasi atau mengganti budget aktif.
  ///
  /// Dipanggil saat pengguna pertama kali mengatur budget,
  /// atau saat ganti bulan.
  void inisialisasi({
    required double budgetBulanan,
    required DateTime bulan,
  }) {
    assert(budgetBulanan > 0, 'Budget bulanan harus lebih dari 0');

    _budget = BudgetModel(
      budgetBulanan: budgetBulanan,
      bulan: bulan,
    );

    // Hitung ulang berdasarkan transaksi yang mungkin sudah ada
    _hitungUlang();
  }

  /// Memperbarui daftar transaksi dan menghitung ulang budget.
  ///
  /// Dipanggil setiap kali ada penambahan atau penghapusan transaksi.
  void perbaruiTransaksi(List<TransactionModel> transaksi) {
    _transaksi = List.unmodifiable(transaksi);
    _hitungUlang();
  }

  /// Mengubah nominal budget bulanan.
  ///
  /// Berguna jika pengguna ingin menyesuaikan budget di tengah bulan.
  void ubahBudgetBulanan(double budgetBaru) {
    if (_budget == null) return;
    assert(budgetBaru > 0, 'Budget bulanan harus lebih dari 0');

    _budget = _budget!.copyWith(budgetBulanan: budgetBaru);
    _hitungUlang();
  }

  // ─────────────────────────────────────────
  // PRIVATE
  // ─────────────────────────────────────────

  void _hitungUlang() {
    if (_budget == null) return;
    _budget = _calculatorService.perbaruiBudget(
      budget: _budget!,
      transaksi: _transaksi,
    );
  }
}