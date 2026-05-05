import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'features/auth/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Menentukan initial route
  String initialRoute = AppRoutes.login;

  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser != null) {
    if (currentUser.isAnonymous) {
      // Jika sebelumnya login anonim (dari versi lama), kita logout paksa
      await FirebaseAuth.instance.signOut();
      initialRoute = AppRoutes.login;
    } else {
      // ✅ Selalu cek Firestore langsung (tidak andalkan SharedPreferences)
      // Ini memastikan user yang pindah perangkat/browser tetap masuk home
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final data = doc.data();

      if (doc.exists && data != null && (data['budgetBulanan'] ?? 0) > 0) {
        // Dokumen & budget ada → langsung ke home
        initialRoute = AppRoutes.home;
        // Sinkronkan SharedPreferences jika belum
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOnboardingDone', true);
      } else {
        // Akun ada tapi belum isi budget → ke onboarding
        initialRoute = AppRoutes.awal;
      }
    }
  }

  // Registrasi AuthController secara global
  Get.put(AuthController());

  runApp(MyApp(
    initialRoute: initialRoute,
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BudJet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),

      // 🔥 Route awal
      initialRoute: initialRoute,

      // 🔥 Semua route dari app_routes.dart
      routes: AppRoutes.getRoutes(),
    );
  }
}



