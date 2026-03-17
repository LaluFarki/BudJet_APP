// ===============================================================
// FILE : main_screen.dart
// FOLDER : lib/features/main/views/
// FUNGSI : Sebagai layar utama aplikasi yang menampung
//          beberapa halaman (Home, Transaction, Profile)
//          serta mengatur navigasi menggunakan Bottom Navigation.
//
// Konsep yang digunakan:
// - StatefulWidget
// - IndexedStack
// - Custom Bottom Navigation
// - Modular Folder Structure
// ===============================================================

// Mengimpor package utama Flutter Material Design
// Berisi widget seperti Scaffold, Text, Center, dll.
import 'package:flutter/material.dart';

// Mengimpor file warna global aplikasi
// Lokasi file:
// lib/core/constants/app_colors.dart
//
// File ini biasanya berisi warna-warna yang dipakai
// secara konsisten di seluruh aplikasi.
import '../../../core/constants/app_colors.dart';

// Mengimpor widget navigasi bawah custom
// Lokasi file:
// lib/core/widgets/custom_bottom_nav.dart
//
// Widget ini dibuat sendiri agar tampilan BottomNavigationBar
// bisa dikustom sesuai desain aplikasi.
import '../../../core/widgets/custom_bottom_nav.dart';

// Mengimpor layar HomeScreen
// Lokasi file:
// lib/features/home/views/home_screen.dart
//
// Layar ini merupakan halaman utama aplikasi
// yang biasanya menampilkan dashboard atau ringkasan data.
import 'home_screen.dart';

// Jika nanti fitur transaksi dibuat,
// file ini akan diimport dari:
//
// lib/features/transaction/views/add_transaction_screen.dart
//
// import '../../transaction/views/add_transaction_screen.dart';

// Jika nanti layar profil dibuat,
// maka file profile_screen.dart juga akan diimport di sini.

// ===============================================================
// CLASS MAINSCREEN
// ===============================================================
//
// MainScreen adalah widget utama setelah user login.
//
// Fungsi MainScreen:
// - Menjadi container untuk beberapa halaman
// - Mengatur navigasi antar halaman
// - Menampilkan Bottom Navigation Bar
//
// Menggunakan StatefulWidget karena:
// kita perlu menyimpan state halaman aktif.
// ===============================================================

class MainScreen extends StatefulWidget {
  // Constructor standar Flutter
  const MainScreen({super.key});

  @override
  // Menghubungkan widget dengan state class
  State<MainScreen> createState() => _MainScreenState();
}

// ===============================================================
// CLASS STATE MAINSCREEN
// ===============================================================
//
// Class ini menyimpan state dari MainScreen.
// Di sinilah logika navigasi halaman berada.
// ===============================================================

class _MainScreenState extends State<MainScreen> {
  // ===========================================================
  // VARIABLE _currentIndex
  // ===========================================================
  //
  // Variabel ini menyimpan nomor halaman yang sedang aktif.
  //
  // Contoh:
  // 0 = HomeScreen
  // 1 = AddTransactionScreen
  // 2 = ProfileScreen
  //
  // Default nilai = 0
  // Artinya saat aplikasi pertama dibuka akan menampilkan HomeScreen
  //
  int _currentIndex = 0;

  // ===========================================================
  // LIST HALAMAN APLIKASI
  // ===========================================================
  //
  // Variabel _pages berisi daftar halaman yang akan ditampilkan
  // ketika pengguna menekan tombol navigasi bawah.
  //
  // Urutan halaman harus sama dengan urutan icon
  // pada CustomBottomNav.
  //
  final List<Widget> _pages = [
    // INDEX 0
    // Halaman Home
    const HomeScreen(),

    // INDEX 1
    // Halaman Tambah Transaksi
    //
    // Saat fitur transaksi dibuat,
    // widget ini akan diaktifkan.
    //
    // const AddTransactionScreen(),

    // INDEX 2
    // Halaman Profil
    //
    // Saat ini masih menggunakan dummy widget
    // sebagai placeholder.
    //
    const Center(child: Text("Halaman Profil (Belum Dibuat)")),
  ];

  // ===========================================================
  // FUNCTION NAVIGATION TAP
  // ===========================================================
  //
  // Fungsi ini dipanggil ketika user menekan icon
  // pada Bottom Navigation Bar.
  //
  // Parameter:
  // index = nomor tombol yang ditekan
  //
  void _onNavTapped(int index) {
    // setState digunakan untuk memberi tahu Flutter
    // bahwa state berubah dan UI harus diperbarui
    setState(() {
      // Mengubah halaman aktif sesuai index
      _currentIndex = index;
    });
  }

  // ===========================================================
  // BUILD METHOD
  // ===========================================================
  //
  // Method ini digunakan untuk membangun UI halaman.
  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================
      // BACKGROUND COLOR
      // ========================================================
      //
      // Menggunakan warna dari AppColors
      // agar konsisten di seluruh aplikasi.
      //
      backgroundColor: AppColors.backgroundLight,

      // ========================================================
      // BODY
      // ========================================================
      //
      // IndexedStack digunakan untuk menampilkan halaman
      // berdasarkan index yang aktif.
      //
      // Keunggulan IndexedStack dibanding Navigator:
      //
      // - Halaman tidak di-reset saat berpindah
      // - State halaman tetap tersimpan
      //
      // Contoh:
      // jika user scroll HomeScreen lalu pindah ke Profile,
      // saat kembali ke Home scroll tetap di posisi sebelumnya.
      //
      body: IndexedStack(
        // index menentukan halaman mana yang ditampilkan
        index: _currentIndex,

        // children adalah daftar halaman
        children: _pages,
      ),

      // ========================================================
      // EXTEND BODY
      // ========================================================
      //
      // extendBody digunakan agar body bisa
      // berada di bawah navigation bar.
      //
      // Biasanya digunakan jika BottomNavigationBar
      // memiliki background transparan.
      //
      extendBody: true,

      // ========================================================
      // [PLAYGROUND] TOMBOL SEMENTARA — hapus setelah frontend jadi
      // ========================================================
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.deepPurple,
        onPressed: () => Navigator.pushNamed(context, '/playground'),
        child: const Icon(Icons.science, color: Colors.white),
      ),

      // ========================================================
      // BOTTOM NAVIGATION BAR
      // ========================================================
      //
      // Menggunakan widget custom:
      // CustomBottomNav
      //
      // Lokasi file:
      // lib/core/widgets/custom_bottom_nav.dart
      //
      bottomNavigationBar: CustomBottomNav(
        // currentIndex menentukan icon mana yang aktif
        currentIndex: _currentIndex,

        // onTap adalah callback ketika icon ditekan
        onTap: _onNavTapped,
      ),
    );
  }
}

// lib
// │
// ├── core
// │   │
// │   ├── constants
// │   │     app_colors.dart
// │   │
// │   └── widgets
// │         custom_bottom_nav.dart
// │
// ├── features
// │   │
// │   ├── home
// │   │     views
// │   │        home_screen.dart
// │   │
// │   ├── transaction
// │   │     views
// │   │        add_transaction_screen.dart
// │   │
// │   └── main
// │         views
// │            main_screen.dart
