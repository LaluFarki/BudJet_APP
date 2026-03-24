import 'package:intl/intl.dart';

/// Helper untuk memformat [DateTime] menjadi String yang siap ditampilkan di UI.
///
/// Cara pakai di widget mana saja:
/// ```dart
/// import 'package:flutter_application_1/features/algoritma_pembagian/utils/date_formatter.dart';
///
/// Text(DateFormatter.jamMenit(transaksi.tanggal))      // → 14:32
/// Text(DateFormatter.tanggalPendek(transaksi.tanggal)) // → 16 Mar 2026
/// Text(DateFormatter.lengkap(transaksi.tanggal))       // → 16 Mar 2026, 14:32
/// ```
class DateFormatter {

  // ─────────────────────────────────────────
  // FORMAT JAM
  // ─────────────────────────────────────────

  /// Menampilkan jam dan menit saja.
  /// Contoh: 14:32
  static String jamMenit(DateTime tanggal) {
    return DateFormat('HH:mm').format(tanggal);
  }

  /// Menampilkan jam, menit, dan detik.
  /// Contoh: 14:32:05
  static String jamMenitDetik(DateTime tanggal) {
    return DateFormat('HH:mm:ss').format(tanggal);
  }

  // ─────────────────────────────────────────
  // FORMAT TANGGAL
  // ─────────────────────────────────────────

  /// Menampilkan tanggal pendek.
  /// Contoh: 16 Mar 2026
  static String tanggalPendek(DateTime tanggal) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal);
  }

  /// Menampilkan tanggal panjang.
  /// Contoh: Senin, 16 Maret 2026
  static String tanggalPanjang(DateTime tanggal) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal);
  }

  /// Menampilkan bulan dan tahun saja.
  /// Contoh: Maret 2026
  static String bulanTahun(DateTime tanggal) {
    return DateFormat('MMMM yyyy', 'id_ID').format(tanggal);
  }

  // ─────────────────────────────────────────
  // FORMAT LENGKAP (tanggal + jam)
  // ─────────────────────────────────────────

  /// Menampilkan tanggal dan jam lengkap.
  /// Contoh: 16 Mar 2026, 14:32
  static String lengkap(DateTime tanggal) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tanggal);
  }

  /// Menampilkan tanggal dan jam — versi pendek untuk list transaksi.
  /// Contoh: 16/03 • 14:32
  static String pendekDenganJam(DateTime tanggal) {
    return DateFormat('dd/MM • HH:mm').format(tanggal);
  }

  // ─────────────────────────────────────────
  // FORMAT RELATIF (untuk UX yang lebih friendly)
  // ─────────────────────────────────────────

  /// Menampilkan waktu relatif — lebih ramah dibaca user.
  ///
  /// Contoh output:
  /// - Baru saja         (< 1 menit yang lalu)
  /// - 5 menit yang lalu
  /// - 2 jam yang lalu
  /// - Hari ini, 14:32   (lebih dari 1 hari tapi masih hari ini)
  /// - Kemarin, 09:15
  /// - 16 Mar 2026       (lebih dari 2 hari)
  static String relatif(DateTime tanggal) {
    final sekarang = DateTime.now();
    final selisih = sekarang.difference(tanggal);

    if (selisih.inSeconds < 60) {
      return 'Baru saja';
    } else if (selisih.inMinutes < 60) {
      return '${selisih.inMinutes} menit yang lalu';
    } else if (selisih.inHours < 24 && _hariYangSama(tanggal, sekarang)) {
      return 'Hari ini, ${jamMenit(tanggal)}';
    } else if (_hariYangSama(
        tanggal, sekarang.subtract(const Duration(days: 1)))) {
      return 'Kemarin, ${jamMenit(tanggal)}';
    } else {
      return tanggalPendek(tanggal);
    }
  }

  // ─────────────────────────────────────────
  // PRIVATE HELPER
  // ─────────────────────────────────────────

  static bool _hariYangSama(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
