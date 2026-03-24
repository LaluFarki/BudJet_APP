import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../transaction/controllers/transaction_controller.dart';
import '../../transaction/models/transaction_model.dart';


class RiwayatTransaksiScreen extends StatefulWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  State<RiwayatTransaksiScreen> createState() => _RiwayatTransaksiScreenState();
}

class _RiwayatTransaksiScreenState extends State<RiwayatTransaksiScreen> {
  final TransactionController txController = Get.find<TransactionController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Map<String, List<TransactionModel>> _groupTransactions(List<TransactionModel> txs) {
    if (txs.isEmpty) return {};

    final grouped = <String, List<TransactionModel>>{};
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var tx in txs) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;

      if (txDate == today) {
        label = 'Hari Ini';
      } else if (txDate == yesterday) {
        label = 'Kemarin';
      } else {
        label = _formatDate(txDate);
      }

      if (!grouped.containsKey(label)) {
        grouped[label] = [];
      }
      grouped[label]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Get.back(), // Get.back instead of Navigator.pop
        ),
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildBalanceCard(),
              const SizedBox(height: 24),
              
              // Dynamic Transaction List
              Obx(() {
                List<TransactionModel> txs = txController.transactions.toList();
                
                // Search Logic
                if (_searchQuery.value.isNotEmpty) {
                  final q = _searchQuery.value.toLowerCase();
                  txs = txs.where((t) => 
                    t.title.toLowerCase().contains(q) || 
                    t.kategori.toLowerCase().contains(q)
                  ).toList();
                }

                if (txs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('Tidak ada transaksi ditemukan', 
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
                      ),
                    ),
                  );
                }

                // Group and Render
                final grouped = _groupTransactions(txs);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: grouped.entries.map((entry) {
                    final label = entry.key;
                    final txList = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 4),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ...txList.map((t) => _buildTransactionTile(t)),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), // Replaced withValues for backward compatibility
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: AppColors.textGrey, size: 20),
                hintText: 'Cari transaksi...',
                hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildIconButton(Icons.tune),
        const SizedBox(width: 8),
        _buildIconButton(Icons.calendar_month_outlined),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.textDark, size: 20),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Saya',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Obx(() {
            return Text(
              AppHelpers.formatCurrency(txController.userBalance.value),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: catColor.withOpacity(0.15),
                child: Icon(
                  catIcon,
                  color: catColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.kategori,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isIncome
                    ? '+ ${AppHelpers.formatCurrency(tx.amount)}'
                    : '- ${AppHelpers.formatCurrency(tx.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
