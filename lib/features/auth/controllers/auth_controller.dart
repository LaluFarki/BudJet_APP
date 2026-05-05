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

  // Login dengan Email dan Password
  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _checkOnboardingAndNavigate();
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Login Gagal', e.message ?? 'Terjadi kesalahan');
    } finally {
      isLoading.value = false;
    }
  }

  // Daftar dengan Email dan Password
  Future<void> registerWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Simpan data pengguna ke Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'name': 'Pengguna Baru', // Nama default, nanti bisa diubah user
          'email': email,
          'profilePic': '',
          'budgetBulanan': 0,
          'balance': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar('Sukses', 'Akun berhasil dibuat. Silakan login.');
      Get.offAllNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Pendaftaran Gagal', e.message ?? 'Terjadi kesalahan');
    } finally {
      isLoading.value = false;
    }
  }

  // Login dengan Google
  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      await GoogleSignIn.instance.initialize();

      GoogleSignInAccount googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } catch (e) {
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final authz = await googleUser.authorizationClient.authorizationForScopes([]);

      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        UserCredential userCredential = await _auth.signInWithCredential(googleCredential);

        // Cek apakah ini user baru di Firestore
        if (userCredential.user != null) {
          final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
          if (!userDoc.exists) {
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
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
        if (e.code == 'account-exists-with-different-credential') {
          // Email sudah terdaftar pakai Email/Password
          Get.snackbar(
            'Login Gagal',
            'Email ini sudah terdaftar menggunakan kata sandi. Silakan login dengan Email dan Kata Sandi kamu.',
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.snackbar('Google Login Gagal', e.message ?? e.code);
        }
      }
    } catch (e) {
      Get.snackbar('Google Login Gagal', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Reset Password via Email
  Future<void> sendPasswordResetEmail(String email, {VoidCallback? onSuccess}) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);
      if (onSuccess != null) {
        onSuccess();
      } else {
        Get.snackbar('Terkirim', 'Tautan atur ulang kata sandi telah dikirim ke $email');
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Gagal', e.message ?? 'Gagal mengirim email reset');
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    Get.delete<TransactionController>(force: true);

    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _checkOnboardingAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    bool isOnboardingDone = prefs.getBool('isOnboardingDone') ?? false;

    if (isOnboardingDone) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.awal);
    }
  }
}
