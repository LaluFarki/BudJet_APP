// algoritma_pembagian.dart
// Compatibility layer — menyediakan kembali API lama yang dipakai oleh unit test.
// Class-class ini merepresentasikan domain model dan service untuk manajemen budget mahasiswa.

// ─────────────────────────────────────────────────────
// ENUM: KategoriTransaksi
// ─────────────────────────────────────────────────────
enum KategoriTransaksi {
  makananMinuman,
  transportasi,
  belanja,
  hiburan,
  kesehatan,
  pendidikan,
  lainnya;

  String get label {
    switch (this) {
      case KategoriTransaksi.makananMinuman:
        return 'Makanan & Minuman';
      case KategoriTransaksi.transportasi:
        return 'Transportasi';
      case KategoriTransaksi.belanja:
        return 'Belanja';
      case KategoriTransaksi.hiburan:
        return 'Hiburan';
      case KategoriTransaksi.kesehatan:
        return 'Kesehatan';
      case KategoriTransaksi.pendidikan:
        return 'Pendidikan';
      case KategoriTransaksi.lainnya:
        return 'Lainnya';
    }
  }

  static KategoriTransaksi fromString(String value) {
    return KategoriTransaksi.values.firstWhere(
      (e) => e.name == value,
      orElse: () => KategoriTransaksi.lainnya,
    );
  }
}


// ─────────────────────────────────────────────────────
// MODEL: TransactionModel (versi algoritma lama)
// ─────────────────────────────────────────────────────
class TransactionModel {
  final String id;
  final double nominal;
  final KategoriTransaksi kategori;
  final DateTime tanggal;
  final String keterangan;

  const TransactionModel({
    required this.id,
    required this.nominal,
    required this.kategori,
    required this.tanggal,
    this.keterangan = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nominal': nominal,
        'kategori': kategori.name,
        'tanggal': tanggal.toIso8601String(),
        'keterangan': keterangan,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      kategori: KategoriTransaksi.fromString(map['kategori'] as String),
      tanggal: DateTime.parse(map['tanggal'] as String),
      keterangan: map['keterangan'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────
// MODEL: BudgetModel
// ─────────────────────────────────────────────────────
class BudgetModel {
  final double budgetBulanan;
  final DateTime bulan;
  final double totalPengeluaran;

  const BudgetModel({
    required this.budgetBulanan,
    required this.bulan,
    this.totalPengeluaran = 0,
  });

  int get _jumlahHari =>
      DateTime(bulan.year, bulan.month + 1, 0).day;

  double get budgetHarian => budgetBulanan / _jumlahHari;
  double get sisaBudget => budgetBulanan - totalPengeluaran;
  bool get isMelebihiBudget => totalPengeluaran > budgetBulanan;
  double get persentasePemakaian =>
      budgetBulanan == 0 ? 0 : totalPengeluaran / budgetBulanan;

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
}

// ─────────────────────────────────────────────────────
// MODEL: CategoryBudgetModel
// ─────────────────────────────────────────────────────
class CategoryBudgetModel {
  final KategoriTransaksi kategori;
  final double budgetDiAlokasikan;
  final double totalDigunakan;

  const CategoryBudgetModel({
    required this.kategori,
    required this.budgetDiAlokasikan,
    required this.totalDigunakan,
  });

  double get sisaBudgetKategori => budgetDiAlokasikan - totalDigunakan;
  bool get isMelebihiAlokasi => totalDigunakan > budgetDiAlokasikan;
  double get persentasePemakaian =>
      budgetDiAlokasikan == 0 ? 0 : totalDigunakan / budgetDiAlokasikan;
}

// ─────────────────────────────────────────────────────
// SERVICE: BudgetCalculatorService
// ─────────────────────────────────────────────────────
class BudgetCalculatorService {
  const BudgetCalculatorService();

  int _jumlahHari(DateTime bulan) =>
      DateTime(bulan.year, bulan.month + 1, 0).day;

  double hitungBudgetHarian({
    required double budgetBulanan,
    required DateTime bulan,
  }) =>
      budgetBulanan / _jumlahHari(bulan);

  double hitungSisaBudget({
    required double budgetBulanan,
    required double totalPengeluaran,
  }) =>
      budgetBulanan - totalPengeluaran;

  double hitungTotalPengeluaran({
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    return transaksi
        .where((t) =>
            t.tanggal.year == bulan.year && t.tanggal.month == bulan.month)
        .fold(0.0, (sum, t) => sum + t.nominal);
  }

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
}

// ─────────────────────────────────────────────────────
// MODEL: RingkasanBulanan (return type SpendingTrackerService)
// ─────────────────────────────────────────────────────
class RingkasanBulanan {
  final double total;
  final int jumlahTransaksi;
  final TransactionModel? transaksiTerbesar;

  const RingkasanBulanan({
    required this.total,
    required this.jumlahTransaksi,
    this.transaksiTerbesar,
  });
}

// ─────────────────────────────────────────────────────
// SERVICE: SpendingTrackerService
// ─────────────────────────────────────────────────────
class SpendingTrackerService {
  const SpendingTrackerService();

  List<TransactionModel> _filterBulan(
    List<TransactionModel> transaksi,
    DateTime bulan,
  ) =>
      transaksi
          .where((t) =>
              t.tanggal.year == bulan.year && t.tanggal.month == bulan.month)
          .toList();

  RingkasanBulanan ringkasanBulanan({
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    final filtered = _filterBulan(transaksi, bulan);
    final total = filtered.fold(0.0, (sum, t) => sum + t.nominal);
    final terbesar = filtered.isEmpty
        ? null
        : filtered.reduce((a, b) => a.nominal >= b.nominal ? a : b);

    return RingkasanBulanan(
      total: total,
      jumlahTransaksi: filtered.length,
      transaksiTerbesar: terbesar,
    );
  }

  Map<int, double> pengeluaranPerHari({
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    final filtered = _filterBulan(transaksi, bulan);
    final Map<int, double> result = {};
    for (final t in filtered) {
      result[t.tanggal.day] = (result[t.tanggal.day] ?? 0) + t.nominal;
    }
    return result;
  }

  List<TransactionModel> transaksiTerbaru({
    required List<TransactionModel> transaksi,
    int limit = 5,
  }) {
    final sorted = [...transaksi]
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return sorted.take(limit).toList();
  }
}

// ─────────────────────────────────────────────────────
// SERVICE: CategoryService
// ─────────────────────────────────────────────────────
class CategoryService {
  const CategoryService();

  List<CategoryBudgetModel> hitungRealisasiPerKategori({
    required Map<KategoriTransaksi, double> alokasiBudget,
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    return alokasiBudget.entries.map((entry) {
      final kategori = entry.key;
      final alokasi = entry.value;
      final total = transaksi
          .where((t) =>
              t.kategori == kategori &&
              t.tanggal.year == bulan.year &&
              t.tanggal.month == bulan.month)
          .fold(0.0, (sum, t) => sum + t.nominal);

      return CategoryBudgetModel(
        kategori: kategori,
        budgetDiAlokasikan: alokasi,
        totalDigunakan: total,
      );
    }).toList();
  }

  double hitungSisaAlokasi({
    required double budgetBulanan,
    required Map<KategoriTransaksi, double> alokasiBudget,
  }) {
    final totalAlokasi = alokasiBudget.values.fold(0.0, (a, b) => a + b);
    return budgetBulanan - totalAlokasi;
  }

  bool isTotalAlokasiMelebihi({
    required double budgetBulanan,
    required Map<KategoriTransaksi, double> alokasiBudget,
  }) {
    final total = alokasiBudget.values.fold(0.0, (a, b) => a + b);
    return total > budgetBulanan;
  }

  CategoryBudgetModel? kategoriTerboros(List<CategoryBudgetModel> list) {
    if (list.isEmpty) return null;
    return list.reduce(
        (a, b) => a.totalDigunakan >= b.totalDigunakan ? a : b);
  }
}

// ─────────────────────────────────────────────────────
// CONTROLLER: BudgetController
// ─────────────────────────────────────────────────────
class BudgetController {
  BudgetModel? _budget;
  final _service = const BudgetCalculatorService();

  bool get sudahDiinisialisasi => _budget != null;
  double get budgetHarian => _budget?.budgetHarian ?? 0;
  double get sisaBudget => _budget?.sisaBudget ?? 0;
  double get totalPengeluaran => _budget?.totalPengeluaran ?? 0;
  bool get isMelebihiBudget => _budget?.isMelebihiBudget ?? false;

  void inisialisasi({
    required double budgetBulanan,
    required DateTime bulan,
  }) {
    _budget = BudgetModel(budgetBulanan: budgetBulanan, bulan: bulan);
  }

  void perbaruiTransaksi(List<TransactionModel> transaksi) {
    if (_budget == null) return;
    _budget = _service.perbaruiBudget(budget: _budget!, transaksi: transaksi);
  }

  void ubahBudgetBulanan(double nilai) {
    if (_budget == null) return;
    _budget = _budget!.copyWith(budgetBulanan: nilai);
  }
}

// ─────────────────────────────────────────────────────
// CONTROLLER: TransactionController (versi algoritma, bukan GetX)
// ─────────────────────────────────────────────────────
class TransactionController {
  final void Function(List<TransactionModel>)? onTransaksiChanged;
  final List<TransactionModel> _list = [];

  TransactionController({this.onTransaksiChanged});

  List<TransactionModel> get semuaTransaksi => List.unmodifiable(_list);

  void tambahTransaksi(TransactionModel tx) {
    _list.add(tx);
    onTransaksiChanged?.call(semuaTransaksi);
  }

  void hapusTransaksi(String id) {
    _list.removeWhere((t) => t.id == id);
    onTransaksiChanged?.call(semuaTransaksi);
  }
}

// ─────────────────────────────────────────────────────
// CONTROLLER: CategoryController
// ─────────────────────────────────────────────────────
class CategoryController {
  final Map<KategoriTransaksi, double> _alokasi = {};
  List<CategoryBudgetModel> _kategoriList = [];
  final _service = const CategoryService();

  Map<KategoriTransaksi, double> get alokasiBudget =>
      Map.unmodifiable(_alokasi);
  List<CategoryBudgetModel> get kategoriList =>
      List.unmodifiable(_kategoriList);

  double get totalAlokasi => _alokasi.values.fold(0.0, (a, b) => a + b);

  void aturAlokasi(KategoriTransaksi kategori, double nominal) {
    _alokasi[kategori] = nominal;
  }

  bool isAlokasiMelebihi(double budgetBulanan) =>
      totalAlokasi > budgetBulanan;

  void perbaruiRealisasi({
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    _kategoriList = _service.hitungRealisasiPerKategori(
      alokasiBudget: _alokasi,
      transaksi: transaksi,
      bulan: bulan,
    );
  }

  void hapusAlokasi(KategoriTransaksi kategori) {
    _alokasi.remove(kategori);
  }

  void resetAlokasi() {
    _alokasi.clear();
    _kategoriList = [];
  }
}
