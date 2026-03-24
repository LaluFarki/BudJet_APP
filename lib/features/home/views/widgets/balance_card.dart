import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transaction/controllers/transaction_controller.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({Key? key}) : super(key: key);

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
          const Text(
            'Saldo Saya',
            style: TextStyle(color: AppColors.textDark, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                final txCtrl = Get.find<TransactionController>();
                // Menampilkan saldo realtime (contoh format: Rp425000), bisa diformat lebih rapi nanti
                return Text(
                  'Rp${txCtrl.userBalance.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility, color: AppColors.textDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
