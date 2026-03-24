// ======================================================================
// FILE : riwayat_transaksi_screen.dart
// FOLDER : lib/features/riwayat_transaksi/views/
// FUNGSI : Menampilkan riwayat transaksi pengguna.
//
// Halaman ini berisi:
// - AppBar dengan tombol kembali
// - Search bar + filter & kalender icon
// - Kartu "Pengeluaran Hari Ini" dan "Total Pengeluaran"
// - Daftar transaksi dikelompokkan per tanggal
//
// Konsep Flutter yang digunakan:
// - StatelessWidget
// - Scaffold, SafeArea, SingleChildScrollView
// - Container Styling (borderRadius, boxShadow)
// - Row, Column, ListView
//
// ======================================================================

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_bottom_nav.dart';

// ======================================================================
// MODEL DATA TRANSAKSI (Dummy / Sementara)
// ======================================================================
//
// Class ini merepresentasikan satu item transaksi.
// Ke depannya, data ini akan diambil dari controller GetX
// atau database lokal (misalnya SQLite / Hive).
//
class TransaksiItem {
  final String nama;
  final String kategori;
  final String metodePembayaran;
  final String nominal;
  final Color warnaCategoryIcon;
  final IconData iconKategori;

  const TransaksiItem({
    required this.nama,
    required this.kategori,
    required this.metodePembayaran,
    required this.nominal,
    required this.warnaCategoryIcon,
    required this.iconKategori,
  });
}

// ======================================================================
// DATA DUMMY TRANSAKSI
// ======================================================================
//
// Data ini digunakan sebagai placeholder sebelum terhubung ke database.
// Nanti data ini diganti dengan data dari GetX Controller.
//
final List<TransaksiItem> _transaksiHariIni = [
  const TransaksiItem(
    nama: 'Gojek',
    kategori: 'Transportasi',
    metodePembayaran: 'Dompet Digital',
    nominal: '-Rp 24.000',
    warnaCategoryIcon: Color(0xFF4CAF50),
    iconKategori: Icons.motorcycle,
  ),
  const TransaksiItem(
    nama: 'Makan Siang',
    kategori: 'Makanan',
    metodePembayaran: 'Tunai',
    nominal: '-Rp 15.000',
    warnaCategoryIcon: Color(0xFFFF9800),
    iconKategori: Icons.restaurant,
  ),
  const TransaksiItem(
    nama: 'Kopi Kenangan',
    kategori: 'Makanan',
    metodePembayaran: 'Dompet Digital',
    nominal: '-Rp 22.000',
    warnaCategoryIcon: Color(0xFFFF9800),
    iconKategori: Icons.local_cafe,
  ),
];

final List<TransaksiItem> _transaksiKemarin = [
  const TransaksiItem(
    nama: 'Grab',
    kategori: 'Transportasi',
    metodePembayaran: 'Tunai',
    nominal: '-Rp 18.000',
    warnaCategoryIcon: Color(0xFF2196F3),
    iconKategori: Icons.directions_car,
  ),
  const TransaksiItem(
    nama: 'Indomaret',
    kategori: 'Belanja',
    metodePembayaran: 'Tunai',
    nominal: '-Rp 45.000',
    warnaCategoryIcon: Color(0xFF9C27B0),
    iconKategori: Icons.shopping_bag,
  ),
];

// ======================================================================
// CLASS RIWAYAT TRANSAKSI SCREEN
// ======================================================================

class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  // State untuk melacak apakah mode edit sedang aktif
  bool _isEditMode = false;

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================================================================
      // BACKGROUND COLOR
      // ================================================================
      backgroundColor: AppColors.backgroundLight,

      // ================================================================
      // APP BAR
      // ================================================================
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,

        // Tombol kembali
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        // Judul halaman
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        centerTitle: true,
      ),

      // ================================================================
      // BODY
      // ================================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================================
              // 1. SEARCH BAR + FILTER + KALENDER
              // ========================================================
              _buildSearchBar(),

              const SizedBox(height: 20),

              // ========================================================
              // 2. KARTU SALDO SAYA
              // ========================================================
              _buildBalanceCard(),

              const SizedBox(height: 24),

              // ========================================================
              // 3. LABEL HARI INI + TOMBOL EDIT
              // ========================================================
              _buildSectionHeader('Hari Ini', showEdit: true),

              const SizedBox(height: 10),

              // ========================================================
              // 4. LIST TRANSAKSI HARI INI
              // ========================================================
              ..._transaksiHariIni.map((t) => _buildTransactionTile(t)),

              const SizedBox(height: 20),

              // ========================================================
              // 5. LABEL KEMARIN
              // ========================================================
              _buildSectionHeader('Kemarin', showEdit: false),

              const SizedBox(height: 10),

              // ========================================================
              // 6. LIST TRANSAKSI KEMARIN
              // ========================================================
              ..._transaksiKemarin.map((t) => _buildTransactionTile(t)),

              const SizedBox(height: 20),

              // ========================================================
              // 7. LABEL TANGGAL LAMA
              // ========================================================
              _buildSectionHeader('12 Oktober 2025', showEdit: false),

              const SizedBox(height: 10),

              _buildTransactionTile(
                const TransaksiItem(
                  nama: 'Warung Padang',
                  kategori: 'Makanan',
                  metodePembayaran: 'Tunai',
                  nominal: '-Rp 14.000',
                  warnaCategoryIcon: Color(0xFFFF9800),
                  iconKategori: Icons.restaurant,
                ),
              ),
            ],
          ),
        ),
      ),
      // ================================================================
      // BOTTOM NAVIGATION BAR
      // ================================================================
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0, // Set to 0 (Home) as placeholder
        onTap: (index) {
          // Navigasikan kembali ke MainScreen dengan tab yang bersangkutan
          if (index != 0) {
            // Karena tidak ada sistem state manajemen global yang terlihat mengatur index MainScreen dari luar saat ini,
            // kita bisa kembalikan ke Home saja via pop, namun lebih ideal jika di masa depan di handle lewat GetX.
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  // ====================================================================
  // WIDGET: SEARCH BAR
  // ====================================================================
  //
  // Search bar berbentuk pill dengan icon filter dan kalender
  // di sebelah kanan.
  //
  Widget _buildSearchBar() {
    return Row(
      children: [
        // Input pencarian (Expanded agar mengambil sisa ruang)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: AppColors.textGrey, size: 20),
                hintText: 'Cari transaksi...',
                hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Tombol Filter
        _buildIconButton(Icons.tune),

        const SizedBox(width: 8),

        // Tombol Calendar
        _buildIconButton(Icons.calendar_month_outlined),
      ],
    );
  }

  // ====================================================================
  // WIDGET: ICON BUTTON (Filter & Calendar)
  // ====================================================================
  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.textDark, size: 20),
    );
  }

  // ====================================================================
  // WIDGET: KARTU SALDO SAYA
  // ====================================================================
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen, // Lime Green background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Saya',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rp425.000',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // WIDGET: SECTION HEADER (Label Tanggal + Edit Button)
  // ====================================================================
  Widget _buildSectionHeader(String title, {required bool showEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        if (showEdit)
          GestureDetector(
            onTap: _toggleEditMode,
            child: _isEditMode
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  // ====================================================================
  // WIDGET: SATU ITEM TRANSAKSI
  // ====================================================================
  //
  // Tile transaksi dengan:
  // - Icon kategori (CircleAvatar berwarna)
  // - Nama + sub-kategori + metode bayar
  // - Nominal di sebelah kanan
  //
  Widget _buildTransactionTile(TransaksiItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // --------------------------------------------------------------
          // KONTEN TRANSAKSI (Expanded agar mengambil ruang sisa)
          // --------------------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon Kategori
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: item.warnaCategoryIcon.withValues(
                      alpha: 0.15,
                    ),
                    child: Icon(
                      item.iconKategori,
                      color: item.warnaCategoryIcon,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Nama + Kategori + Metode Bayar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.kategori} • ${item.metodePembayaran}',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nominal (Hanya tampil jika BUKAN mode edit, atau bisa tetap tampil tergantung preferensi,
                  // tapi di desain UI, saat Edit, nominalnya hilang terganti oleh tombol. Mari kita hilangkan nominal saat Edit.)
                  if (!_isEditMode)
                    Text(
                      item.nominal,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --------------------------------------------------------------
          // TOMBOL EDIT & DELETE (Hanya tampil jika Mode Edit aktif)
          // --------------------------------------------------------------
          if (_isEditMode)
            Row(
              children: [
                // Tombol Edit (Lime Green)
                GestureDetector(
                  onTap: () {
                    // TODO: Implementasi logika edit
                  },
                  child: Container(
                    width: 50,
                    height: 72, // Menyesuaikan tinggi agar sejajar dengan tile
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textDark,
                      size: 24,
                    ),
                  ),
                ),
                // Tombol Delete (Merah / Pink)
                GestureDetector(
                  onTap: () {
                    _showDeleteConfirmation(context, item);
                  },
                  child: Container(
                    width: 50,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF697A),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ====================================================================
  // WIDGET: MODAL KONFIRMASI HAPUS TRANSAKSI
  // ====================================================================
  void _showDeleteConfirmation(BuildContext context, TransaksiItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikon Warning Merah
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF697A).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF697A), // Warna merah pink
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4DFF697A),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Teks Judul
                const Text(
                  'Yakin Menghapus?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                // Teks Deskripsi
                const Text(
                  'Jika anda melanjutkan, riwayat transaksi akan terhapus',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Tombol Batal & Lanjut
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF697A), // Merah
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext); // Tutup dialog
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Lanjut
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280), // Abu-abu
                          side: const BorderSide(
                            color: Color(0xFFD1D5DB), // Garis abu-abu
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext); // Tutup dialog pertama
                          // (Logika menghapus item di backend / list state ditambahkan di sini)
                          _showSuccessDeleted(context, item);
                        },
                        child: const Text(
                          'Lanjut',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================================================================
  // WIDGET: MODAL SUKSES HAPUS TRANSAKSI
  // ====================================================================
  void _showSuccessDeleted(BuildContext context, TransaksiItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikon Centang Hijau (Lime Green)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.textDark,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Teks Judul
                const Text(
                  'Transaksi Dihapus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                // Teks Deskripsi
                Text(
                  'Transaksi ${item.nama} telah berhasil dihapus dari riwayat transaksi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Tombol Kembali
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen, // Lime Green
                      foregroundColor: AppColors.textDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext); // Tutup dialog sukses
                    },
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
