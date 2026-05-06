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
  final Rxn<DateTimeRange> _dateRange = Rxn<DateTimeRange>();
  final RxString _selectedCategory = ''.obs;

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

                // Category Filter Logic
                if (_selectedCategory.value.isNotEmpty) {
                  txs = txs.where((t) => t.kategori == _selectedCategory.value).toList();
                }

                // Date Range Filter Logic
                if (_dateRange.value != null) {
                  final start = DateTime(_dateRange.value!.start.year, _dateRange.value!.start.month, _dateRange.value!.start.day);
                  final end = DateTime(_dateRange.value!.end.year, _dateRange.value!.end.month, _dateRange.value!.end.day, 23, 59, 59);
                  txs = txs.where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1))) && t.date.isBefore(end.add(const Duration(seconds: 1)))).toList();
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
        Obx(() => _buildIconButton(
          Icons.tune, 
          isActive: _selectedCategory.value.isNotEmpty,
          onTap: _selectCategory,
        )),
        const SizedBox(width: 8),
        Obx(() => _buildIconButton(
          Icons.calendar_month_outlined, 
          isActive: _dateRange.value != null,
          onTap: _selectDateRange,
        )),
      ],
    );
  }

  void _selectDateRange() {
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Pilih Periode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildQuickFilterOption('Hari Ini', () {
              final now = DateTime.now();
              _dateRange.value = DateTimeRange(start: now, end: now);
              Get.back();
            }, Icons.today),
            _buildQuickFilterOption('7 Hari Terakhir', () {
              final now = DateTime.now();
              _dateRange.value = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
              Get.back();
            }, Icons.date_range),
            _buildQuickFilterOption('Bulan Ini', () {
              final now = DateTime.now();
              _dateRange.value = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
              Get.back();
            }, Icons.calendar_month),
            _buildQuickFilterOption('Pilih Custom Tanggal', _showFullDatePicker, Icons.edit_calendar_outlined, isPrimary: true),
            if (_dateRange.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    _dateRange.value = null;
                    Get.back();
                  },
                  child: const Text('Reset Filter Tanggal', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullDatePicker() async {
    Get.back(); // Close bottom sheet
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: _dateRange.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF66BB6A),
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dateRange.value = picked;
    }
  }

  Widget _buildQuickFilterOption(String label, VoidCallback onTap, IconData icon, {bool isPrimary = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF66BB6A).withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isPrimary ? const Color(0xFF66BB6A) : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: isPrimary ? const Color(0xFF66BB6A) : AppColors.textGrey, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                  color: isPrimary ? const Color(0xFF66BB6A) : AppColors.textDark,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: isPrimary ? const Color(0xFF66BB6A) : Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCategory() {
    // Gabungkan kategori dari budget (userCategories) dan kategori dari transaksi (historical)
    final Set<String> allCategories = {};
    
    // Tambah dari budget settings
    allCategories.addAll(txController.userCategories);
    
    // Tambah dari transaksi yang sudah ada (untuk history)
    allCategories.addAll(txController.transactions.map((t) => t.kategori));
    
    final categories = allCategories.toList();
    categories.sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Filter Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildCategoryGridItem('Semua', '', Icons.all_inclusive),
                  ...categories.map((cat) => _buildCategoryGridItem(
                        cat,
                        cat,
                        AppHelpers.getCategoryIcon(cat),
                      )),
                ],
              ),
            ),
            if (_selectedCategory.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      _selectedCategory.value = '';
                      Get.back();
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Hapus Filter Kategori'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGridItem(String label, String value, IconData icon) {
    return Obx(() {
      final isSelected = _selectedCategory.value == value;
      return InkWell(
        onTap: () {
          _selectedCategory.value = value;
          Get.back();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF66BB6A).withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF66BB6A) : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF66BB6A) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? []
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textGrey,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF66BB6A) : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildIconButton(IconData icon, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF66BB6A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? const Color(0xFF66BB6A) : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: isActive ? Colors.white : AppColors.textDark, size: 20),
      ),
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
                  backgroundColor: const Color(0xFF66BB6A),
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
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: const Color(0xFF4CAF50),
                        colorText: Colors.white,
                        borderRadius: 12,
                        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
