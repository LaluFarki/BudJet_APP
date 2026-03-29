import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1728), // Latar belakang gelap (Navy Slate)
      body: Column(
        children: [
          // Bagian atas (Gambar Utama dengan Logo)
          Expanded(
            flex: 55, // Mengambil 55% ruang vertikal atas
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/onboarding.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Bagian bawah (Wadah Putih Melengkung)
          Expanded(
            flex: 45, // Mengambil 45% ruang vertikal bawah
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  // Judul dengan Underline Custom
                  Column(
                    children: [
                      const Text(
                        'Budgeting untuk',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: 2,
                            child: Container(
                              height: 12,
                              width: 155,
                              color: const Color(0xFFD4F069), // Garis stabilo
                            ),
                          ),
                          const Text(
                            'Mahasiswa',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Deskripsi
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Tracking pengeluaran, Pembagian budget bulanan, dan Penyesuaian budget harian',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B), // Slate grey
                        height: 1.5,
                      ),
                    ),
                  ),

                  const Spacer(),
                  
                  // Tombol Mulai
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Pergi ke Home dan hapus navigasi onboarding
                        Get.offAllNamed(AppRoutes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4F069),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Mulai',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: AppColors.textDark),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Teks "Masuk"
                  RichText(
                    text: const TextSpan(
                      text: 'Sudah punya akun? ',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Masuk',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
