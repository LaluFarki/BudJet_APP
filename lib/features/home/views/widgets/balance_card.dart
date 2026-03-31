import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../../transaction/controllers/transaction_controller.dart';
import '../../../transaction/models/transaction_model.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  void _showAddIncomeDialog(BuildContext context, TransactionController txCtrl) {
    final TextEditingController amountController = TextEditingController();

    Get.defaultDialog(
      title: 'Tambah Budget',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nominal ini akan ditambahkan ke budget bulanan Anda.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
          ],
        ),
      ),
      textConfirm: 'Simpan',
      textCancel: 'Batal',
      confirmTextColor: Colors.black,
      buttonColor: const Color(0xFFDCE775),
      cancelTextColor: Colors.grey,
      onConfirm: () async {
        final cleanText = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final inputAmount = double.tryParse(cleanText);

        if (inputAmount == null || inputAmount <= 0) {
          Get.snackbar('Kesalahan', 'Silakan masukkan angka valid', snackPosition: SnackPosition.BOTTOM);
          return;
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        try {
          // Tambahkan transaksi baru bertipe 'income' untuk mencatat di riwayat
          await txCtrl.addTransaction(
            TransactionModel(
              id: '', // Diabaikan oleh Firestore addTransaction
              amount: inputAmount,
              createdAt: DateTime.now(),
              date: DateTime.now(),
              kategori: 'Top Up',
              note: 'Tambah Saldo dari Home',
              title: 'Tambah Saldo',
              type: 'income',
            ),
          );

          Get.back();
          Get.snackbar('Berhasil', 'Budget ditambahkan ${AppHelpers.formatCurrency(inputAmount)}', snackPosition: SnackPosition.BOTTOM);
        } catch (e) {
          Get.snackbar('Gagal', 'Terjadi kesalahan: $e', snackPosition: SnackPosition.BOTTOM);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: uid != null
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        // Ambil budgetBulanan dari Firestore (data budget user)
        double budgetBulanan = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          budgetBulanan = (data['budgetBulanan'] ?? 0).toDouble();
        }

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
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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

                    // Saldo = budgetBulanan - total pengeluaran bulan ini
                    final sisa = budgetBulanan - txCtrl.totalExpense;
                    return Text(
                      AppHelpers.formatCurrency(sisa < 0 ? 0 : sisa),
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
                        color: Colors.black.withValues(alpha: 0.1),
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
      },
    );
  }
}
