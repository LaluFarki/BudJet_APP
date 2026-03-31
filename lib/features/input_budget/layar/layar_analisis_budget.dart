import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../budget/views/widgets/budget_donut_chart.dart';

/// Layar 3 dari 3 (onboarding): Analisis & konfirmasi pembagian budget.
/// Menerima data dari LayarBudgetKategori dan menampilkan:
/// - Donut chart persentase per kategori
/// - Rincian Budget Bulanan per kategori
/// - Rincian Budget Harian (alokasi / 30)
///
/// Tombol "Simpan" menyimpan semua data ke Firestore dan mengarahkan ke Home.
class LayarAnalisisBudget extends StatefulWidget {
  final double budgetBulanan;
  final double budgetHarian;
  final DateTime bulan;
  final List<String> kategoriList;
  final Map<String, double> allocations; // {namaKategori: nominal}

  const LayarAnalisisBudget({
    super.key,
    required this.budgetBulanan,
    required this.budgetHarian,
    required this.bulan,
    required this.kategoriList,
    required this.allocations,
  });

  @override
  State<LayarAnalisisBudget> createState() => _LayarAnalisisBudgetState();
}

class _LayarAnalisisBudgetState extends State<LayarAnalisisBudget> {
  bool _isSaving = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Mapping warna per kategori
  static const List<Color> _segmentColors = [
    Color(0xFFFF7B33), // Orange - Makanan
    Color(0xFF1D9CCB), // Biru - Transport
    Color(0xFFBCE037), // Hijau lime - Tabungan
    Color(0xFFAB6AEA), // Ungu - Hiburan
    Color(0xFFFC5A8D), // Pink - Custom
  ];

  Color _colorForIndex(int i) => _segmentColors[i % _segmentColors.length];

  IconData _iconForKategori(String k) {
    final key = k.toLowerCase();
    if (key.contains('makan') || key.contains('minum')) return Icons.fastfood_outlined;
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

  String _formatSingkat(double val) {
    if (val == 0) return 'Rp 0';
    if (val >= 1000000) {
      return 'Rp ${(val / 1000000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')}jt';
    }
    if (val >= 1000) {
      return 'Rp ${(val / 1000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')}k';
    }
    return _currencyFormat.format(val);
  }

  Future<void> _simpan() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User belum login');

      // Susun data kategori dengan persentase & budget harian
      final List<Map<String, dynamic>> categories = [];
      for (final nama in widget.kategoriList) {
        final alokasi = widget.allocations[nama] ?? 0;
        categories.add({
          'nama': nama,
          'alokasi': alokasi,
          'persentase': widget.budgetBulanan > 0
              ? (alokasi / widget.budgetBulanan * 100).roundToDouble()
              : 0.0,
          'harian': (alokasi / 30).roundToDouble(),
        });
      }

      // Simpan ke Firestore — satu dokumen di users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'budgetBulanan': widget.budgetBulanan,
        'budgetHarian': widget.budgetHarian,
        'bulan': widget.bulan.toIso8601String(),
        'categories': categories,
        'selectedCategories': widget.kategoriList,
        'allocations': widget.allocations,
        'balance': widget.budgetBulanan, // ← Saldo awal = total budget bulanan
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Tandai onboarding selesai
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOnboardingDone', true);

      if (!mounted) return;

      // Navigasi ke Dashboard, hapus semua route sebelumnya
      Get.offAllNamed('/');
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kategoriList = widget.kategoriList;
    final totalBudget = widget.budgetBulanan;

    // Build donut segments dari data alokasi
    final List<DonutSegment> segments = totalBudget > 0
        ? kategoriList.asMap().entries.map((e) {
            final alokasi = widget.allocations[e.value] ?? 0;
            return DonutSegment(
              percentage: alokasi / totalBudget,
              color: _colorForIndex(e.key),
            );
          }).toList()
        : [const DonutSegment(percentage: 1.0, color: Color(0xFFF0F0F0))];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Pembagian Budget',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E), size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (s) {
          s.disallowIndicator();
          return true;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── 1. Kartu Donut Chart ──
              _buildCard(
                child: Column(
                  children: [
                    BudgetDonutChart(
                      size: 180,
                      totalText: _formatSingkat(totalBudget),
                      segments: segments,
                    ),
                    const SizedBox(height: 28),
                    // Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: kategoriList.asMap().entries.map((e) {
                        final alokasi = widget.allocations[e.value] ?? 0;
                        final pct = totalBudget > 0
                            ? (alokasi / totalBudget * 100).round()
                            : 0;
                        return _buildLegend(
                          color: _colorForIndex(e.key),
                          title: e.value.toUpperCase(),
                          value: '$pct%',
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 2. Rincian Budget Bulanan ──
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Rincian Budget Bulanan', kategoriList.length),
                    const SizedBox(height: 20),
                    ...kategoriList.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildDetailRow(
                            icon: _iconForKategori(e.value),
                            iconBg: _iconBgFor(e.key),
                            iconColor: _colorForIndex(e.key),
                            title: e.value,
                            amount: _currencyFormat.format(widget.allocations[e.value] ?? 0),
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 3. Rincian Budget Harian ──
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Rincian Budget Harian', kategoriList.length),
                    const SizedBox(height: 20),
                    ...kategoriList.asMap().entries.map((e) {
                      final harian = ((widget.allocations[e.value] ?? 0) / 30);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDetailRow(
                          icon: _iconForKategori(e.value),
                          iconBg: _iconBgFor(e.key),
                          iconColor: _colorForIndex(e.key),
                          title: e.value,
                          amount: _currencyFormat.format(harian),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Footer ──
              const Text(
                'Sudah Cocok?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 14),

              // ── Tombol Simpan ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4E858),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            color: Color(0xFF1E1E1E),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }
}
