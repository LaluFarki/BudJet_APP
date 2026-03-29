/// Model yang merepresentasikan data budget pengguna.
///
/// [BudgetModel] menyimpan informasi budget bulanan, budget harian otomatis,
/// dan sisa budget yang tersedia secara real-time.
///
/// Contoh penggunaan:
/// ```dart
/// final budget = BudgetModel(
///   budgetBulanan: 3000000,
///   bulan: DateTime(2024, 1),
/// );
/// ```
class BudgetModel {
  /// Budget awal yang diatur pengguna untuk satu bulan (dalam rupiah).
  final double budgetBulanan;

  /// Bulan dan tahun berlakunya budget ini.
  /// Hanya bagian bulan dan tahun yang digunakan, hari diabaikan.
  final DateTime bulan;

  /// Total pengeluaran yang sudah terjadi di bulan ini (dalam rupiah).
  final double totalPengeluaran;

  const BudgetModel({
    required this.budgetBulanan,
    required this.bulan,
    this.totalPengeluaran = 0,
  });

  /// Budget harian otomatis = budget bulanan ÷ jumlah hari dalam bulan.
  ///
  /// Contoh: budget Rp 3.000.000 di bulan Januari (31 hari)
  /// → Rp 3.000.000 ÷ 31 = Rp 96.774/hari
  double get budgetHarian {
    final jumlahHari = _jumlahHariDalamBulan(bulan);
    return budgetBulanan / jumlahHari;
  }

  /// Sisa budget real-time = budget bulanan - total pengeluaran.
  double get sisaBudget => budgetBulanan - totalPengeluaran;

  /// Apakah pengguna sudah melebihi budget bulanan.
  bool get isMelebihiBudget => totalPengeluaran > budgetBulanan;

  /// Persentase pemakaian budget (0.0 - 1.0+).
  /// Bisa lebih dari 1.0 jika sudah over budget.
  double get persentasePemakaian {
    if (budgetBulanan == 0) return 0;
    return totalPengeluaran / budgetBulanan;
  }

  /// Menghitung jumlah hari dalam bulan tertentu.
  int _jumlahHariDalamBulan(DateTime tanggal) {
    // Ambil hari pertama bulan berikutnya, lalu mundur 1 hari
    final bulanBerikutnya = DateTime(tanggal.year, tanggal.month + 1, 1);
    return bulanBerikutnya.subtract(const Duration(days: 1)).day;
  }

  /// Membuat salinan [BudgetModel] dengan nilai yang diubah.
  BudgetModel copyWith({
    double? budgetBulanan,
    DateTime? bulan,
    double? totalPengeluaran,
  }) {
    return BudgetModel(
      budgetBulanan: budgetBulanan ?? this.budgetBulanan,
      bulan: bulan ?? this.bulan,
      totalPengeluaran: totalPengeluaran ?? this.totalPengeluaran,
    );
  }

  /// Konversi dari Map (misal: dari database lokal / JSON).
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      budgetBulanan: (map['budget_bulanan'] as num).toDouble(),
      bulan: DateTime.parse(map['bulan'] as String),
      totalPengeluaran: (map['total_pengeluaran'] as num? ?? 0).toDouble(),
    );
  }

  /// Konversi ke Map (misal: untuk disimpan ke database lokal / JSON).
  Map<String, dynamic> toMap() {
    return {
      'budget_bulanan': budgetBulanan,
      'bulan': bulan.toIso8601String(),
      'total_pengeluaran': totalPengeluaran,
    };
  }

  @override
  String toString() {
    return 'BudgetModel('
        'budgetBulanan: $budgetBulanan, '
        'bulan: $bulan, '
        'totalPengeluaran: $totalPengeluaran, '
        'sisaBudget: $sisaBudget'
        ')';
  }
}