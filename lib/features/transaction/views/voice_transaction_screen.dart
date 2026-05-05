import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/voice_transaction_controller.dart';

class VoiceTransactionScreen extends StatelessWidget {
  const VoiceTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VoiceTransactionController());

    const Color bgColor = Color(0xFFDDEB71); 
    const Color darkColor = Color(0xFF14192D);

    // Memastikan state tereset saat user tekan back/keluar layar
    return PopScope(
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) controller.reset();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: darkColor),
            onPressed: () {
              controller.reset();
              Get.back();
            },
          ),
          title: const Text(
            'Voice Input',
            style: TextStyle(color: darkColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              
              const Text(
                "Format Pengucapan",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text(
                "[Nama] + [Kategori] + [Jumlah Pengeluaran]",
                style: TextStyle(
                  color: darkColor, 
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),

              const Spacer(),
              const Spacer(),
              
              Obx(() => GestureDetector(
                onTapDown: (_) => controller.startListening(),
                onTapUp: (_) => controller.stopAndProcess(),
                onTapCancel: () => controller.stopAndProcess(), // Jika jari user tergelincir dari tombol
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFakeWave(),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: darkColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: darkColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Icon(
                        controller.isListening.value ? Icons.stop : Icons.mic_none,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(width: 20),
                    _buildFakeWave(),
                  ],
                ),
              )),
              
              const Spacer(),

              Obx(() {
                if (controller.isProcessing.value) {
                  return const Column(
                    children: [
                      CircularProgressIndicator(color: darkColor),
                      SizedBox(height: 20),
                      Text("Sedang memproses suara...", 
                        style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
                    ],
                  );
                }
                
                String spokenText = controller.transcription.value;
                bool isPlaceholder = spokenText.isEmpty || spokenText == "Mendengarkan...";
                
                String displayText = isPlaceholder 
                    ? "“[Nama Transaksi] + [Kategori Transaksi] + [Harga Transaksi]”"
                    : '“$spokenText”';

                return Column(
                  children: [
                    Text(
                      controller.isListening.value 
                          ? "Sedang Mendengarkan..." 
                          : (isPlaceholder 
                              ? "Tekan & tahan tombol untuk bicara" 
                              : "Hasil Transkripsi:"),
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      displayText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: isPlaceholder ? Colors.black38 : darkColor,
                      ),
                    ),
                  ],
                );
              }),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.transcription.value.isNotEmpty && 
                        controller.transcription.value != "Mendengarkan...") {
                      controller.saveTransaction(); // Lempar ke AddTransactionScreen
                    } else {
                      Get.snackbar("Perhatian", "Silakan bicara terlebih dahulu",
                          backgroundColor: Colors.white, colorText: Colors.black);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Cek Input", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFakeWave() {
    return Row(
      children: [
        _waveBar(height: 30),
        _waveBar(height: 55),
        _waveBar(height: 85),
        _waveBar(height: 45),
        _waveBar(height: 70),
      ],
    );
  }

  Widget _waveBar({required double height}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF14192D),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}