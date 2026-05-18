import 'package:budjet/features/algoritma_pembagian/smart_budget_engine.dart';
import 'package:budjet/features/algoritma_pembagian/smart_budget_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../budget/views/widgets/budget_donut_chart.dart';
import '../../../../core/utils/app_helpers.dart';

class LayarAnalisisBudget extends StatefulWidget {
  final double budgetBulanan;
  final double budgetHarian;
  final DateTime bulan;
  final List<BudgetCategory> categories;

  const LayarAnalisisBudget({
    super.key,
    required this.budgetBulanan,
    required this.budgetHarian,
    required this.bulan,
    required this.categories,
  });

  @override
  State<LayarAnalisisBudget> createState() => _LayarAnalisisBudgetState();
}

class _LayarAnalisisBudgetState extends State<LayarAnalisisBudget> {
  bool _isSaving = false;
  final SmartBudgetEngine _engine = SmartBudgetEngine();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Color _colorForIndex(String k, int i) => AppHelpers.getCategoryColor(k, i);
  Color _iconBgFor(String k, int i) => AppHelpers.getCategoryColorBg(k, i);
  IconData _iconForKategori(String k) => AppHelpers.getCategoryIcon(k);

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

  String _periodSuffix(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return 'hari';
      case BudgetPeriod.weekly:
        return 'minggu';
      case BudgetPeriod.monthly:
        return 'bulan';
    }
  }

  double _amountPerPeriod(double monthlyAmount, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return monthlyAmount / 30;
      case BudgetPeriod.weekly:
        return monthlyAmount / 4;
      case BudgetPeriod.monthly:
        return monthlyAmount;
    }
  }

  Future<void> _simpan() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      var uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        uid = userCredential.user?.uid;
        if (uid == null) throw Exception('Gagal membuat sesi pengguna baru.');
      }

      final summary = _engine.calculateSummary(
        monthlyBudget: widget.budgetBulanan,
        categories: widget.categories,
        transactions: [],
      );

      // Susun data kategori untuk disimpan ke Firestore
      final List<Map<String, dynamic>> categories = summary.categories.map((c) {
        return {
          'id': c.categoryId,
          'nama': c.name,
          'periode': c.period.name,
          'alokasiInput': c.allocationAmount,
          'alokasiBulanan': c.monthlyEquivalent,
          'terpakai': c.spentAmount,
          'sisa': c.remainingAmount,
          'persentase': widget.budgetBulanan > 0
              ? (c.monthlyEquivalent / widget.budgetBulanan * 100)
                    .roundToDouble()
              : 0.0,
          'harian': (c.monthlyEquivalent / 30).roundToDouble(),
        };
      }).toList();

      // Simpan ke Firestore — HARUS await agar data ada saat home dibuka
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'budgetBulanan': widget.budgetBulanan,
        'budgetHarian': widget.budgetHarian,
        'bulan': widget.bulan.toIso8601String(),
        'categories': categories,
        'selectedCategories': widget.categories.map((c) => c.name).toList(),
        'allocations': {for (final c in widget.categories) c.name: c.amount},
        'balance': widget.budgetBulanan, // ← Saldo awal = total budget bulanan
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOnboardingDone', true);

      if (!mounted) return;
      Get.offAllNamed('/');
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = widget.budgetBulanan;

    final summary = _engine.calculateSummary(
      monthlyBudget: widget.budgetBulanan,
      categories: widget.categories,
      transactions: [],
    );

    final kategoriSummary = summary.categories;

    final List<DonutSegment> segments = totalBudget > 0
        ? kategoriSummary.asMap().entries.map((e) {
            final category = e.value;

            return DonutSegment(
              percentage: category.monthlyEquivalent / totalBudget,
              color: _colorForIndex(category.name, e.key),
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
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1E1E1E),
              size: 20,
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
              _buildCard(
                child: Column(
                  children: [
                    BudgetDonutChart(
                      size: 180,
                      totalText: _formatSingkat(totalBudget),
                      segments: segments,
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: kategoriSummary.asMap().entries.map((e) {
                        final category = e.value;
                        final pct = totalBudget > 0
                            ? (category.monthlyEquivalent / totalBudget * 100)
                                  .round()
                            : 0;

                        return _buildLegend(
                          color: _colorForIndex(category.name, e.key),
                          title: category.name.toUpperCase(),
                          value: '$pct%',
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Rincian Budget Bulanan',
                      kategoriSummary.length,
                    ),
                    const SizedBox(height: 20),
                    ...kategoriSummary.asMap().entries.map((e) {
                      final category = e.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDetailRow(
                          icon: _iconForKategori(category.name),
                          iconBg: _iconBgFor(category.name, e.key),
                          iconColor: _colorForIndex(category.name, e.key),
                          title: '${category.name}',
                          amount: _currencyFormat.format(
                            category.monthlyEquivalent,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Budget per Kategori (Sesuai Periode)',
                      kategoriSummary.length,
                    ),
                    const SizedBox(height: 20),
                    ...kategoriSummary.asMap().entries.map((e) {
                      final category = e.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDetailRow(
                          icon: _iconForKategori(category.name),
                          iconBg: _iconBgFor(category.name, e.key),
                          iconColor: _colorForIndex(category.name, e.key),
                          title: category.name,
                          amount:
                              '${_currencyFormat.format(_amountPerPeriod(category.monthlyEquivalent, category.period))}/${_periodSuffix(category.period)}',
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Sudah Cocok?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 14),

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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
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
            overflow: TextOverflow.ellipsis,
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
