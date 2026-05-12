import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                onTap: () => _showChangePasswordDialog(context),
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

  // Dialog ganti kata sandi
  void _showChangePasswordDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    if (isGoogle) {
      Get.snackbar(
        'Perhatian',
        'Akun yang login dengan Google tidak dapat mengganti kata sandi dari aplikasi.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFFECEC),
        colorText: const Color(0xFF8B0000),
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
      return;
    }

    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final isCurrentObscure = ValueNotifier<bool>(true);
    final isNewObscure = ValueNotifier<bool>(true);
    final isSaving = ValueNotifier<bool>(false);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ganti Kata Sandi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan kata sandi saat ini dan kata sandi baru untuk akunmu.',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.5),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: isCurrentObscure,
                builder: (_, obscure, __) => TextField(
                  controller: currentPasswordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Saat Ini',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => isCurrentObscure.value = !isCurrentObscure.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: isNewObscure,
                builder: (_, obscure, __) => TextField(
                  controller: newPasswordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => isNewObscure.value = !isNewObscure.value,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: isSaving,
                  builder: (_, saving, __) => ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final currentPwd = currentPasswordCtrl.text;
                            final newPwd = newPasswordCtrl.text;

                            if (currentPwd.isEmpty || newPwd.isEmpty) {
                              Get.snackbar(
                                'Error',
                                'Semua kolom harus diisi.',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: const Color(0xFFFFECEC),
                                colorText: const Color(0xFF8B0000),
                                margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              );
                              return;
                            }

                            if (newPwd.length < 8 ||
                                !newPwd.contains(RegExp(r'[A-Z]')) ||
                                !newPwd.contains(RegExp(r'[a-z]')) ||
                                !newPwd.contains(RegExp(r'[0-9]'))) {
                              Get.snackbar(
                                'Peringatan',
                                'Kata sandi minimal 8 karakter, harus terdiri dari huruf besar, huruf kecil, dan angka.',
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                                margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              );
                              return;
                            }

                            isSaving.value = true;
                            try {
                              final credential = EmailAuthProvider.credential(
                                email: user.email!,
                                password: currentPwd,
                              );
                              await user.reauthenticateWithCredential(credential);
                              await user.updatePassword(newPwd);
                              
                              Get.back(); // Tutup dialog
                              Get.snackbar(
                                'Sukses',
                                'Kata sandi berhasil diubah.',
                                backgroundColor: const Color(0xFFECFFEC),
                                colorText: const Color(0xFF1B5E20),
                                snackPosition: SnackPosition.TOP,
                                margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              );
                            } on FirebaseAuthException catch (e) {
                              String pesan = 'Gagal mengganti kata sandi. Silakan coba lagi.';
                              if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                                pesan = 'Kata sandi saat ini salah.';
                              } else if (e.code == 'too-many-requests') {
                                pesan = 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
                              }
                              Get.snackbar(
                                'Gagal',
                                pesan,
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: const Color(0xFFFFECEC),
                                colorText: const Color(0xFF8B0000),
                                margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              );
                            } finally {
                              isSaving.value = false;
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4791EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Dialog konfirmasi awal
  void _showDeleteAccountDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFECEC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_outlined,
                  color: Color(0xFFEC6A6A), size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Akun?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Semua data transaksi dan budget kamu akan dihapus permanen dan tidak bisa dipulihkan.',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Batal',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    _showPasswordConfirmDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC6A6A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Lanjut'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dialog input kata sandi / re-autentikasi Google
  void _showPasswordConfirmDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cek apakah user login via Google
    final isGoogle = user.providerData
        .any((p) => p.providerId == 'google.com');

    if (isGoogle) {
      _deleteWithGoogle(user);
      return;
    }

    // Login via Email/Password → minta kata sandi
    final passwordCtrl = TextEditingController();
    final isObscure = ValueNotifier<bool>(true);
    final isDeleting = ValueNotifier<bool>(false);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Kata Sandi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan kata sandi kamu untuk mengkonfirmasi penghapusan akun.',
              style: TextStyle(
                  fontSize: 13, color: Colors.blueGrey, height: 1.5),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: isObscure,
              builder: (_, obscure, __) => TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => isObscure.value = !isObscure.value,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Batal',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: isDeleting,
                  builder: (_, deleting, __) => ElevatedButton(
                    onPressed: deleting
                        ? null
                        : () async {
                            if (passwordCtrl.text.isEmpty) {
                              Get.snackbar(
                                'Kata Sandi Kosong',
                                'Masukkan kata sandi terlebih dahulu.',
                                snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
                              return;
                            }
                            isDeleting.value = true;
                            await _deleteWithPassword(
                                user, passwordCtrl.text);
                            isDeleting.value = false;
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC6A6A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: deleting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Hapus Akun'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _deleteWithPassword(User user, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await _hapusDataFirestore(user.uid);
      await user.delete();
      Get.back(); // Tutup dialog
      Get.offAllNamed('/login');
      Get.snackbar(
        'Akun Dihapus',
        'Akun dan semua datamu telah dihapus secara permanen.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFECFFEC),
        colorText: const Color(0xFF1B5E20),
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    } on FirebaseAuthException catch (e) {
      String pesan;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        pesan = 'Kata sandi yang kamu masukkan salah. Coba lagi.';
      } else if (e.code == 'too-many-requests') {
        pesan = 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      } else {
        pesan = 'Gagal menghapus akun. Silakan coba lagi.';
      }
      Get.snackbar(
        'Gagal',
        pesan,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFFECEC),
        colorText: const Color(0xFF8B0000),
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    }
  }

  Future<void> _deleteWithGoogle(User user) async {
    try {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizationForScopes([]);
      final credential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      await _hapusDataFirestore(user.uid);
      await user.delete();
      Get.offAllNamed('/login');
      Get.snackbar(
        'Akun Dihapus',
        'Akun dan semua datamu telah dihapus secara permanen.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal menghapus akun. Silakan coba lagi.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFFECEC),
        colorText: const Color(0xFF8B0000),
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    }
  }

  // Hapus semua data user dari Firestore
  Future<void> _hapusDataFirestore(String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    // Hapus sub-koleksi transaksi
    final txSnap = await ref.collection('transactions').get();
    for (final doc in txSnap.docs) {
      await doc.reference.delete();
    }
    // Hapus dokumen utama
    await ref.delete();
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
