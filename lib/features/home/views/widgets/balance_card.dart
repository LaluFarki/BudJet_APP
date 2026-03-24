import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transaction/controllers/transaction_controller.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({Key? key}) : super(key: key);

  void _showEditBalanceDialog(BuildContext context, TransactionController txCtrl) {
    final TextEditingController amountController = TextEditingController(
      text: txCtrl.userBalance.value.toStringAsFixed(0),
    );

    Get.defaultDialog(
      title: 'Edit Saldo Utama',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sisa Saldo Baru',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      textConfirm: 'Simpan',
      textCancel: 'Batal',
      confirmTextColor: Colors.black,
      buttonColor: const Color(0xFFDCE775), // Sesuai warna button aplikasi Anda
      cancelTextColor: Colors.grey,
      onConfirm: () {
        final cleanText = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final newBalance = double.tryParse(cleanText);
        if (newBalance != null) {
          txCtrl.updateBalance(newBalance);
        } else {
          Get.snackbar('Kesalahan', 'Silakan masukkan angka valid');
        }
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
              // Tombol Icon Edit Kecil
              GestureDetector(
                onTap: () {
                  final txCtrl = Get.find<TransactionController>();
                  _showEditBalanceDialog(context, txCtrl);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textDark),
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
