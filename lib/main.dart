import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes/app_routes.dart'; // Memanggil peta jalan kita
import 'firebase_options.dart'; // File yang dibuat oleh flutterfire configure

void main() async {
  // Wajib: memastikan Flutter siap untuk kode async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aplikasi Keuangan',
      debugShowCheckedModeBanner: false, // Menghilangkan pita 'DEBUG'
      theme: ThemeData(fontFamily: 'Roboto'),
      // MENGGUNAKAN APP ROUTES SEBAGAI NAVIGASI UTAMA
      initialRoute: AppRoutes.home,
      routes: AppRoutes.getRoutes(),
    );
  }
}
