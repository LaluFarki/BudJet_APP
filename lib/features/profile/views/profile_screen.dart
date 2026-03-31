import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../transaction/controllers/transaction_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan controller terdaftar
    final profileCtrl = Get.find<ProfileController>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Foto Profil dgn Bayangan
          GestureDetector(
            onTap: () {
              profileCtrl.pickProfileImage();
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Obx(() {
                    final path = profileCtrl.profileImagePath.value;
                    const avatarEmojis = ['🐱', '🐻', '🦊', '🐰', '🐼'];
                    const avatarColors = [
                      Color(0xFFFCE4EC), Color(0xFFFFF3E0), Color(0xFFFFF9C4),
                      Color(0xFFF3E5F5), Color(0xFFE8F5E9),
                    ];
                    if (path.startsWith('avatar:')) {
                      final idx = int.tryParse(path.split(':').last) ?? 0;
                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: avatarColors[idx.clamp(0, 4)],
                        child: Text(avatarEmojis[idx.clamp(0, 4)],
                            style: const TextStyle(fontSize: 46)),
                      );
                    } else if (path.isNotEmpty) {
                      return CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(File(path)),
                      );
                    } else {
                      return const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 46, color: Colors.grey),
                      );
                    }
                  }),
                ),
                // Icon Edit overlay photo
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4791EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Nama Profil
          Obx(() {
            return Text(
              profileCtrl.name.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: 0.5,
              ),
            );
          }),
          const SizedBox(height: 40),
          // Menu List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                _buildMenuCard(
                  title: 'Budget Saya',
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF70C94B),
                  iconBgColor: const Color(0xFFE4F8E4),
                  onTap: () {
                    Get.toNamed('/budget');
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  title: 'Data Diri',
                  icon: Icons.account_box_outlined,
                  iconColor: const Color(0xFF4791EB),
                  iconBgColor: const Color(0xFFE3EFFF),
                  onTap: () {
                    Get.toNamed('/data-diri');
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  title: 'Log Out',
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFEC6A6A),
                  iconBgColor: const Color(0xFFFFECEC),
                  onTap: () {
                    // TODO: Aksi Log Out
                  },
                ),
                const SizedBox(height: 32),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textGrey,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    final txCtrl = Get.find<TransactionController>();
                    txCtrl.injectDummyData();
                  },
                  icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: const Text(
                    "Suntik Data Dummy",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                      color: Color.fromARGB(255, 30, 30, 30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
