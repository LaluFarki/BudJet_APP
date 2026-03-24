import 'transaction_model.dart';

/// Model yang merepresentasikan alokasi budget untuk satu kategori.
///
/// Pengguna mengatur [budgetDiAlokasikan] secara manual dalam nominal rupiah.
/// Sistem kemudian menghitung realisasi dan sisa secara otomatis.
///
/// Contoh penggunaan:
/// ```dart
/// final kategoriMakan = CategoryBudgetModel(
///   kategori: KategoriTransaksi.makananMinuman,
///   budgetDiAlokasikan: 800000, // Rp 800.000 untuk makan bulan ini
/// );
/// ```
class CategoryBudgetModel {
  /// Kategori yang bersangkutan.
  final KategoriTransaksi kategori;

  /// Nominal budget yang dialokasikan pengguna untuk kategori ini (rupiah).
  final double budgetDiAlokasikan;

  /// Total pengeluaran aktual untuk kategori ini (rupiah).
  final double totalDigunakan;

  const CategoryBudgetModel({
    required this.kategori,
    required this.budgetDiAlokasikan,
    this.totalDigunakan = 0,
  });

  /// Sisa budget kategori ini = alokasi - total digunakan.
  double get sisaBudgetKategori => budgetDiAlokasikan - totalDigunakan;

  /// Apakah pengeluaran kategori ini sudah melebihi alokasi.
  bool get isMelebihiAlokasi => totalDigunakan > budgetDiAlokasikan;

  /// Persentase pemakaian kategori ini (0.0 - 1.0+).
  double get persentasePemakaian {
    if (budgetDiAlokasikan == 0) return 0;
    return totalDigunakan / budgetDiAlokasikan;
  }

  /// Membuat salinan dengan nilai yang diubah.
  CategoryBudgetModel copyWith({
    KategoriTransaksi? kategori,
    double? budgetDiAlokasikan,
    double? totalDigunakan,
  }) {
    return CategoryBudgetModel(
      kategori: kategori ?? this.kategori,
      budgetDiAlokasikan: budgetDiAlokasikan ?? this.budgetDiAlokasikan,
      totalDigunakan: totalDigunakan ?? this.totalDigunakan,
    );
  }

  /// Konversi dari Map.
  factory CategoryBudgetModel.fromMap(Map<String, dynamic> map) {
    return CategoryBudgetModel(
      kategori: KategoriTransaksi.fromString(map['kategori'] as String),
      budgetDiAlokasikan: (map['budget_dialokasikan'] as num).toDouble(),
      totalDigunakan: (map['total_digunakan'] as num? ?? 0).toDouble(),
    );
  }

  /// Konversi ke Map.
  Map<String, dynamic> toMap() {
    return {
      'kategori': kategori.name,
      'budget_dialokasikan': budgetDiAlokasikan,
      'total_digunakan': totalDigunakan,
    };
  }

  @override
  String toString() {
    return 'CategoryBudgetModel('
        'kategori: ${kategori.label}, '
        'alokasi: $budgetDiAlokasikan, '
        'digunakan: $totalDigunakan, '
        'sisa: $sisaBudgetKategori'
        ')';
  }
}