import 'package:flutter/material.dart';
import 'package:budjet/features/onboarding/views/layar_profil_setup.dart';

class LayarAwal extends StatelessWidget {
  const LayarAwal({super.key});

  @override
  Widget build(BuildContext context) {
    final limeColor = const Color(0xFFD4E858);
    final darkNavy = const Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Warna asli yang lebih halus
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Gambar dengan efek fade di 4 sisi (Vignette) agar menyatu total
                Center(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                        stops: [0.0, 0.05, 0.95, 1.0], // Fade atas & bawah
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                          stops: [0.0, 0.05, 0.95, 1.0], // Fade kiri & kanan
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        "assets/img/image2.jpeg",
                        height: MediaQuery.of(context).size.height * 0.42,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30), // Jarak disesuaikan agar pas

                // Judul Bahasa Indonesia
                Text(
                  "Budgeting untuk\nMahasiswa",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42, // Dibesarkan sedikit dari 40
                    fontWeight: FontWeight.w900,
                    color: darkNavy,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                
                const SizedBox(height: 24),

                // Deskripsi Bahasa Indonesia (RichText)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 17, // Dibesarkan sedikit dari 16
                      height: 1.5,
                      color: Colors.grey.shade600,
                      fontFamily: 'Roboto', // Pastikan font konsisten
                    ),
                    children: [
                      TextSpan(
                        text: "Tracking ",
                        style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy),
                      ),
                      const TextSpan(text: "pengeluaran, "),
                      TextSpan(
                        text: "Pembagian\n",
                        style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy),
                      ),
                      const TextSpan(text: "budget bulanan, dan "),
                      TextSpan(
                        text: "Penyesuaian\n",
                        style: TextStyle(fontWeight: FontWeight.bold, color: darkNavy),
                      ),
                      const TextSpan(text: "budget harian"),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Tombol Mulai
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LayarProfilSetup(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: limeColor,
                      foregroundColor: darkNavy,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Mulai",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

