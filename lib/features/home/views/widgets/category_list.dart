import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transaction/controllers/transaction_controller.dart';
import '../../../../core/utils/app_helpers.dart';

class CategoryListWidget extends StatelessWidget {
  const CategoryListWidget({super.key});

  // ──────────────────────────────────────────
  // Icon & Warna: SAMA PERSIS antar halaman via AppHelpers
  // ──────────────────────────────────────────
  static IconData _getIcon(String kategori) {
    return AppHelpers.getCategoryIcon(kategori);
  }

  static Color _getColor(String kategori, [int index = 0]) {
    return AppHelpers.getCategoryColor(kategori, index);
  }

  static Color _getColorBg(String kategori, [int index = 0]) {
    return AppHelpers.getCategoryColorBg(kategori, index);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100);
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final categoriesRaw = data['categories'] as List<dynamic>? ?? [];
        if (categoriesRaw.isEmpty) return const SizedBox();

        // Parse & sort berdasarkan alokasi terbesar
        final categories = categoriesRaw
            .map((e) => e as Map<String, dynamic>)
            .toList()
          ..sort((a, b) =>
              ((b['alokasi'] ?? 0) as num).compareTo((a['alokasi'] ?? 0) as num));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row: "Budget Saya" + "Kategori Budget" + "Lihat Semua" ──
            Row(
              children: [
                const Text(
                  "Budget Saya",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Kategori Budget",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed('/budget'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Lainnya",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Row: Tombol Budget Saya (Fixed) | Divider | Kategori (Scrollable) ──
            SizedBox(
              height: 90,
              child: Row(
                children: [
                  // ── Tombol Budget Saya (Fixed di kiri) ──
                  GestureDetector(
                    onTap: () => Get.toNamed('/budget'),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDCE775).withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDCE775).withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE4F8E4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.payments_outlined, color: Color(0xFF70C94B), size: 22),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Budget',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Pembatas Vertikal | ──
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 1.5,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  // ── Kategori (Scrollable) ──
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.hardEdge,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final nama = cat['nama'] as String? ?? '';
                        final catColor = _getColor(nama, index);
                        final catIcon = _getIcon(nama);
                        final catBg = _getColorBg(nama, index);

                        return GestureDetector(
                          onTap: () => _showCategoryPopup(
                            context,
                            cat: cat,
                            currencyFmt: currencyFmt,
                          ),
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: catColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: catColor.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: catBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(catIcon, color: catColor, size: 22),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  nama,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // Pop-up saat kategori di-klik
  // Menampilkan: Sisa Bulan Ini, Sisa Hari Ini, Tombol Edit
  // ──────────────────────────────────────────
  void _showCategoryPopup(
    BuildContext context, {
    required Map<String, dynamic> cat,
    required NumberFormat currencyFmt,
  }) {
    final txCtrl = Get.find<TransactionController>();
    final nama = cat['nama'] as String? ?? '';
    final alokasi = (cat['alokasi'] ?? 0).toDouble();
    final harian = (cat['harian'] ?? (alokasi / 30)).toDouble();
    final now = DateTime.now();

    // Helper: cek apakah kategori transaksi cocok dengan nama budget
    // Mendukung nama berbeda (misal "Makanan & Minuman" vs "Makan & Minum")
    bool matchKategori(String txKategori) {
      final txLower = txKategori.toLowerCase();
      final namaLower = nama.toLowerCase();
      // Exact match
      if (txLower == namaLower) return true;
      // Contains match ("makan" ada di kedua versi)
      final keywords = namaLower.split(RegExp(r'[\s&]+'));
      for (final kw in keywords) {
        if (kw.length >= 3 && txLower.contains(kw)) return true;
      }
      return false;
    }

    // Expense bulan ini untuk kategori ini
    final usedBulan = txCtrl.transactions
        .where((tx) =>
            tx.type == 'expense' &&
            matchKategori(tx.kategori) &&
            tx.date.year == now.year &&
            tx.date.month == now.month)
        .fold(0.0, (total, item) => total + item.amount);

    final usedHari = txCtrl.transactions
        .where((tx) =>
            tx.type == 'expense' &&
            matchKategori(tx.kategori) &&
            tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day)
        .fold(0.0, (total, item) => total + item.amount);

    final sisaBulan = alokasi - usedBulan;
    final sisaHari = harian - usedHari;
    
    // Temukan index asli untuk konsistensi warna (opsional, tapi lebih baik pakai keyword match)
    final catIndex = txCtrl.transactions.indexWhere((tx) => matchKategori(tx.kategori));
    final catColor = _getColor(nama, catIndex != -1 ? catIndex : 0);
    final catIcon = _getIcon(nama);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header icon + nama
              CircleAvatar(
                radius: 28,
                backgroundColor: catColor.withValues(alpha: 0.15),
                child: Icon(catIcon, color: catColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                nama,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Alokasi: ${currencyFmt.format(alokasi)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // Sisa Bulan Ini
              _infoRow(
                label: 'Sisa Bulan Ini',
                value: currencyFmt.format(sisaBulan < 0 ? 0 : sisaBulan),
                valueColor: sisaBulan < 0 ? Colors.red : const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 10),
              // Sisa Hari Ini
              _infoRow(
                label: 'Sisa Hari Ini',
                value: currencyFmt.format(sisaHari < 0 ? 0 : sisaHari),
                valueColor: sisaHari < 0 ? Colors.red : const Color(0xFF2196F3),
              ),

              const SizedBox(height: 24),

              // Tombol Edit Budget
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Get.toNamed('/edit-budget');
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Budget'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
