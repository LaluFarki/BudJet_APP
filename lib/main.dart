import 'package:flutter/material.dart';
import 'routes/app_routes.dart'; // Memanggil peta jalan kita

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Keuangan',
      debugShowCheckedModeBanner: false, // Menghilangkan pita 'DEBUG'
      theme: ThemeData(fontFamily: 'Roboto'),
      // MENGGUNAKAN APP ROUTES SEBAGAI NAVIGASI UTAMA
      initialRoute: AppRoutes.home,
      routes: AppRoutes.getRoutes(),
    );
  }
}
