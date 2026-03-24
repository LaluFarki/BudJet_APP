import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/transaction_model.dart';
import '../controllers/transaction_controller.dart';

class SuccessTransactionScreen extends StatelessWidget {
  const SuccessTransactionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mengambil data transaksi yang dikirim via Get.arguments
    final TransactionModel tx = Get.arguments as TransactionModel;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Ikon Centang Berhasil
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE775), // Lime green modern
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDCE775).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 70,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Teks Berhasil
              const Center(
                child: Text(
                  'Berhasil Disimpan!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Subteks
              Center(
                child: Text(
                  tx.type == 'expense' 
                      ? 'Pengeluaran Anda telah tercatat.'
                      : 'Pemasukan Anda telah tercatat.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Kotak Struk (Receipt)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.04),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Baris Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Rp ${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Garis Putus-putus
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: List.generate(
                            (constraints.constrainWidth() / 10).floor(),
                            (index) => SizedBox(
                              width: 5,
                              height: 1.5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Baris Kategori
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kategori', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text(tx.kategori, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    // Baris Tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tanggal', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(tx.date), 
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Garis Pemisah (Solid)
                    Divider(color: Colors.grey.withOpacity(0.15), thickness: 1.5),
                    const SizedBox(height: 20),
                    
                    // Baris Sisa Saldo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sisa Saldo', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        Obx(() {
                          // Karena saldo Reactive, ia akan menampilkan saldo terbaru yg sudah dipotong di fitur Tambah
                          final txCtrl = Get.find<TransactionController>();
                          return Text(
                            'Rp ${txCtrl.userBalance.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.textDark,
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              // Tombol Keluar (Lime Green sama dengan kotak desain)
              ElevatedButton(
                onPressed: () => Get.offAllNamed('/'), // Menutup semua screen transisi dan kembali bersih ke Home
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDCE775), // Lime/Light Green
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Sangat bulat melengkung (Pill shape)
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Keluar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
