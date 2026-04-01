import '../models/category_budget_model.dart';
import '../models/transaction_model.dart';

/// Service untuk menghitung alokasi dan realisasi budget per kategori.
///
/// Pengguna mengatur nominal budget tiap kategori secara bebas dalam rupiah.
/// Service ini menghitung berapa yang sudah terpakai dan berapa sisa per kategori.
///
/// Cara pakai:
/// ```dart
/// final service = CategoryService();
///
/// // Daftar alokasi yang sudah diatur pengguna
/// final alokasi = {
///   KategoriTransaksi.makananMinuman: 800000.0,
///   KategoriTransaksi.transportasi: 400000.0,
/// };
///
/// final hasilKategori = service.hitungRealisasiPerKategori(
///   alokasiBudget: alokasi,
///   transaksi: semuaTransaksi,
///   bulan: DateTime.now(),
/// );
/// ```
class CategoryService {
  const CategoryService();

  // ─────────────────────────────────────────
  // HITUNG REALISASI PER KATEGORI
  // ─────────────────────────────────────────

  /// Menghitung realisasi pengeluaran untuk setiap kategori.
  ///
  /// Menerima [alokasiBudget] berupa Map kategori → nominal (rupiah),
  /// lalu mencocokkan dengan transaksi di [bulan] yang ditentukan.
  ///
  /// Mengembalikan daftar [CategoryBudgetModel] yang sudah berisi
  /// [totalDigunakan] dari transaksi aktual.
  List<CategoryBudgetModel> hitungRealisasiPerKategori({
    required Map<KategoriTransaksi, double> alokasiBudget,
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    // Filter transaksi hanya untuk bulan ini
    final transaksiSebulan = transaksi
        .where((t) => t.tanggal.year == bulan.year && t.tanggal.month == bulan.month)
        .toList();

    // Hitung total per kategori dari transaksi aktual
    final Map<KategoriTransaksi, double> totalPerKategori = {};
    for (final t in transaksiSebulan) {
      totalPerKategori[t.kategori] =
          (totalPerKategori[t.kategori] ?? 0) + t.nominal;
    }

    // Gabungkan alokasi pengguna dengan realisasi aktual
    return alokasiBudget.entries.map((entry) {
      return CategoryBudgetModel(
        kategori: entry.key,
        budgetDiAlokasikan: entry.value,
        totalDigunakan: totalPerKategori[entry.key] ?? 0,
      );
    }).toList();
  }

  // ─────────────────────────────────────────
  // VALIDASI ALOKASI
  // ─────────────────────────────────────────

  /// Memvalidasi apakah total alokasi kategori tidak melebihi budget bulanan.
  ///
  /// Mengembalikan selisih: positif = masih ada sisa, negatif = over alokasi.
  ///
  /// Contoh: budget Rp 3.000.000, total alokasi Rp 2.800.000
  /// → sisa Rp 200.000 (aman)
  double hitungSisaAlokasi({
    required double budgetBulanan,
    required Map<KategoriTransaksi, double> alokasiBudget,
  }) {
    final totalAlokasi = alokasiBudget.values.fold(0.0, (sum, v) => sum + v);
    return budgetBulanan - totalAlokasi;
  }

  /// Mengecek apakah total alokasi kategori melebihi budget bulanan.
  bool isTotalAlokasiMelebihi({
    required double budgetBulanan,
    required Map<KategoriTransaksi, double> alokasiBudget,
  }) {
    return hitungSisaAlokasi(
          budgetBulanan: budgetBulanan,
          alokasiBudget: alokasiBudget,
        ) <
        0;
  }

  // ─────────────────────────────────────────
  // RINGKASAN KATEGORI
  // ─────────────────────────────────────────

  /// Mencari kategori dengan pengeluaran terbesar.
  ///
  /// Mengembalikan null jika daftar kosong.
  CategoryBudgetModel? kategoriTerboros(
    List<CategoryBudgetModel> kategoriList,
  ) {
    if (kategoriList.isEmpty) return null;
    return kategoriList.reduce(
      (a, b) => a.totalDigunakan >= b.totalDigunakan ? a : b,
    );
  }

  /// Mencari kategori yang sudah melebihi alokasi budget-nya.
  List<CategoryBudgetModel> kategoriOverBudget(
    List<CategoryBudgetModel> kategoriList,
  ) {
    return kategoriList.where((k) => k.isMelebihiAlokasi).toList();
  }

  /// Menghitung total nominal yang sudah dialokasikan ke semua kategori.
  double totalAlokasi(Map<KategoriTransaksi, double> alokasiBudget) {
    return alokasiBudget.values.fold(0.0, (sum, v) => sum + v);
  }
}
