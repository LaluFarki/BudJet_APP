import 'package:flutter/material.dart';
import '../komponen/tombol_utama.dart';
import 'layar_form_anggaran.dart';

class LayarAwal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Page awal gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.asset(
                "assets/img/image1.png",
                height: 450,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 5),

            Text(
              "Budgeting made",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                  height: 1.1
              ),
            ),

            Text(
              "for Student",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,

              ),
            ),



            Text(
              "Track expenses, split bills  with \nroommates, and manage   your \n money easily.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 60),

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
    );
  }
}

