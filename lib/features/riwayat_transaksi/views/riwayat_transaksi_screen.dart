import 'package:flutter/material.dart';
import 'package:get/get.dart';


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
                  color: Colors.black.withValues(alpha: 0.04), // Replaced withValues for backward compatibility
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.textDark, size: 20),
    );
  }


  Widget _buildTransactionTile(TransactionModel tx) {
    final isIncome = tx.type == 'income';
    final catIcon = AppHelpers.getCategoryIcon(tx.kategori, tx.title);
    final catColor = AppHelpers.getCategoryColor(tx.kategori, tx.title);

    return GestureDetector(
      onTap: () => _showTransactionOptions(context, tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                backgroundColor: catColor.withValues(alpha: 0.15),
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

  void _showTransactionOptions(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Judul
            Text(
              tx.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${tx.kategori} • ${AppHelpers.formatCurrency(tx.amount)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 24),
            // Tombol Edit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Get.toNamed('/add-tx', arguments: tx);
                },
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Edit Transaksi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDCE775),
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Tombol Hapus
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Get.defaultDialog(
                    title: 'Hapus Transaksi?',
                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    middleText: 'Transaksi "${tx.title}" akan dihapus permanen.',
                    textConfirm: 'Hapus',
                    textCancel: 'Batal',
                    confirmTextColor: Colors.white,
                    buttonColor: const Color(0xFFFF697A),
                    cancelTextColor: Colors.grey,
                    onConfirm: () {
                      txController.deleteTransaction(tx);
                      Get.back();
                      Get.snackbar(
                        'Berhasil',
                        'Transaksi berhasil dihapus',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF4CAF50),
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Hapus Transaksi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF697A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
