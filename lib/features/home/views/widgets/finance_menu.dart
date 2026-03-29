import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';

class FinanceMenu extends StatelessWidget {
  const FinanceMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Row untuk menyusun tombol ke samping
    return Row(
      children: [
        // Expanded agar tombol membagi lebar layar sama rata
        Expanded(
          // GestureDetector atau InkWell digunakan agar Container biasa bisa diklik/ditekan seperti tombol
          child: InkWell(
            onTap: () {
              // FUNGSI NAVIGASI: Mengarahkan pengguna dari halaman Home ke halaman History
              Get.toNamed('/riwayat-transaksi');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ), // Padding atas bawah agar tombol tinggi
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              // Column untuk menyusun ikon di atas dan teks di bawahnya
              child: Column(
                children: const [
                  Icon(
                    Icons.history,
                    color: AppColors.textDark,
                    size: 30,
                  ), // Ikon jam putarbalik
                  SizedBox(height: 8),
                  Text(
                    'Riwayat',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 15), // Jarak antar tombol

        Expanded(
          child: InkWell(
            onTap: () {
              // Nanti diisi dengan navigasi ke halaman Laporan (Report Screen)
              // Saat ini dikosongkan dulu karena kita belum membuat file report_screen.dart
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.book,
                    color: AppColors.textDark,
                    size: 30,
                  ), // Ikon buku
                  SizedBox(height: 8),
                  Text(
                    'Laporan',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
