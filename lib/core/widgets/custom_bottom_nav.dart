// ======================================================================
// FILE : custom_bottom_nav.dart
// FOLDER : lib/core/widgets/
// FUNGSI : Widget untuk menampilkan Bottom Navigation Bar kustom
//          menggunakan package CurvedNavigationBar.
//
// Widget ini digunakan sebagai navigasi utama aplikasi
// agar pengguna dapat berpindah antar halaman utama.
//
// Navigasi yang tersedia:
// 1. Home
// 2. Tambah Transaksi
// 3. Profil
//
// Package yang digunakan:
// - curved_navigation_bar
//
// Package ini membuat efek navigasi bawah dengan bentuk
// melengkung (curved) dan animasi gelombang.
//
// Konsep Flutter yang digunakan:
// - StatelessWidget
// - Constructor Parameter
// - Callback Function
// - Custom Styling
// - External Package
// - Conditional Styling
//
// Widget ini bersifat reusable dan dapat digunakan di
// berbagai halaman yang membutuhkan Bottom Navigation.
//
// ======================================================================

// Mengimpor package utama Flutter
// Berisi widget dasar seperti Scaffold, Icon, Container, dll.
import 'package:flutter/material.dart';

// Mengimpor package CurvedNavigationBar
// Package ini digunakan untuk membuat Bottom Navigation
// dengan efek melengkung dan animasi gelombang.
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// Mengimpor warna global aplikasi
// File ini berisi kumpulan warna yang digunakan secara konsisten
// di seluruh aplikasi.
//
// Contoh warna yang dipakai di widget ini:
// - AppColors.primaryGreen
// - AppColors.backgroundLight
// - AppColors.textDark
// - AppColors.textGrey
// - AppColors.cardWhite
//
import '../constants/app_colors.dart';

// ======================================================================
// CLASS CUSTOM BOTTOM NAV
// ======================================================================
//
// CustomBottomNav adalah widget navigasi bawah
// yang digunakan untuk berpindah halaman.
//
// Widget ini menggunakan StatelessWidget karena
// tidak menyimpan state internal.
//
// Perubahan halaman dikontrol oleh widget parent
// melalui parameter:
//
// - currentIndex → halaman yang sedang aktif
// - onTap → fungsi yang dijalankan saat ikon ditekan
//
// ======================================================================

class CustomBottomNav extends StatelessWidget {
  // ====================================================================
  // CURRENT INDEX
  // ====================================================================
  //
  // Menyimpan index halaman yang sedang aktif.
  //
  // Contoh:
  //
  // 0 = Home
  // 1 = Add Transaction
  // 2 = Profile
  //
  final int currentIndex;

  // ====================================================================
  // ON TAP CALLBACK
  // ====================================================================
  //
  // Function ini akan dipanggil saat pengguna
  // menekan salah satu ikon navigasi.
  //
  // Function ini biasanya digunakan untuk
  // mengganti halaman dengan setState()
  //
  final Function(int) onTap;

  // ====================================================================
  // CONSTRUCTOR
  // ====================================================================
  //
  // Constructor menerima dua parameter wajib:
  //
  // - currentIndex
  // - onTap
  //
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // ====================================================================
  // BUILD METHOD
  // ====================================================================
  //
  // Method ini digunakan untuk membangun tampilan UI
  //
  @override
  Widget build(BuildContext context) {
    // ================================================================
    // CURVED NAVIGATION BAR
    // ================================================================
    //
    // Widget dari package curved_navigation_bar
    //
    // Membuat navigasi bawah dengan efek:
    //
    // - bentuk melengkung
    // - animasi gelombang
    // - tombol yang naik ke atas saat aktif
    //
    return CurvedNavigationBar(
      // ==============================================================
      // INDEX
      // ==============================================================
      //
      // Memberitahu navigasi item mana yang sedang aktif
      //
      index: currentIndex,

      // ==============================================================
      // ANIMATION SETTINGS
      // ==============================================================
      //
      // Mengatur kecepatan animasi saat berpindah menu
      //
      animationDuration: const Duration(milliseconds: 400),

      // Mengatur gaya animasi
      animationCurve: Curves.easeInOut,

      // ==============================================================
      // WARNA NAVIGASI
      // ==============================================================

      // Warna background navigasi bawah
      color: AppColors.cardWhite,

      // Warna tombol yang naik ke atas saat aktif
      buttonBackgroundColor: AppColors.primaryGreen,

      // Warna background di belakang gelombang
      // Biasanya harus sama dengan background halaman
      // agar terlihat menyatu
      backgroundColor: AppColors.backgroundLight,

      // ==============================================================
      // HEIGHT
      // ==============================================================
      //
      // Tinggi navigasi bawah
      //
      height: 65.0,

      // ==============================================================
      // ON TAP EVENT
      // ==============================================================
      //
      // Function yang dipanggil saat ikon ditekan
      //
      onTap: onTap,

      // ==============================================================
      // ITEMS NAVIGASI
      // ==============================================================
      //
      // Daftar ikon navigasi yang akan ditampilkan
      //
      items: [
        // ============================================================
        // INDEX 0 : HOME
        // ============================================================
        //
        // Ikon untuk halaman Home
        //
        Icon(
          Icons.home_rounded,
          size: 30,

          // Warna ikon berubah berdasarkan halaman aktif
          //
          // Jika aktif → warna gelap
          // Jika tidak → warna abu
          //
          color: currentIndex == 0 ? AppColors.textDark : AppColors.textGrey,
        ),

        // ============================================================
        // INDEX 1 : TAMBAH TRANSAKSI
        // ============================================================
        //
        // Ikon untuk menambahkan transaksi baru
        //
        Icon(
          Icons.add_rounded,
          size: 30,
          color: currentIndex == 1 ? AppColors.textDark : AppColors.textGrey,
        ),

        // ============================================================
        // INDEX 2 : PROFIL
        // ============================================================
        //
        // Ikon untuk halaman profil pengguna
        //
        Icon(
          Icons.person_rounded,
          size: 30,
          color: currentIndex == 2 ? AppColors.textDark : AppColors.textGrey,
        ),
      ],
    );
  }
}
