import '../models/category_budget_model.dart';
import '../models/transaction_model.dart';
import '../services/category_service.dart';

/// Controller yang mengelola alokasi dan realisasi budget per kategori.
///
/// Pengguna bebas mengatur nominal budget tiap kategori dalam rupiah.
/// Controller ini memastikan total alokasi tidak melebihi budget bulanan,
/// lalu menghitung realisasi dari transaksi aktual.
///
/// Contoh penggunaan:
/// ```dart
/// final controller = CategoryController();
///
/// // Pengguna mengatur nominal budget tiap kategori
/// controller.aturAlokasi(KategoriTransaksi.makananMinuman, 800000);
/// controller.aturAlokasi(KategoriTransaksi.transportasi, 400000);
/// controller.aturAlokasi(KategoriTransaksi.hiburan, 200000);
///
/// // Hitung realisasi dari transaksi
/// controller.perbaruiRealisasi(
///   transaksi: semuaTransaksi,
///   bulan: DateTime.now(),
/// );
///
/// print(controller.kategoriList); // Daftar [CategoryBudgetModel]
/// ```
class CategoryController {
  final CategoryService _categoryService;

  CategoryController({
    CategoryService? categoryService,
  }) : _categoryService = categoryService ?? const CategoryService();

  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────

  /// Alokasi budget yang diatur pengguna: kategori → nominal (rupiah).
  final Map<KategoriTransaksi, double> _alokasiBudget = {};

  /// Hasil gabungan alokasi + realisasi aktual.
  List<CategoryBudgetModel> _kategoriList = [];

  /// Daftar kategori beserta status realisasinya (read-only).
  List<CategoryBudgetModel> get kategoriList => List.unmodifiable(_kategoriList);

  /// Alokasi budget yang sudah diatur (read-only).
  Map<KategoriTransaksi, double> get alokasiBudget =>
      Map.unmodifiable(_alokasiBudget);

  // ─────────────────────────────────────────
  // ACTIONS — ATUR ALOKASI
  // ─────────────────────────────────────────

  /// Mengatur nominal budget untuk satu kategori.
  ///
  /// Jika kategori sudah ada, nilainya akan di-overwrite.
  /// [nominal] harus >= 0.
  void aturAlokasi(KategoriTransaksi kategori, double nominal) {
    assert(nominal >= 0, 'Nominal alokasi tidak boleh negatif');
    _alokasiBudget[kategori] = nominal;
  }

  /// Menghapus alokasi untuk satu kategori.
  void hapusAlokasi(KategoriTransaksi kategori) {
    _alokasiBudget.remove(kategori);
    _kategoriList.removeWhere((k) => k.kategori == kategori);
  }

  /// Menghapus semua alokasi (reset).
  void resetAlokasi() {
    _alokasiBudget.clear();
    _kategoriList = [];
  }

  // ─────────────────────────────────────────
  // ACTIONS — PERBARUI REALISASI
  // ─────────────────────────────────────────

  /// Menghitung ulang realisasi berdasarkan transaksi terbaru.
  ///
  /// Harus dipanggil setiap kali ada transaksi baru atau dihapus.
  void perbaruiRealisasi({
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    _kategoriList = _categoryService.hitungRealisasiPerKategori(
      alokasiBudget: _alokasiBudget,
      transaksi: transaksi,
      bulan: bulan,
    );
  }

  // ─────────────────────────────────────────
  // GETTER TURUNAN
  // ─────────────────────────────────────────

  /// Total nominal yang sudah dialokasikan ke semua kategori.
  double get totalAlokasi => _categoryService.totalAlokasi(_alokasiBudget);

  /// Sisa budget yang belum dialokasikan ke kategori mana pun.
  double sisaAlokasiDari(double budgetBulanan) {
    return _categoryService.hitungSisaAlokasi(
      budgetBulanan: budgetBulanan,
      alokasiBudget: _alokasiBudget,
    );
  }

  /// Apakah total alokasi sudah melebihi budget bulanan.
  bool isAlokasiMelebihi(double budgetBulanan) {
    return _categoryService.isTotalAlokasiMelebihi(
      budgetBulanan: budgetBulanan,
      alokasiBudget: _alokasiBudget,
    );
  }

  /// Kategori dengan pengeluaran terbesar bulan ini.
  CategoryBudgetModel? get kategoriTerboros =>
      _categoryService.kategoriTerboros(_kategoriList);

  /// Kategori yang sudah melebihi alokasi budget-nya.
  List<CategoryBudgetModel> get kategoriOverBudget =>
      _categoryService.kategoriOverBudget(_kategoriList);
}
