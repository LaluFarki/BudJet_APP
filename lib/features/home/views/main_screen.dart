import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/views/profile_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ProfileScreen(),
  ];

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // ========================================================
      // TAMPILAN TAMBAH TRANSAKSI DI TENGAH (MENGAMBANG)
      // ========================================================
      floatingActionButton: FloatingActionButton(
        elevation: 2,
        backgroundColor: const Color(0xFFDCE775), // Lime green
        shape: const CircleBorder(), // Pastikan bulat penuh
        onPressed: () => Get.toNamed('/add-tx'),
        child: const Icon(Icons.add, color: AppColors.textDark, size: 28),
      ),
      // Menyambungkan tombol ke lengkungan bar bawah
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ========================================================
      // NAVIGASI BAWAH BIASA DENGAN LENGKUNGAN (NOTCH)
      // ========================================================
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(), // Membuat cekungan untuk tombol melayang
        notchMargin: 8.0, // Jarak tombol dengan lengkungan putih
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // --- TOMBOL BERANDA ---
              IconButton(
                iconSize: 32,
                icon: Icon(
                  Icons.home_rounded,
                  color: _currentIndex == 0 ? AppColors.textDark : AppColors.textGrey,
                ),
                onPressed: () => _onNavTapped(0),
              ),
              
              // Memberikan ruang kosong (SizedBox) persis di tengah tab 
              // agar icon Profil tidak menempel ke tengah
              const SizedBox(width: 48),

              // --- TOMBOL PROFIL ---
              IconButton(
                iconSize: 32,
                icon: Icon(
                  Icons.person_rounded,
                  color: _currentIndex == 1 ? AppColors.textDark : AppColors.textGrey,
                ),
                onPressed: () => _onNavTapped(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
