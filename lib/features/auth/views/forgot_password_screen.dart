import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _emailController = TextEditingController();

  void _showEmailSentDialog(String email) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: Color(0xFF4CAF50), size: 42),
            ),
            const SizedBox(height: 20),
            const Text(
              'Email Terkirim!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Tautan atur ulang kata sandi telah dikirim ke:\n$email',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          color: Color(0xFFF9A825), size: 16),
                      SizedBox(width: 6),
                      Text('Email tidak ditemukan?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFF9A825))),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Cek folder Spam / Junk di emailmu\n'
                    '• Cek folder Promosi atau Update\n'
                    '• Pastikan email yang dimasukkan benar\n'
                    '• Tunggu beberapa menit lalu cek kembali',
                    style: TextStyle(fontSize: 11, color: Colors.brown, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // tutup dialog
                  Get.back(); // kembali ke Login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8E669),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Kembali ke Login',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131A26),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        height: 50,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          'BudJet',
                          style: TextStyle(color: Color(0xFFC8E669), fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Jangan khawatir! Itu terjadi. Silakan masukkan alamat email yang tertaut dengan akun Anda.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            // Form Container
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => Get.back(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Lupa Kata Sandi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Email',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: 'Masukkan email anda',
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC8E669))),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Obx(() => ElevatedButton(
                      onPressed: _authController.isLoading.value
                          ? null
                          : () {
                              if (_emailController.text.isNotEmpty) {
                                _authController.sendPasswordResetEmail(
                                  _emailController.text,
                                  onSuccess: () => _showEmailSentDialog(_emailController.text),
                                );
                              } else {
                                Get.snackbar('Peringatan', 'Harap masukkan email Anda');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8E669),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _authController.isLoading.value
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                          : const Text('Kirim Tautan Atur Ulang →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
