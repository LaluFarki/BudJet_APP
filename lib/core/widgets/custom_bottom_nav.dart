import 'package:flutter/material.dart';
// Ini adalah alat baru yang barusan kita pasang
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../constants/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      // Memberitahu package ini halaman mana yang sedang aktif
      index: currentIndex,

      // Kecepatan dan gaya animasi gelombangnya
      animationDuration: const Duration(milliseconds: 400),
      animationCurve: Curves.easeInOut,

      // PENGATURAN WARNA SESUAI DESAINMU:
      // Warna background putih kotak bawahnya
      color: AppColors.cardWhite,

      // Warna lingkaran yang melayang ke atas (menggunakan hijau khas-mu)
      buttonBackgroundColor: AppColors.primaryGreen,

      // SANGAT PENTING: Warna di belakang gelombang harus sama dengan warna background layar
      // agar terlihat seperti "berlubang" transparan
      backgroundColor: AppColors.backgroundLight,

      // Tinggi dari navigasi bawahnya
      height: 65.0,

      // Fungsi saat ditekan
      onTap: onTap,

      // Daftar kepingan ikonnya
      items: [
        // Index 0: Ikon Home
        Icon(
          Icons.home_rounded,
          size: 30,
          // Warnanya gelap jika aktif, abu-abu jika tidak
          color: currentIndex == 0 ? AppColors.textDark : AppColors.textGrey,
        ),

        // Index 1: Ikon Tambah Transaksi
        Icon(
          Icons.add_rounded,
          size: 30,
          color: currentIndex == 1 ? AppColors.textDark : AppColors.textGrey,
        ),

        // Index 2: Ikon Profil
        Icon(
          Icons.person_rounded,
          size: 30,
          color: currentIndex == 2 ? AppColors.textDark : AppColors.textGrey,
        ),
      ],
    );
  }
}
