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

  @override
  Widget build(BuildContext context) {
    final txCtrl = Get.find<TransactionController>();

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
          const Text(
            'Saldo Saya',
            style: TextStyle(color: AppColors.textDark, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
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
                // Saldo = budgetBulanan (Rx) - total pengeluaran (Rx)
                final sisa = txCtrl.budgetBulanan.value - txCtrl.totalExpense;
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
                  txCtrl.isBalanceVisible.value = !txCtrl.isBalanceVisible.value;
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Obx(() => Icon(
                    txCtrl.isBalanceVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.textDark,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
