import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/budget_donut_chart.dart';

/// Halaman Budget Saya — menampilkan rencana alokasi budget yang disimpan di Firestore.
/// Membaca dari users/{uid}.categories (bukan dari transaksi aktual).
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Budget Saya',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  color: AppColors.textDark, size: 20),
            ),
            onPressed: () => Get.back(),
          ),
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

                // Build donut segments
                final segments = categories.asMap().entries.map((e) {
                  final alokasi =
                      (e.value['alokasi'] ?? 0).toDouble();
                  return DonutSegment(
                    percentage:
                        budgetBulanan > 0 ? alokasi / budgetBulanan : 0,
                    color: segmentColors[e.key % segmentColors.length],
                  );
                }).toList();

                // Format angka singkat (Rp 1,5jt)
                String formatSingkat(double val) {
                  if (val == 0) return 'Rp 0';
                  if (val >= 1000000) {
                    return 'Rp ${(val / 1000000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')}jt';
                  }
                  if (val >= 1000) {
                    return 'Rp ${(val / 1000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')}k';
                  }
                  return currencyFmt.format(val);
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
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              BudgetDonutChart(
                                size: 180,
                                totalText: formatSingkat(budgetBulanan),
                                segments: segments,
                              ),
                              const SizedBox(height: 28),
                              // Legend
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: categories.asMap().entries.map((e) {
                                  final nama = e.value['nama'] as String? ?? '';
                                  final pct = (e.value['persentase'] ?? 0).toInt();
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

                        const SizedBox(height: 24),

                        // 2. Rincian Budget Bulanan
                        _buildRincianCard(
                          title: 'Rincian Budget Bulanan',
                          count: categories.length,
                          children: categories.asMap().entries.map((e) {
                            final nama = e.value['nama'] as String? ?? '';
                            final alokasi = (e.value['alokasi'] ?? 0).toDouble();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildDetailRow(
                                kategori: nama,
                                index: e.key,
                                amount: currencyFmt.format(alokasi),
                                segmentColors: segmentColors,
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildDetailRow(
                                kategori: nama,
                                index: e.key,
                                amount: currencyFmt.format(harian),
                                segmentColors: segmentColors,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
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
            color: Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _iconForKategori(String k) {
    final key = k.toLowerCase();
    if (key.contains('makan') || key.contains('minum')) {
      return Icons.fastfood_outlined;
    }
    if (key.contains('transport')) return Icons.directions_bus_outlined;
    if (key.contains('tabung')) return Icons.savings_outlined;
    if (key.contains('hibur')) return Icons.movie_outlined;
    return Icons.label_outline;
  }

  Color _iconBgFor(int i) {
    const bgs = [
      Color(0xFFFFEAE0),
      Color(0xFFDCF3FB),
      Color(0xFFE9F8C6),
      Color(0xFFF0E5FA),
      Color(0xFFFFE4EE),
    ];
    return bgs[i % bgs.length];
  }

  Widget _buildDetailRow({
    required String kategori,
    required int index,
    required String amount,
    required List<Color> segmentColors,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _iconBgFor(index),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _iconForKategori(kategori),
            color: segmentColors[index % segmentColors.length],
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
