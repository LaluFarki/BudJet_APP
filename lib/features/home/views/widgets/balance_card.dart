import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transaction/controllers/transaction_controller.dart';
import '../../../transaction/models/transaction_model.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({Key? key}) : super(key: key);

  void _showAddIncomeDialog(BuildContext context, TransactionController txCtrl) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController sourceController = TextEditingController(text: 'Top-Up Saldo');
    // State mode koreksi via Obx
    final RxBool isCorrectionMode = false.obs;

    Get.defaultDialog(
      title: 'Tambah / Koreksi Saldo',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Switch Mode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mode Koreksi Aktual?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Switch(
                  value: isCorrectionMode.value,
                  onChanged: (val) => isCorrectionMode.value = val,
                  activeColor: AppColors.primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isCorrectionMode.value 
                  ? 'Ketik total saldo fisik Anda saat ini. Sistem otomatis menghitung selisih transaksinya.'
                  : 'Ketik nominal pemasukan yang direkam sebagai Saldo Masuk.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sourceController,
              decoration: const InputDecoration(
                labelText: 'Keterangan Sumber',
                hintText: 'Misal: Gaji, Jualan, Tabungan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        )),
      ),
      textConfirm: 'Simpan',
      textCancel: 'Batal',
      confirmTextColor: Colors.black,
      buttonColor: const Color(0xFFDCE775),
      cancelTextColor: Colors.grey,
      onConfirm: () async {
        final cleanText = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final inputAmount = double.tryParse(cleanText);

        if (inputAmount == null) {
          Get.snackbar('Kesalahan', 'Silakan masukkan angka valid', snackPosition: SnackPosition.BOTTOM);
          return;
        }

        double finalAmount = inputAmount;
        String type = 'income';
        String title = sourceController.text.isEmpty ? 'Top-Up Saldo' : sourceController.text;

        if (isCorrectionMode.value) {
          final currentBalance = txCtrl.userBalance.value;
          final diff = inputAmount - currentBalance;
          if (diff == 0) {
             Get.back(); // Tidak ada perubahan rill
             return;
          } else if (diff > 0) {
             finalAmount = diff;
             type = 'income';
             title = '$title (Koreksi Naik)';
          } else {
             finalAmount = diff.abs();
             type = 'expense';
             title = '$title (Koreksi Turun)';
          }
        } 

        final newTx = TransactionModel(
          id: '',
          title: title,
          kategori: 'Lainnya',
          amount: finalAmount,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          note: '',
          type: type,
        );

        Get.back(); // Tutup dialog
        await txCtrl.addTransaction(newTx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Saya',
                style: TextStyle(color: AppColors.textDark, fontSize: 14),
              ),
              // Tombol Tambah Pemasukan (+)
              GestureDetector(
                onTap: () {
                  final txCtrl = Get.find<TransactionController>();
                  _showAddIncomeDialog(context, txCtrl);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.add, size: 16, color: AppColors.textDark),
                      SizedBox(width: 4),
                      Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                final txCtrl = Get.find<TransactionController>();
                // Cek state mata / hide
                if (!txCtrl.isBalanceVisible.value) {
                  return const Text(
                    'Rp ********',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                return Text(
                  'Rp${txCtrl.userBalance.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
              // Tombol Mata (Hide/Show)
              GestureDetector(
                onTap: () {
                  final txCtrl = Get.find<TransactionController>();
                  txCtrl.isBalanceVisible.value = !txCtrl.isBalanceVisible.value;
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Obx(() {
                    final txCtrl = Get.find<TransactionController>();
                    return Icon(
                      txCtrl.isBalanceVisible.value ? Icons.visibility : Icons.visibility_off, 
                      color: AppColors.textDark
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
