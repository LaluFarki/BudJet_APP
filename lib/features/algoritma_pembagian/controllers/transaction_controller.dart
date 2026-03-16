import '../models/transaction_model.dart';
import '../services/spending_tracker_service.dart';

/// Controller yang mengelola daftar transaksi pengeluaran.
///
/// Bertanggung jawab untuk:
/// - Menambah dan menghapus transaksi
/// - Menyediakan ringkasan pengeluaran (harian, bulanan)
/// - Memberi notifikasi ke [BudgetController] jika ada perubahan
///
/// Contoh penggunaan:
/// ```dart
/// final controller = TransactionController(
///   onTransaksiChanged: (daftar) => budgetController.perbaruiTransaksi(daftar),
/// );
///
/// controller.tambahTransaksi(TransactionModel(
///   id: 'txn_001',
///   nominal: 25000,
///   kategori: KategoriTransaksi.makananMinuman,
///   tanggal: DateTime.now(),
///   keterangan: 'Makan siang',
/// ));
/// ```
class TransactionController {
  final SpendingTrackerService _trackerService;

  /// Callback yang dipanggil setiap kali daftar transaksi berubah.
  /// Gunakan ini untuk memberi tahu [BudgetController] agar hitung ulang.
  final void Function(List<TransactionModel> transaksiTerbaru)? onTransaksiChanged;

  TransactionController({
    SpendingTrackerService? trackerService,
    this.onTransaksiChanged,
  }) : _trackerService = trackerService ?? const SpendingTrackerService();

  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────

  final List<TransactionModel> _transaksi = [];

  /// Daftar semua transaksi (read-only).
  List<TransactionModel> get semuaTransaksi => List.unmodifiable(_transaksi);

  // ─────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────

  /// Menambahkan transaksi baru ke daftar.
  ///
  /// Otomatis memanggil [onTransaksiChanged] setelah ditambahkan.
  void tambahTransaksi(TransactionModel transaksi) {
    _transaksi.add(transaksi);
    _notifikasiPerubahan();
  }

  /// Menghapus transaksi berdasarkan ID.
  ///
  /// Tidak melakukan apa-apa jika ID tidak ditemukan.
  void hapusTransaksi(String id) {
    _transaksi.removeWhere((t) => t.id == id);
    _notifikasiPerubahan();
  }

  /// Mengganti semua transaksi sekaligus (misal: saat load dari database).
  void muatTransaksi(List<TransactionModel> transaksi) {
    _transaksi
      ..clear()
      ..addAll(transaksi);
    _notifikasiPerubahan();
  }

  // ─────────────────────────────────────────
  // GETTER RINGKASAN
  // ─────────────────────────────────────────

  /// Ringkasan pengeluaran bulan ini.
  RingkasanPengeluaran ringkasanBulanan(DateTime bulan) {
    return _trackerService.ringkasanBulanan(
      transaksi: _transaksi,
      bulan: bulan,
    );
  }

  /// Ringkasan pengeluaran hari ini.
  RingkasanPengeluaran ringkasanHariIni() {
    return _trackerService.ringkasanHarian(transaksi: _transaksi);
  }

  /// Pengeluaran per hari dalam satu bulan (untuk grafik tren).
  Map<int, double> pengeluaranPerHari(DateTime bulan) {
    return _trackerService.pengeluaranPerHari(
      transaksi: _transaksi,
      bulan: bulan,
    );
  }

  /// N transaksi terbaru.
  List<TransactionModel> transaksiTerbaru({int limit = 5}) {
    return _trackerService.transaksiTerbaru(
      transaksi: _transaksi,
      limit: limit,
    );
  }

  // ─────────────────────────────────────────
  // PRIVATE
  // ─────────────────────────────────────────

  void _notifikasiPerubahan() {
    onTransaksiChanged?.call(List.unmodifiable(_transaksi));
  }
}