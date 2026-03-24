import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../transaction/controllers/transaction_controller.dart';

import 'widgets/balance_card.dart';
import 'widgets/expense_summary.dart';
import 'widgets/finance_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller GetX
    Get.put(TransactionController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Mematikan efek overscroll stretch (karet) bawaan Android
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Nama & Foto)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Selamat Pagi',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      Text(
                        'Smith Joie',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Kotak Saldo
              const BalanceCard(),
              const SizedBox(height: 20),

              // 3. Kotak Ringkasan Pengeluaran
              const ExpenseSummary(),
              const SizedBox(height: 25),

              // 4. Menu Keuangan
              const Text(
                "Keuangan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const FinanceMenu(),
              const SizedBox(height: 25),

              // 5. Header Daftar Transaksi + Tombol "Lihat Semua"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Riwayat Transaksi Hari Ini",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  // Tombol navigasi ke RiwayatTransaksiScreen
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/riwayat-transaksi'),
                    child: const Text(
                      "Lihat Semua",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // ======================================================
              // LIST FITUR: DAFTAR TRANSAKSI HARI INI
              // ======================================================
              Obx(() {
                final txController = Get.find<TransactionController>();
                final todayTxs = txController.todayTransactions;

                // Jika hari ini belum ada transaksi sama sekali
                if (todayTxs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Text(
                        'Belum ada transaksi hari ini.',
                        style: TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  );
                }

                // Render List secara dinamis tanpa Scroll karena di dalam SingleChildScrollView
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayTxs.length > 7 ? 7 : todayTxs.length,
                  itemBuilder: (context, index) {
                    final tx = todayTxs[index];
                    final isIncome = tx.type == 'income';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icon Transaksi (Hijau ke bawah / Merah ke atas)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Detail Transaksi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  tx.kategori,
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Nominal Transaksi
                          Text(
                            isIncome
                                ? '+ Rp${tx.amount.toStringAsFixed(0)}'
                                : '- Rp${tx.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
              
              // Jarak pengaman di paling bawah agar item terakhir tidak tertimpa 
              // oleh bar navigasi putih di bagian bawah layar.
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // HAPUS BAGIAN INI DARI KODEMU YANG SEBELUMNYA:
      // floatingActionButton: ...
      // floatingActionButtonLocation: ...
      // bottomNavigationBar: ...
    );
  }
}

/*
=========================================================
DOKUMENTASI PEMBELAJARAN FLUTTER – HOME SCREEN
=========================================================

📌 1. TUJUAN LAYAR
---------------------------------------------------------
HomeScreen adalah halaman utama aplikasi setelah pengguna masuk.
Layar ini menampilkan ringkasan kondisi keuangan hari ini:
- Salam sapa dan foto profil
- Saldo total dan sisa budget harian (BalanceCard)
- Ringkasan pemasukan & pengeluaran (ExpenseSummary)
- Menu akses cepat ke fitur (FinanceMenu)
- Judul untuk daftar transaksi (akan diisi widget terpisah)

LAYAR INI TIDAK MENGANDUNG BOTTOM NAVIGASI ATAU FAB.
Navigasi dan tombol tambah dikelola oleh parent widget
(misalnya di MainScreen atau HomeWrapper) agar lebih terstruktur.

---------------------------------------------------------
📌 2. STRUKTUR FOLDER DAN FILE TERKAIT
---------------------------------------------------------
File ini berada di:
lib/features/home/views/home_screen.dart

Widget yang di-import:
- ../../../core/constants/app_colors.dart
   → dari lib/core/constants/app_colors.dart (warna tema)

- widgets/balance_card.dart
   → dari lib/features/home/views/widgets/balance_card.dart

- widgets/expense_summary.dart
   → dari lib/features/home/views/widgets/expense_summary.dart

- widgets/finance_menu.dart
   → dari lib/features/home/views/widgets/finance_menu.dart

Catatan: Baris import custom_bottom_nav sudah dihapus karena
bottom navigation tidak lagi dipasang di sini.

---------------------------------------------------------
📌 3. MENGAPA STATELESSWIDGET?
---------------------------------------------------------
HomeScreen saat ini hanya menampilkan data statis (belum ada
data dinamis dari controller). Semua konten tetap dan tidak
berubah berdasarkan interaksi di dalam layar ini. Karena itu,
StatelessWidget sudah cukup.

Nanti jika data sudah diambil dari database/API, widget ini
akan diubah menjadi StatefulWidget atau menggunakan
state management (GetX/Provider/Riverpod) dengan controller.

---------------------------------------------------------
📌 4. PENJELASAN BAGIAN PER BAGIAN
---------------------------------------------------------

🔹 Scaffold
   - Memberikan struktur dasar halaman.
   - backgroundColor: AppColors.backgroundLight → warna latar
     dari tema aplikasi.
   - body: berisi seluruh konten layar.

🔹 SafeArea
   - Menghindari area notch, status bar, dan home indicator.
   - Memastikan konten tidak terpotong oleh lekukan layar.

🔹 SingleChildScrollView
   - Membungkus seluruh konten agar bisa di-scroll jika layar
     sempit (misal keyboard muncul atau konten terlalu panjang).
   - padding: 20.0 di semua sisi → memberi ruang tepi yang rapi.

🔹 Column dengan crossAxisAlignment.start
   - Menyusun widget secara vertikal.
   - crossAxisAlignment.start membuat semua child rata kiri.

---------------------------------------------------------
📌 5. BAGIAN 1: HEADER (NAMA & FOTO)
---------------------------------------------------------
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(...),  // Teks sambutan
    CircleAvatar(...) // Foto profil
  ]
)

- Menggunakan Row untuk menempatkan teks di kiri dan foto di kanan.
- Column di dalamnya berisi dua teks:
  * "Selamat Pagi" dengan warna abu-abu (textGrey)
  * "Smith Joie" dengan ukuran 24 dan tebal
- CircleAvatar menampilkan foto profil (masih placeholder dari
  network image). Nanti bisa diganti dengan foto dari akun Google.

---------------------------------------------------------
📌 6. BAGIAN 2: BALANCE CARD (WIDGET TERPISAH)
---------------------------------------------------------
const BalanceCard()

- Widget terpisah yang berada di file:
  lib/features/home/views/widgets/balance_card.dart
- Bertugas menampilkan dua informasi utama:
  * Sisa budget total
  * Sisa budget harian
- Menggunakan desain dual widget view sesuai backlog #9.
- Karena const, tidak ada perubahan state di sini.

---------------------------------------------------------
📌 7. BAGIAN 3: EXPENSE SUMMARY (WIDGET TERPISAH)
---------------------------------------------------------
const ExpenseSummary()

- File: lib/features/home/views/widgets/expense_summary.dart
- Menampilkan ringkasan pengeluaran, misalnya total pemasukan,
  total pengeluaran hari ini, atau persentase budget yang terpakai.
- Bisa dalam bentuk progress bar, angka, atau teks.

---------------------------------------------------------
📌 8. BAGIAN 4: FINANCE MENU (WIDGET TERPISAH)
---------------------------------------------------------
Text("Keuangan", style: ...)
const FinanceMenu()

- Teks "Keuangan" sebagai judul menu.
- FinanceMenu dari file:
  lib/features/home/views/widgets/finance_menu.dart
- Biasanya berisi 3-4 ikon dengan label, seperti:
  * Transfer, Tagihan, Top Up, dll (atau sesuai kebutuhan).
- Di backlog disebut "finance_menu.dart" untuk menu keuangan cepat.

---------------------------------------------------------
📌 9. BAGIAN 5: JUDUL DAFTAR TRANSAKSI
---------------------------------------------------------
Text("Riwayat Transaksi Hari Ini", ...)

- Hanya judul, belum ada daftar transaksinya.
- Nanti di bawah judul ini akan ditambahkan widget
  TransactionList yang menampilkan transaksi hari ini.
- TransactionList bisa dibuat terpisah di file yang sama
  atau di widget terpisah.

---------------------------------------------------------
📌 10. MENGAPA BOTTOM NAVIGASI DAN FAB DIHAPUS?
---------------------------------------------------------
Kode sebelumnya mungkin memasang bottomNavigationBar dan
floatingActionButton langsung di HomeScreen. Sekarang keduanya
dipindahkan ke parent (misal HomeWrapper atau MainScreen) karena:

- Bottom navigation biasanya tetap berada di semua halaman utama,
  sehingga lebih efisien ditempatkan di satu tempat induk.
- Floating action button untuk tambah transaksi harus konsisten
  muncul di beberapa halaman (Home, History, dll). Dengan
  menempatkannya di parent, kita tidak perlu menduplikasi kode.

Pendekatan ini mengikuti prinsip DRY (Don't Repeat Yourself).

---------------------------------------------------------
📌 11. HAL YANG AKAN DATANG (RENCANA PENGEMBANGAN)
---------------------------------------------------------
1. Menambahkan TransactionList di bawah judul riwayat.
2. Menghubungkan dengan controller (GetX/Provider) untuk
   mengambil data transaksi real dari database.
3. Menambahkan pull-to-refresh.
4. Animasi ketika data berubah.
5. Menampilkan status overspending jika melebihi budget.

---------------------------------------------------------
📌 12. LATIHAN UNTUK MEMAHAMI LEBIH DALAM
---------------------------------------------------------
Coba lakukan modifikasi berikut:
1️⃣ Ganti teks "Smith Joie" dengan nama dari SharedPreferences.
2️⃣ Tambahkan icon notifikasi di sebelah kanan foto.
3️⃣ Buat widget TransactionList sederhana (ListTile) dengan data dummy.
4️⃣ Hubungkan BalanceCard dengan nilai budget dari controller sederhana.

---------------------------------------------------------
📌 13. KESIMPULAN
---------------------------------------------------------
HomeScreen adalah pusat informasi keuangan harian. Saat ini
masih statis dan fokus pada struktur tata letak. Dengan
memisahkan setiap bagian ke widget masing-masing, kode menjadi
lebih bersih dan mudah dikelola. Penghapusan navigasi dari sini
membantu menjaga tanggung jawab tunggal (single responsibility).

🚀 Layar ini siap dikoneksikan dengan data nyata dan logika bisnis!
*/
