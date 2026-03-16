// ======================================================================
// FILE : expense_summary.dart
// FOLDER : lib/features/home/widgets/
// FUNGSI : Widget untuk menampilkan ringkasan pengeluaran
//          dalam bentuk dua kartu informasi.
//
// Widget ini biasanya ditampilkan di halaman HomeScreen
// untuk memberikan ringkasan cepat kepada pengguna.
//
// Isi widget:
// 1. Pengeluaran Hari Ini
// 2. Total Pengeluaran
//
// Konsep yang digunakan:
// - StatelessWidget
// - Row Layout
// - Expanded Widget
// - Container Styling
// - BoxDecoration
// - BoxShadow
// - Column Layout
//
// Widget ini bersifat reusable (bisa digunakan ulang).
// ======================================================================

// Mengimpor package utama Flutter untuk UI
// Berisi widget seperti Row, Column, Container, Text, dll.
import 'package:flutter/material.dart';

// Mengimpor file warna global aplikasi
// Lokasi file:
//
// lib/core/constants/app_colors.dart
//
// File ini berisi kumpulan warna yang digunakan secara
// konsisten di seluruh aplikasi.
//
// Contoh warna yang digunakan di sini:
// - AppColors.cardWhite
// - AppColors.textDark
// - AppColors.primaryGreen
//
import '../../../../core/constants/app_colors.dart';

// ======================================================================
// CLASS EXPENSE SUMMARY
// ======================================================================
//
// ExpenseSummary adalah widget yang menampilkan
// ringkasan data pengeluaran.
//
// Widget ini menggunakan StatelessWidget karena:
//
// - Tidak memiliki state yang berubah
// - Hanya menampilkan data statis
//
// Jika nanti ingin menampilkan data dari database
// atau API, widget ini tetap bisa dipakai dan
// hanya mengganti nilai teksnya.
//
// ======================================================================

class ExpenseSummary extends StatelessWidget {
  // Constructor standar Flutter
  const ExpenseSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ==================================================================
    // ROW LAYOUT
    // ==================================================================
    //
    // Row digunakan karena kita ingin menampilkan
    // dua kotak secara horizontal (kiri dan kanan).
    //
    // Layout:
    //
    // [ Pengeluaran Hari Ini ]   [ Total Pengeluaran ]
    //
    return Row(
      children: [
        // ===============================================================
        // EXPANDED PERTAMA
        // ===============================================================
        //
        // Expanded digunakan agar widget mengambil
        // ruang kosong yang tersedia secara proporsional.
        //
        // Karena ada dua Expanded di Row,
        // maka keduanya akan memiliki lebar yang sama.
        //
        Expanded(
          child: Container(
            // Padding memberi jarak antara isi container
            // dengan batas container
            padding: const EdgeInsets.all(15),

            // ===========================================================
            // BOX DECORATION
            // ===========================================================
            //
            // Digunakan untuk styling container
            //
            decoration: BoxDecoration(
              // Warna background putih
              color: AppColors.cardWhite,

              // Membuat sudut container melengkung
              borderRadius: BorderRadius.circular(15),

              // Menambahkan bayangan agar terlihat seperti kartu
              boxShadow: [
                BoxShadow(
                  // Warna bayangan abu dengan opacity kecil
                  color: Colors.grey.withOpacity(0.1),

                  // Tingkat blur bayangan
                  blurRadius: 10,

                  // Posisi bayangan (ke bawah)
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            // ===========================================================
            // COLUMN UNTUK MENYUSUN TEKS
            // ===========================================================
            //
            // Column digunakan untuk menyusun widget
            // secara vertikal (atas ke bawah).
            //
            child: Column(
              // Meratakan isi ke kiri
              crossAxisAlignment: CrossAxisAlignment.start,

              children: const [
                // ======================================================
                // TEKS JUDUL
                // ======================================================
                //
                // Menampilkan label informasi
                //
                Text(
                  'Pengeluaran Hari Ini',

                  style: TextStyle(
                    // Warna teks
                    color: AppColors.textDark,

                    // Ukuran teks
                    fontSize: 12,

                    // Ketebalan teks
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ======================================================
                // SPACING
                // ======================================================
                //
                // Memberikan jarak vertikal
                //
                SizedBox(height: 10),

                // ======================================================
                // NILAI PENGELUARAN
                // ======================================================
                //
                // Menampilkan jumlah pengeluaran hari ini
                //
                Text(
                  'Rp14.500',

                  style: TextStyle(
                    color: AppColors.textDark,

                    // Ukuran lebih besar karena ini data utama
                    fontSize: 22,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ===============================================================
        // SPACING ANTAR KARTU
        // ===============================================================
        //
        // SizedBox digunakan untuk memberi jarak
        // horizontal antara dua container.
        //
        const SizedBox(width: 15),

        // ===============================================================
        // EXPANDED KEDUA
        // ===============================================================
        //
        // Kotak untuk menampilkan total pengeluaran
        //
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),

            decoration: BoxDecoration(
              // Menggunakan warna primaryGreen
              // tapi diberi transparansi agar lebih soft
              
              color: AppColors.cardRed.withOpacity(0.8),

              borderRadius: BorderRadius.circular(15),
            ),

            // ===========================================================
            // COLUMN UNTUK TEKS
            // ===========================================================
            //
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: const [
                // Judul informasi
                Text(
                  'Total Pengeluaran',

                  style: TextStyle(
                    color: AppColors.textDark,

                    fontSize: 12,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10),

                // Total pengeluaran keseluruhan
                Text(
                  'Rp737.500',

                  style: TextStyle(
                    color: AppColors.textDark,

                    fontSize: 22,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
