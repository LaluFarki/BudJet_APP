/// Enum untuk kategori pengeluaran.
///
/// Pengguna bebas menentukan nominal budget per kategori dalam rupiah.
enum KategoriTransaksi {
  makananMinuman,
  transportasi,
  hiburan,
  kesehatan,
  belanja,
  tagihanUtilitas,
  lainnya;

  /// Label yang ditampilkan ke pengguna di UI.
  String get label {
    switch (this) {
      case KategoriTransaksi.makananMinuman:
        return 'Makanan & Minuman';
      case KategoriTransaksi.transportasi:
        return 'Transportasi';
      case KategoriTransaksi.hiburan:
        return 'Hiburan';
      case KategoriTransaksi.kesehatan:
        return 'Kesehatan';
      case KategoriTransaksi.belanja:
        return 'Belanja';
      case KategoriTransaksi.tagihanUtilitas:
        return 'Tagihan & Utilitas';
      case KategoriTransaksi.lainnya:
        return 'Lainnya';
    }
  }

  /// Konversi dari String (untuk keperluan serialisasi).
  static KategoriTransaksi fromString(String value) {
    return KategoriTransaksi.values.firstWhere(
      (k) => k.name == value,
      orElse: () => KategoriTransaksi.lainnya,
    );
  }
}

/// Model yang merepresentasikan satu transaksi pengeluaran.
///
/// Setiap transaksi memiliki nominal, kategori, tanggal, dan keterangan opsional.
///
/// Contoh penggunaan:
/// ```dart
/// final transaksi = TransactionModel(
///   id: 'txn_001',
///   nominal: 25000,
///   kategori: KategoriTransaksi.makananMinuman,
///   tanggal: DateTime.now(),
///   keterangan: 'Makan siang',
/// );
/// ```
class TransactionModel {
  /// ID unik transaksi.
  final String id;

  /// Nominal pengeluaran dalam rupiah.
  final double nominal;

  /// Kategori pengeluaran.
  final KategoriTransaksi kategori;

  /// Tanggal dan waktu transaksi dilakukan.
  final DateTime tanggal;

  /// Keterangan opsional, misal: "Makan siang", "Bensin motor".
  final String? keterangan;

  const TransactionModel({
    required this.id,
    required this.nominal,
    required this.kategori,
    required this.tanggal,
    this.keterangan,
  });

  /// Konversi dari Map (misal: dari database lokal / JSON).
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      kategori: KategoriTransaksi.fromString(map['kategori'] as String),
      tanggal: DateTime.parse(map['tanggal'] as String),
      keterangan: map['keterangan'] as String?,
    );
  }

  /// Konversi ke Map (misal: untuk disimpan ke database lokal / JSON).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nominal': nominal,
      'kategori': kategori.name,
      'tanggal': tanggal.toIso8601String(),
      'keterangan': keterangan,
    };
  }

  /// Membuat salinan [TransactionModel] dengan nilai yang diubah.
  TransactionModel copyWith({
    String? id,
    double? nominal,
    KategoriTransaksi? kategori,
    DateTime? tanggal,
    String? keterangan,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      nominal: nominal ?? this.nominal,
      kategori: kategori ?? this.kategori,
      tanggal: tanggal ?? this.tanggal,
      keterangan: keterangan ?? this.keterangan,
    );
  }

  @override
  String toString() {
    return 'TransactionModel('
        'id: $id, '
        'nominal: $nominal, '
        'kategori: ${kategori.label}, '
        'tanggal: $tanggal'
        ')';
  }
}