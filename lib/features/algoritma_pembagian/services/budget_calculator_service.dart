import '../models/budget_model.dart';
import '../models/transaction_model.dart';

/// Service yang berisi algoritma inti perhitungan budget.
///
/// Kelas ini **hanya berisi logika murni** — tidak menyimpan state,
/// tidak berinteraksi dengan database, dan tidak tahu soal UI.
/// Semua method bersifat pure function: input yang sama selalu
/// menghasilkan output yang sama.
///
/// Cara pakai (dari controller):
/// ```dart
/// final service = BudgetCalculatorService();
/// final harian = service.hitungBudgetHarian(budgetBulanan: 3000000, bulan: DateTime.now());
/// ```
class BudgetCalculatorService {
  const BudgetCalculatorService();

  // ─────────────────────────────────────────
  // PERHITUNGAN BUDGET HARIAN
  // ─────────────────────────────────────────

  /// Menghitung budget harian dengan rumus:
  /// **budget harian = budget bulanan ÷ jumlah hari dalam bulan**
  ///
  /// [budgetBulanan] : nominal budget yang diatur pengguna (rupiah)
  /// [bulan]         : bulan yang dihitung (hanya month & year yang digunakan)
  ///
  /// Contoh:
  /// - Budget Rp 3.000.000, bulan Januari (31 hari) → Rp 96.774/hari
  /// - Budget Rp 3.000.000, bulan Februari (28 hari) → Rp 107.143/hari
  double hitungBudgetHarian({
    required double budgetBulanan,
    required DateTime bulan,
  }) {
    assert(budgetBulanan >= 0, 'Budget bulanan tidak boleh negatif');
    final jumlahHari = _jumlahHariDalamBulan(bulan);
    return budgetBulanan / jumlahHari;
  }

  /// Menghitung budget kumulatif sampai hari ini.
  ///
  /// Berguna untuk mengecek: "seharusnya sudah habis berapa sampai hari ini?"
  ///
  /// Contoh: tanggal 15 Januari, budget harian Rp 96.774
  /// → seharusnya sudah terpakai Rp 96.774 × 15 = Rp 1.451.610
  double hitungBudgetKumulatifSampaiHariIni({
    required double budgetBulanan,
    required DateTime bulan,
  }) {
    final harian = hitungBudgetHarian(budgetBulanan: budgetBulanan, bulan: bulan);
    final hariIni = DateTime.now().day;
    // Pastikan tidak melebihi jumlah hari dalam bulan
    final hariDipakai = hariIni.clamp(1, _jumlahHariDalamBulan(bulan));
    return harian * hariDipakai;
  }

  // ─────────────────────────────────────────
  // PERHITUNGAN SISA BUDGET
  // ─────────────────────────────────────────

  /// Menghitung sisa budget bulanan secara real-time.
  ///
  /// **sisa budget = budget bulanan - total pengeluaran**
  ///
  /// Hasilnya bisa negatif jika sudah over budget.
  double hitungSisaBudget({
    required double budgetBulanan,
    required double totalPengeluaran,
  }) {
    return budgetBulanan - totalPengeluaran;
  }

  /// Menghitung total pengeluaran dari daftar transaksi.
  ///
  /// Hanya menjumlahkan transaksi yang ada di bulan yang ditentukan.
  ///
  /// [transaksi] : daftar semua transaksi
  /// [bulan]     : filter bulan (hanya month & year yang dicocokkan)
  double hitungTotalPengeluaran({
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    return transaksi
        .where((t) => _adalahBulanYangSama(t.tanggal, bulan))
        .fold(0.0, (total, t) => total + t.nominal);
  }

  /// Menghitung apakah pengeluaran hari ini melebihi budget harian.
  ///
  /// Mengembalikan selisihnya (positif = over, negatif = masih aman).
  double hitungSelisihBudgetHarian({
    required double budgetBulanan,
    required List<TransactionModel> transaksi,
    required DateTime bulan,
    DateTime? tanggalTarget, // default: hari ini
  }) {
    final target = tanggalTarget ?? DateTime.now();
    final harian = hitungBudgetHarian(budgetBulanan: budgetBulanan, bulan: bulan);

    final pengeluaranHariIni = transaksi
        .where((t) => _adalahHariYangSama(t.tanggal, target))
        .fold(0.0, (total, t) => total + t.nominal);

    // Positif = over budget harian, negatif = masih aman
    return pengeluaranHariIni - harian;
  }

  // ─────────────────────────────────────────
  // HELPER DARI BudgetModel
  // ─────────────────────────────────────────

  /// Memperbarui [BudgetModel] berdasarkan daftar transaksi terbaru.
  ///
  /// Menghitung ulang [totalPengeluaran] dari daftar transaksi.
  BudgetModel perbaruiBudget({
    required BudgetModel budget,
    required List<TransactionModel> transaksi,
  }) {
    final total = hitungTotalPengeluaran(
      transaksi: transaksi,
      bulan: budget.bulan,
    );
    return budget.copyWith(totalPengeluaran: total);
  }

  // ─────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────

  /// Menghitung jumlah hari dalam sebulan.
  int _jumlahHariDalamBulan(DateTime tanggal) {
    final bulanBerikutnya = DateTime(tanggal.year, tanggal.month + 1, 1);
    return bulanBerikutnya.subtract(const Duration(days: 1)).day;
  }

  /// Mengecek apakah dua DateTime berada di bulan dan tahun yang sama.
  bool _adalahBulanYangSama(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// Mengecek apakah dua DateTime berada di hari yang sama.
  bool _adalahHariYangSama(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
