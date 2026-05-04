import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Seksi Akun ===
              _buildSectionLabel('Akun'),
              _buildMenuCard(
                title: 'Ganti Kata Sandi',
                subtitle: 'Ubah kata sandi akun kamu',
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF4791EB),
                iconBgColor: const Color(0xFFE3EFFF),
                onTap: () => Get.toNamed('/forgot-password'),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                title: 'Hapus Akun',
                subtitle: 'Hapus akun dan semua data secara permanen',
                icon: Icons.delete_forever_outlined,
                iconColor: const Color(0xFFEC6A6A),
                iconBgColor: const Color(0xFFFFECEC),
                onTap: () => _showDeleteAccountDialog(context),
              ),
              const SizedBox(height: 24),

              // === Seksi Bantuan ===
              _buildSectionLabel('Bantuan'),
              _buildMenuCard(
                title: 'Bantuan / FAQ',
                subtitle: 'Pertanyaan yang sering ditanyakan',
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF9C6FDE),
                iconBgColor: const Color(0xFFF3EEFF),
                onTap: () => _showFaqDialog(context),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                title: 'Hubungi Kami',
                subtitle: 'Kirim pertanyaan atau masukan ke tim kami',
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF70C94B),
                iconBgColor: const Color(0xFFE4F8E4),
                onTap: () => _showContactDialog(context),
              ),
              const SizedBox(height: 40),

              // === Versi Aplikasi ===
              Center(
                child: Column(
                  children: [
                    Text(
                      'BudJet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versi 2.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
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
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Akun?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Semua data transaksi dan budgetmu akan dihapus permanen dan tidak bisa dipulihkan.\n\nApakah kamu yakin?',
          style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                final authCtrl = Get.find<AuthController>();
                authCtrl.logout();
              } catch (e) {
                Get.snackbar(
                  'Gagal',
                  'Silakan login ulang terlebih dahulu sebelum menghapus akun.',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC6A6A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Bantuan / FAQ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FaqItem(
                q: 'Bagaimana cara menambah transaksi?',
                a: 'Tekan tombol (+) di bagian bawah layar, lalu isi nama, nominal, dan kategori.',
              ),
              _FaqItem(
                q: 'Bagaimana cara menambah budget?',
                a: 'Pergi ke menu Budget, lalu tekan tombol tambah untuk menambahkan kategori dan anggaran.',
              ),
              _FaqItem(
                q: 'Apakah data saya aman?',
                a: 'Ya, semua data disimpan di Firebase yang terenkripsi dan hanya bisa diakses oleh akun kamu.',
              ),
              _FaqItem(
                q: 'Bagaimana cara ganti foto profil?',
                a: 'Tekan foto profil di halaman Profil, lalu pilih foto dari galeri atau pilih avatar.',
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.textDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE4F8E4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_outlined,
                color: Color(0xFF70C94B),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hubungi Kami',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Punya pertanyaan atau masukan?\nKami siap membantu kamu!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text(
                    'support@budjet.app',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.textDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❓ $q',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            a,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
