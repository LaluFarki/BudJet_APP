import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Melakukan login anonim di background
  await FirebaseAuth.instance.signInAnonymously();

  final prefs = await SharedPreferences.getInstance();
  bool isOnboardingDone = prefs.getBool('isOnboardingDone') ?? false;

  // ── Validasi ganda: cek juga apakah dokumen Firestore masih ada ──
  // Kalau user hapus dokumen Firestore, kita reset onboarding agar mulai dari awal lagi
  if (isOnboardingDone) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      // Kalau dokumen tidak ada ATAU belum ada budgetBulanan → reset onboarding
      if (!doc.exists || data == null || !data.containsKey('budgetBulanan')) {
        await prefs.setBool('isOnboardingDone', false);
        isOnboardingDone = false;
      }
    }
  }

  runApp(MyApp(
    initialRoute: isOnboardingDone ? AppRoutes.home : AppRoutes.awal,
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aplikasi Keuangan',
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