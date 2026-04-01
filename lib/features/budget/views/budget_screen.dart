import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../transaction/controllers/transaction_controller.dart';
import 'widgets/budget_donut_chart.dart';

/// Halaman Budget Saya — menampilkan rencana alokasi budget yang disimpan di Firestore.
/// Membaca dari users/{uid}.categories (bukan dari transaksi aktual).
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final txCtrl = Get.find<TransactionController>();

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Helper: flexible matching antara nama kategori budget & kategori transaksi
    // Misal "Makan & Minum" cocok dengan "Makanan & Minuman"
    bool matchKategori(String txKategori, String budgetKat) {
      final txLower = txKategori.toLowerCase();
      final katLower = budgetKat.toLowerCase();
      if (txLower == katLower) return true;
      final keywords = katLower.split(RegExp(r'[\s&]+'));
      for (final kw in keywords) {
        if (kw.length >= 3 && txLower.contains(kw)) return true;
      }
      return false;
    }

    double expenseBulanan(String kat) {
      final now = DateTime.now();
      return txCtrl.transactions
          .where((tx) => tx.type == 'expense' && matchKategori(tx.kategori, kat) && tx.date.year == now.year && tx.date.month == now.month)
          .fold(0.0, (total, item) => total + item.amount);
    }

    double expenseHarian(String kat) {
      final now = DateTime.now();
      return txCtrl.transactions
          .where((tx) => tx.type == 'expense' && matchKategori(tx.kategori, kat) && tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day)
          .fold(0.0, (total, item) => total + item.amount);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Budget Saya',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: 22),
          onPressed: () => Get.back(),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Belum login'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildEmpty();
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                // Ambil data budget dari Firestore
                final double budgetBulanan =
                    (data['budgetBulanan'] ?? 0).toDouble();
                final List<dynamic> categoriesRaw = data['categories'] ?? [];

                // Parse daftar kategori
                final categories = categoriesRaw
                    .map((c) => c as Map<String, dynamic>)
                    .toList();

                if (categories.isEmpty || budgetBulanan == 0) {
                  return _buildEmpty();
                }

                // Warna per kategori (urutan)
                const segmentColors = [
                  Color(0xFFFF7B33),
                  Color(0xFF1D9CCB),
                  Color(0xFFBCE037),
                  Color(0xFFAB6AEA),
                  Color(0xFFFC5A8D),
                ];

                // Format angka donut chart: selalu tampilkan 1 angka di belakang koma
                String formatDonut(double val) {
                  if (val == 0) return 'Rp 0';
                  if (val >= 1000000) {
                    return 'Rp ${(val / 1000000).toStringAsFixed(1).replaceAll('.', ',')}jt';
                  }
                  return currencyFmt.format(val);
                }

                // Format K untuk rincian: 200K, 1,8jt, dsb
                String formatK(double val) {
                  if (val == 0) return '0';
                  if (val >= 1000000) {
                    return '${(val / 1000000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')}jt';
                  }
                  if (val >= 1000) {
                    final k = val / 1000;
                    if (k == k.roundToDouble()) {
                      return '${k.toInt()}K';
                    }
                    return '${k.toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')}K';
                  }
                  return val.toInt().toString();
                }

                // Gunakan Obx agar SELURUH tampilan reaktif terhadap perubahan transaksi
                return Obx(() {
                  final double expensesTotal = txCtrl.transactions
                      .where((t) => t.type == 'expense' && t.date.year == DateTime.now().year && t.date.month == DateTime.now().month)
                      .fold(0.0, (s, i) => s + i.amount);

                  final double sisaTotalBulanan = budgetBulanan - expensesTotal;
                  final double sisaDisplay = sisaTotalBulanan < 0 ? 0.0 : sisaTotalBulanan;

                  // Build donut segments based on REMAINING amount
                  final segments = categories.asMap().entries.map((e) {
                    final nama = e.value['nama'] as String? ?? '';
                    final alokasi = (e.value['alokasi'] ?? 0).toDouble();
                    final used = expenseBulanan(nama);
                    final sisaKategori = (alokasi - used) < 0 ? 0.0 : (alokasi - used);

                    return DonutSegment(
                      percentage:
                          sisaDisplay > 0 ? sisaKategori / sisaDisplay : 0,
                      color: segmentColors[e.key % segmentColors.length],
                    );
                  }).toList();
                  
                  // If sisa is 0, provide a blank segment
                  if (sisaDisplay <= 0) {
                    segments.add(const DonutSegment(percentage: 1.0, color: Color(0xFFF0F0F0)));
                  }

                  return NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (s) {
                    s.disallowIndicator();
                    return true;
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // 1. Kartu Donut Chart
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                children: [
                                  BudgetDonutChart(
                                    size: 180,
                                    totalText: formatDonut(sisaDisplay),
                                    segments: segments.where((s) => s.color != const Color(0xFFF0F0F0)).toList(),
                                  ),
                                  const SizedBox(height: 28),
                                  // Legend
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: categories.asMap().entries.map((e) {
                                      final nama = e.value['nama'] as String? ?? '';
                                      final alokasi = (e.value['alokasi'] ?? 0).toDouble();
                                      final used = expenseBulanan(nama);
                                      final sisaKategori = (alokasi - used) < 0 ? 0.0 : (alokasi - used);
                                      
                                      final pct = sisaDisplay > 0 ? (sisaKategori / sisaDisplay * 100).round() : 0;
                                      return _buildLegend(
                                        color: segmentColors[e.key % segmentColors.length],
                                        title: nama.toUpperCase(),
                                        value: '$pct%',
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () => Get.toNamed('/edit-budget'),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.edit_outlined, size: 22, color: AppColors.textDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 2. Rincian Budget Bulanan
                        _buildRincianCard(
                          title: 'Rincian Budget Bulanan',
                          count: categories.length,
                          children: categories.asMap().entries.map((e) {
                            final nama = e.value['nama'] as String? ?? '';
                            final alokasi = (e.value['alokasi'] ?? 0).toDouble();
                            final used = expenseBulanan(nama);
                            final sisa = alokasi - used;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildDetailRow(
                                kategori: nama,
                                index: e.key,
                                amount: '${formatK(sisa)} / ${formatK(alokasi)}',
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // 3. Rincian Budget Harian
                        _buildRincianCard(
                          title: 'Rincian Budget Harian',
                          count: categories.length,
                          children: categories.asMap().entries.map((e) {
                            final nama = e.value['nama'] as String? ?? '';
                            final harian = (e.value['harian'] ??
                                    (e.value['alokasi'] ?? 0) / 30)
                                .toDouble();
                            final used = expenseHarian(nama);
                            final sisa = harian - used;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildDetailRow(
                                kategori: nama,
                                index: e.key,
                                amount: '${formatK(sisa)} / ${formatK(harian)}',
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
                }); // <== Penutup Obx
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada data budget.\nSelesaikan pengaturan awal terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildRincianCard({
    required String title,
    required int count,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count Item',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLegend({
    required Color color,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey, // Grey
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E1E1E), // textDark
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _iconForKategori(String k) {
    return AppHelpers.getCategoryIcon(k);
  }

  Color _iconBgFor(int i, String name) {
    return AppHelpers.getCategoryColorBg(name, i);
  }

  Widget _buildDetailRow({
    required String kategori,
    required int index,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _iconBgFor(index, kategori),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _iconForKategori(kategori),
            color: AppHelpers.getCategoryColor(kategori, index),
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            kategori,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
