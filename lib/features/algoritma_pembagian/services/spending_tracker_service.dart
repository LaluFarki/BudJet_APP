import '../models/transaction_model.dart';

/// Hasil ringkasan pengeluaran untuk satu periode (hari/minggu/bulan).
class RingkasanPengeluaran {
  final double total;
  final int jumlahTransaksi;
  final TransactionModel? transaksiTerbesar;

  const RingkasanPengeluaran({
    required this.total,
    required this.jumlahTransaksi,
    this.transaksiTerbesar,
  });

  @override
  String toString() => 'RingkasanPengeluaran('
      'total: $total, '
      'jumlahTransaksi: $jumlahTransaksi'
      ')';
}

/// Service untuk melacak dan merangkum data pengeluaran.
///
/// Fokus pada **pengambilan informasi** dari daftar transaksi —
/// tidak menyimpan state dan tidak memodifikasi data.
///
/// Cara pakai:
/// ```dart
/// final service = SpendingTrackerService();
/// final ringkasan = service.ringkasanBulanan(
///   transaksi: semuaTransaksi,
///   bulan: DateTime.now(),
/// );
/// print('Total bulan ini: ${ringkasan.total}');
/// ```
class SpendingTrackerService {
  const SpendingTrackerService();

  // ─────────────────────────────────────────
  // RINGKASAN PENGELUARAN
  // ─────────────────────────────────────────

  /// Merangkum semua pengeluaran dalam satu bulan.
  RingkasanPengeluaran ringkasanBulanan({
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    final filtered = _filterBulan(transaksi, bulan);
    return _buatRingkasan(filtered);
  }

  /// Merangkum semua pengeluaran dalam satu hari tertentu.
  RingkasanPengeluaran ringkasanHarian({
    required List<TransactionModel> transaksi,
    DateTime? tanggal, // default: hari ini
  }) {
    final target = tanggal ?? DateTime.now();
    final filtered = _filterHari(transaksi, target);
    return _buatRingkasan(filtered);
  }

  // ─────────────────────────────────────────
  // PENGELUARAN PER HARI (untuk grafik tren)
  // ─────────────────────────────────────────

  /// Mengelompokkan pengeluaran per hari dalam satu bulan.
  ///
  /// Mengembalikan Map dengan key = tanggal (1-31),
  /// value = total pengeluaran di hari tersebut.
  ///
  /// Hari yang tidak ada transaksinya tidak masuk ke Map.
  ///
  /// Contoh output: {1: 50000.0, 3: 120000.0, 5: 75000.0}
  Map<int, double> pengeluaranPerHari({
    required List<TransactionModel> transaksi,
    required DateTime bulan,
  }) {
    final filtered = _filterBulan(transaksi, bulan);
    final Map<int, double> hasil = {};

    for (final t in filtered) {
      final hari = t.tanggal.day;
      hasil[hari] = (hasil[hari] ?? 0) + t.nominal;
    }

    return hasil;
  }

  // ─────────────────────────────────────────
  // TRANSAKSI TERBARU
  // ─────────────────────────────────────────

  /// Mengambil N transaksi terbaru (urut dari paling baru).
  ///
  /// [limit] : jumlah maksimal transaksi yang dikembalikan (default: 5)
  List<TransactionModel> transaksiTerbaru({
    required List<TransactionModel> transaksi,
    int limit = 5,
  }) {
    final sorted = List<TransactionModel>.from(transaksi)
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return sorted.take(limit).toList();
  }

  // ─────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────

  List<TransactionModel> _filterBulan(
    List<TransactionModel> transaksi,
    DateTime bulan,
  ) {
    return transaksi
        .where((t) => t.tanggal.year == bulan.year && t.tanggal.month == bulan.month)
        .toList();
  }

  List<TransactionModel> _filterHari(
    List<TransactionModel> transaksi,
    DateTime hari,
  ) {
    return transaksi
        .where((t) =>
            t.tanggal.year == hari.year &&
            t.tanggal.month == hari.month &&
            t.tanggal.day == hari.day)
        .toList();
  }

  RingkasanPengeluaran _buatRingkasan(List<TransactionModel> transaksi) {
    if (transaksi.isEmpty) {
      return const RingkasanPengeluaran(total: 0, jumlahTransaksi: 0);
    }

    final total = transaksi.fold(0.0, (sum, t) => sum + t.nominal);
    final terbesar = transaksi.reduce(
      (a, b) => a.nominal >= b.nominal ? a : b,
    );

    return RingkasanPengeluaran(
      total: total,
      jumlahTransaksi: transaksi.length,
      transaksiTerbesar: terbesar,
    );
  }
}
