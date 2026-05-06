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
        // ... (kode appbar sebelumnya)
        body: SafeArea( // 1. Tambahkan SafeArea agar tidak menabrak status bar/bawah layar
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView( // 2. Jadikan scrollable
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight, // 3. Setinggi minimal layar
                  ),
                  child: IntrinsicHeight( // 4. Membiarkan Spacer() tetap berfungsi
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          
                          const Text(
                            "Format Pengucapan",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "[Nama] + [Kategori] + [Jumlah Pengeluaran]",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: darkColor, 
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const Text(
                            "Contoh:",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const Text(
                            "Naik gojek, termasuk transportasi, harga lima puluh ribu",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: darkColor, 
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          
                          // --- Bagian Tombol Mic & Wave ---
                          Obx(() => GestureDetector(
                            onTapDown: (_) => controller.handleMicTapDown(),
                            onTapUp: (_) => controller.handleMicTapUp(),
                            onTapCancel: () => controller.handleMicTapCancel(), 
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildFakeWave(controller.isListening.value),
                                const SizedBox(width: 20),
                                Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: darkColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: darkColor.withValues(alpha: 0.3),
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
                                _buildFakeWave(controller.isListening.value),
                              ],
                            ),
                          )),
                          
                          const Spacer(),

                          // --- Bagian Teks Hasil Transkripsi ---
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
                                ? "“[Nama Transaksi] + [Kategori] + [Harga]”"
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

                          // --- Tombol Cek Input ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (controller.transcription.value.isNotEmpty && 
                                    controller.transcription.value != "Mendengarkan...") {
                                  controller.saveTransaction(); 
                                } else {
                                  Get.snackbar("Perhatian", "Silakan bicara terlebih dahulu",
                                      backgroundColor: Colors.white, colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
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
                          const SizedBox(height: 20), // Kurangi padding bawah agar tidak terlalu padat
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

  Widget _buildFakeWave(bool isListening) {
    return Row(
      children: [
        AnimatedWaveBar(maxHeight: 30, isListening: isListening, delayMs: 0),
        AnimatedWaveBar(maxHeight: 55, isListening: isListening, delayMs: 150),
        AnimatedWaveBar(maxHeight: 85, isListening: isListening, delayMs: 300),
        AnimatedWaveBar(maxHeight: 45, isListening: isListening, delayMs: 150),
        AnimatedWaveBar(maxHeight: 70, isListening: isListening, delayMs: 0),
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

class AnimatedWaveBar extends StatefulWidget {
  final double maxHeight;
  final bool isListening;
  final int delayMs;

  const AnimatedWaveBar({
    super.key,
    required this.maxHeight,
    required this.isListening,
    required this.delayMs,
  });

  @override
  State<AnimatedWaveBar> createState() => _AnimatedWaveBarState();
}

class _AnimatedWaveBarState extends State<AnimatedWaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350), // Kecepatan gelombang naik
    );

    // Animasi bergerak dari 20% ukurannya ke 100% ukuran maksimal
    _animation = Tween<double>(begin: widget.maxHeight * 0.2, end: widget.maxHeight)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isListening) {
      _startAnimation();
    } else {
      _controller.value = 0.5; // Ukuran awal saat diam (separuh jalan)
    }
  }

  void _startAnimation() {
    // Delay ini bikin baris bergerak berurutan seperti gelombang suara
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted && widget.isListening) {
        _controller.repeat(reverse: true); // Bergerak naik turun terus-menerus
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedWaveBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kalau tombol mulai ditahan
    if (widget.isListening && !oldWidget.isListening) {
      _startAnimation();
    } 
    // Kalau tombol dilepas
    else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
      // Animasi kembali perlahan ke ukuran diam agar tidak patah-patah
      _controller.animateTo(0.5, duration: const Duration(milliseconds: 200)); 
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 4,
          height: _animation.value, // Tinggi diset oleh nilai animasi secara real-time
          decoration: BoxDecoration(
            color: const Color(0xFF14192D),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }
}