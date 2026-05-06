import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_routes.dart';
import '../../transaction/controllers/transaction_controller.dart';


class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;

  // ─── Mapper kode error Firebase → pesan Bahasa Indonesia ───────────────────
  String _pesanError(FirebaseAuthException e, {required String konteks}) {
    switch (e.code) {
      // ── Kredensial ──
      case 'invalid-credential':
      case 'wrong-password':
        return 'Email tidak terdaftar atau kata sandi yang kamu masukkan salah. '
            'Pastikan akun sudah dibuat, atau coba daftar terlebih dahulu.';
      case 'user-not-found':
        return konteks == 'reset'
            ? 'Email ini belum terdaftar. Pastikan kamu memasukkan email yang benar.'
            : 'Akun dengan email ini tidak ditemukan. Silakan daftar terlebih dahulu.';
      case 'invalid-email':
        return 'Format email tidak valid. Contoh yang benar: nama@email.com';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi kami untuk bantuan lebih lanjut.';
      // ── Pendaftaran ──
      case 'email-already-in-use':
        return 'Email ini sudah digunakan akun lain. Silakan gunakan email berbeda atau langsung login.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter dengan kombinasi huruf dan angka.';
      case 'operation-not-allowed':
        return 'Metode login ini belum diaktifkan. Silakan hubungi kami.';
      // ── Jaringan & Batas ──
      case 'network-request-failed':
        return 'Gagal terhubung ke internet. Periksa koneksi internetmu dan coba lagi.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Akun sementara dikunci. Coba lagi beberapa menit kemudian.';
      // ── Google / Credential linking ──
      case 'account-exists-with-different-credential':
        return 'Email ini sudah terdaftar menggunakan kata sandi. Silakan login dengan Email dan Kata Sandi kamu.';
      case 'popup-closed-by-user':
        return 'Proses login dibatalkan. Coba lagi jika kamu ingin melanjutkan.';
      // ── Fallback ──
      default:
        return 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.';
    }
  }

  // ─── Login dengan Email dan Password ───────────────────────────────────────
  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _checkOnboardingAndNavigate();
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Gagal',
        _pesanError(e, konteks: 'login'),
        backgroundColor: const Color(0xFFFFECEC),
        colorText: const Color(0xFF8B0000),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        borderRadius: 12,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Daftar dengan Email dan Password ──────────────────────────────────────
  Future<void> registerWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': 'Pengguna Baru',
          'email': email,
          'profilePic': '',
          'budgetBulanan': 0,
          'balance': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar(
        'Pendaftaran Berhasil 🎉',
        'Akun berhasil dibuat. Silakan masuk dengan email dan kata sandimu.',
        backgroundColor: const Color(0xFFECFFEC),
        colorText: const Color(0xFF1B5E20),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        borderRadius: 12,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
      Get.offAllNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Pendaftaran Gagal',
        _pesanError(e, konteks: 'register'),
        backgroundColor: const Color(0xFFFFECEC),
        colorText: const Color(0xFF8B0000),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        borderRadius: 12,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Login dengan Google ────────────────────────────────────────────────────
  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      await GoogleSignIn.instance.initialize();

      GoogleSignInAccount googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } catch (e) {
        isLoading.value = false;
        return; // User menutup popup Google, tidak perlu tampilkan error
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizationForScopes([]);

      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        UserCredential userCredential =
            await _auth.signInWithCredential(googleCredential);

        if (userCredential.user != null) {
          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
          if (!userDoc.exists) {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'name': userCredential.user!.displayName ?? 'Pengguna',
              'email': userCredential.user!.email,
              'profilePic': userCredential.user!.photoURL ?? '',
              'budgetBulanan': 0,
              'balance': 0,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
        _checkOnboardingAndNavigate();
      } on FirebaseAuthException catch (e) {
        Get.snackbar(
          'Login Google Gagal',
          _pesanError(e, konteks: 'google'),
          backgroundColor: const Color(0xFFFFECEC),
          colorText: const Color(0xFF8B0000),
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          borderRadius: 12,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
      }
    } catch (e) {
      Get.snackbar(
        'Login Google Gagal',
        'Terjadi masalah saat login dengan Google. Pastikan kamu terhubung ke internet.',
        backgroundColor: const Color(0xFFFFECEC),
        colorText: const Color(0xFF8B0000),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        borderRadius: 12,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Reset Password via Email ───────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email,
      {VoidCallback? onSuccess}) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);
      if (onSuccess != null) {
        onSuccess();
      } else {
        Get.snackbar(
          'Email Terkirim ✉️',
          'Tautan untuk mengatur ulang kata sandi telah dikirim ke $email. '
              'Periksa kotak masuk atau folder spam kamu.',
          backgroundColor: const Color(0xFFECFFEC),
          colorText: const Color(0xFF1B5E20),
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          borderRadius: 12,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Gagal Mengirim Email',
        _pesanError(e, konteks: 'reset'),
        backgroundColor: const Color(0xFFFFECEC),
        colorText: const Color(0xFF8B0000),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        borderRadius: 12,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    Get.delete<TransactionController>(force: true);

    Get.offAllNamed(AppRoutes.login);
  }

  // ─── Cek onboarding & navigasi ─────────────────────────────────────────────
  Future<void> _checkOnboardingAndNavigate() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // Selalu cek Firestore agar konsisten lintas perangkat
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();

    if (doc.exists && data != null && (data['budgetBulanan'] ?? 0) > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOnboardingDone', true);
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.awal);
    }
  }
}
