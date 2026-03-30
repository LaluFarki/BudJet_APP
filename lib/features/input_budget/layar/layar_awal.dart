import 'package:flutter/material.dart';
import '../komponen/tombol_utama.dart';
import 'layar_form_anggaran.dart';

class LayarAwal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Page awal gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.asset(
                    "assets/img/image1.png",
                    height: size.height * 0.45, // Dinamis sesuai tinggi hp
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Budgeting made",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      height: 1.1
                    ),
                  ),
                ),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "for Student",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  "Track expenses, split bills with \nroommates, and manage your \nmoney easily.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16, // Diturunkan sedikit agar pas
                    color: Colors.grey[700],
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                TombolUtama(
                  teks: "Get Started ",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LayarFormAnggaran(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

