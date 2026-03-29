// ======================================================================
// FILE : history_screen.dart
// FOLDER : lib/features/history/views/
// FUNGSI : Menampilkan halaman riwayat transaksi pengguna.
//
// Halaman ini berisi:
// - AppBar dengan tombol kembali
// - Tombol download riwayat transaksi
// - Kotak pencarian transaksi
// - Daftar transaksi
//
// Konsep Flutter yang digunakan:
// - StatelessWidget
// - Scaffold Layout
// - AppBar
// - Navigator.pop()
// - ListView
// - Container Styling
// - Row & Column Layout
//
// Halaman ini biasanya dipanggil dari HomeScreen
// ketika user ingin melihat semua transaksi.
//
// ======================================================================

// Mengimpor package utama Flutter Material Design
// Berisi widget seperti Scaffold, AppBar, TextField,
// Container, Row, Column, ListView, dll.
import 'package:flutter/material.dart';

// Mengimpor file warna global aplikasi
//
// Lokasi file:
// lib/core/constants/app_colors.dart
//
// File ini berisi kumpulan warna utama aplikasi
// agar tampilan UI konsisten.
//
import '../../../core/constants/app_colors.dart';

// ======================================================================
// CLASS HISTORY SCREEN
// ======================================================================
//
// HistoryScreen adalah halaman yang menampilkan
// daftar riwayat transaksi pengguna.
//
// Widget ini menggunakan StatelessWidget karena:
//
// - Tidak memiliki state internal
// - Data transaksi hanya ditampilkan
//
// Jika nanti data diambil dari database atau API,
// biasanya widget ini akan menggunakan
// State Management seperti Provider / Bloc.
//
// ======================================================================

class HistoryScreen extends StatelessWidget {
  // Constructor standar Flutter
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ==================================================================
      // BACKGROUND COLOR
      // ==================================================================
      //
      // Menggunakan warna dari AppColors
      // agar konsisten dengan halaman lain
      //
      backgroundColor: AppColors.backgroundLight,

      // ==================================================================
      // APP BAR
      // ==================================================================
      //
      // AppBar digunakan untuk header halaman
      //
      appBar: AppBar(
        // Warna AppBar dibuat sama dengan background
        // agar terlihat flat / minimal
        backgroundColor: AppColors.backgroundLight,

        // elevation = 0 agar tidak ada bayangan
        elevation: 0,

        // ================================================================
        // LEADING ICON (TOMBOL KEMBALI)
        // ================================================================
        //
        // IconButton ini digunakan untuk kembali
        // ke halaman sebelumnya.
        //
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),

          // Navigator.pop digunakan untuk
          // keluar dari halaman ini.
          //
          onPressed: () => Navigator.pop(context),
        ),

        // ================================================================
        // TITLE APPBAR
        // ================================================================
        //
        // Judul halaman
        //
        title: const Text(
          'Riwayat Transaksi',

          style: TextStyle(
            color: AppColors.textDark,

            fontWeight: FontWeight.bold,
          ),
        ),

        // ================================================================
        // ACTION BUTTON
        // ================================================================
        //
        // Ikon tambahan di sebelah kanan AppBar
        //
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.textDark),

            // Fungsi download belum diimplementasikan
            onPressed: () {},
          ),
        ],
      ),

      // ==================================================================
      // BODY HALAMAN
      // ==================================================================
      //
      // Padding digunakan untuk memberi jarak
      // antara konten dan tepi layar
      //
      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          children: [
            // ============================================================
            // SEARCH BOX
            // ============================================================
            //
            // Kotak pencarian untuk mencari transaksi
            //
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),

              decoration: BoxDecoration(
                // Warna background putih
                color: AppColors.cardWhite,

                // Membuat sudut kotak melengkung
                borderRadius: BorderRadius.circular(15),

                // Border tipis di sekeliling kotak
                border: Border.all(color: Colors.grey.shade300),
              ),

              // TextField untuk input pencarian
              child: const TextField(
                decoration: InputDecoration(
                  // Icon pencarian
                  icon: Icon(Icons.search, color: AppColors.textGrey),

                  // Placeholder teks
                  hintText: 'Cari transaksi...',

                  // Menghilangkan garis default TextField
                  border: InputBorder.none,
                ),
              ),
            ),

            // Memberi jarak vertikal
            const SizedBox(height: 20),

            // ============================================================
            // LIST TRANSAKSI
            // ============================================================
            //
            // Expanded digunakan agar ListView
            // mengambil sisa ruang yang tersedia.
            //
            Expanded(
              child: ListView(
                children: [
                  // ======================================================
                  // LABEL HARI
                  // ======================================================
                  //
                  const Text(
                    'Hari Ini',

                    style: TextStyle(
                      color: AppColors.textGrey,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ======================================================
                  // ITEM TRANSAKSI
                  // ======================================================
                  //
                  // Container ini mewakili satu transaksi
                  //
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),

                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,

                      borderRadius: BorderRadius.circular(15),
                    ),

                    // ====================================================
                    // ROW UTAMA TRANSAKSI
                    // ====================================================
                    //
                    // Menyusun informasi transaksi kiri dan kanan
                    //
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        // =================================================
                        // BAGIAN KIRI TRANSAKSI
                        // =================================================
                        //
                        Row(
                          children: [
                            // Icon transaksi
                            CircleAvatar(
                              backgroundColor: Colors.green.shade100,

                              child: const Icon(
                                Icons.motorcycle,

                                color: Colors.green,
                              ),
                            ),

                            const SizedBox(width: 15),

                            // Informasi transaksi
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: const [
                                // Nama transaksi
                                Text(
                                  'Gojek',

                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,

                                    fontSize: 16,
                                  ),
                                ),

                                // Kategori transaksi
                                Text(
                                  'Transportasi',

                                  style: TextStyle(
                                    color: AppColors.textGrey,

                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // =================================================
                        // NOMINAL TRANSAKSI
                        // =================================================
                        //
                        const Text(
                          '-Rp 24.000',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,

                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
