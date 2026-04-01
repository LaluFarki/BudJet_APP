import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../controllers/transaction_controller.dart';

class TodayTransactionsScreen extends StatelessWidget {
  const TodayTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Riwayat Hari Ini', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final txController = Get.find<TransactionController>();
        final todayTxs = txController.todayTransactions;

        if (todayTxs.isEmpty) {
          return const Center(
            child: Text('Belum ada transaksi hari ini.', style: TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic)),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: todayTxs.length,
          itemBuilder: (context, index) {
            final tx = todayTxs[index];
            final isIncome = tx.type == 'income';
            final catIcon = AppHelpers.getCategoryIcon(tx.kategori, tx.title);
            final catColor = AppHelpers.getCategoryColor(tx.kategori, tx.title);

            return Slidable(
              key: ValueKey(tx.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      Get.toNamed('/add-tx', arguments: tx);
                    },
                    backgroundColor: const Color(0xFFDCE775),
                    foregroundColor: AppColors.textDark,
                    icon: Icons.edit_outlined,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      txController.deleteTransaction(tx);
                    },
                    backgroundColor: const Color(0xFFFF697A),
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      catIcon,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(tx.kategori, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    isIncome ? '+ ${AppHelpers.formatCurrency(tx.amount)}' : '- ${AppHelpers.formatCurrency(tx.amount)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isIncome ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ),
          );
        },
        );
      }),
    );
  }
}
