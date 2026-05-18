import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:budjet/features/algoritma_pembagian/smart_budget_model.dart';
import 'layar_analisis_budget.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../../../core/utils/validation_helper.dart';

class LayarBudgetKategori extends StatefulWidget {
  final double budgetBulanan;
  final DateTime bulan;
  final List<String> kategoriList;

  const LayarBudgetKategori({
    super.key,
    required this.budgetBulanan,
    required this.bulan,
    required this.kategoriList,
  });

  @override
  State<LayarBudgetKategori> createState() => _LayarBudgetKategoriState();
}

class _LayarBudgetKategoriState extends State<LayarBudgetKategori> {
  late List<TextEditingController> controllers;
  late List<String> periodeList;
  final Map<int, bool> _showNominalWarning = {};
  final Map<int, Timer?> _nominalWarningTimers = {};

  double get _budgetHarian {
    final jumlahHari = DateTime(
      widget.bulan.year,
      widget.bulan.month + 1,
      0,
    ).day;

    return widget.budgetBulanan / jumlahHari;
  }

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double get _totalDialokasikan {
    double total = 0;

    for (int i = 0; i < controllers.length; i++) {
      final nominal = _parseRupiah(controllers[i].text);

      total += nominal;
    }

    return total;
  }

  double get _sisaBelumDialokasikan =>
      widget.budgetBulanan - _totalDialokasikan;

  bool get _isOverBudget => _sisaBelumDialokasikan < 0;

  bool get _isAlokasiPas => _sisaBelumDialokasikan.abs() < 1;

  bool get _isValid => !_isOverBudget;

  @override
  void initState() {
    super.initState();

    controllers = List.generate(
      widget.kategoriList.length,
      (_) => TextEditingController(),
    );

    periodeList = List.generate(widget.kategoriList.length, (_) => 'Mingguan');

    for (final c in controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  double _parseRupiah(String text) {
    final angka = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(angka) ?? 0;
  }

  BudgetPeriod _periodFromString(String value) {
    switch (value) {
      case 'Harian':
        return BudgetPeriod.daily;
      case 'Mingguan':
        return BudgetPeriod.weekly;
      case 'Bulanan':
        return BudgetPeriod.monthly;
      default:
        return BudgetPeriod.monthly;
    }
  }

  // _formatRupiah dihapus karena menggunakan RupiahInputFormatter

  IconData _getIcon(String kategori) {
    return AppHelpers.getCategoryIcon(kategori);
  }

  Color _getColor(String kategori) {
    return AppHelpers.getCategoryColor(kategori);
  }

  Color _getColorBg(String kategori) {
    return AppHelpers.getCategoryColorBg(kategori);
  }

  void _lanjut() {
    final adaKosong = controllers.any((c) => _parseRupiah(c.text) <= 0);

    if (adaKosong) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Budget Belum Lengkap'),
          content: const Text(
            'Pastikan semua kategori sudah diisi nominal bulanannya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!_isValid) {
      _showValidationPopup();
      return;
    }

    if (_sisaBelumDialokasikan > 0) {
      _showSisaDanaConfirmation();
      return;
    }

    _goToAnalisisBudget();
  }

  void _goToAnalisisBudget() {
    final List<BudgetCategory> categories = [];

    for (int i = 0; i < widget.kategoriList.length; i++) {
      categories.add(
        BudgetCategory(
          id: widget.kategoriList[i],
          name: widget.kategoriList[i],
          amount: _parseRupiah(controllers[i].text),
          period: _periodFromString(periodeList[i]),
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LayarAnalisisBudget(
          budgetBulanan: widget.budgetBulanan,
          budgetHarian: _budgetHarian,
          bulan: widget.bulan,
          categories: categories,
        ),
      ),
    );
  }

  void _showSisaDanaConfirmation() {
    final sisa = _sisaBelumDialokasikan;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Saldo Masih Tersisa'),
          content: Text(
            'Masih ada ${_currencyFormat.format(sisa.toInt())} yang belum dialokasikan. '
            'Saldo ini akan otomatis dimasukkan ke kategori Sisa Dana.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cek Lagi'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _goToAnalisisBudget();
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  String _getPreviewPeriode(double nominalBulanan, String periode) {
    if (nominalBulanan == 0) return '';

    final totalBulanan = _currencyFormat.format(nominalBulanan.toInt());

    switch (periode) {
      case 'Harian':
        final harian = nominalBulanan / 30;
        return 'Dari $totalBulanan/bulan, kamu dapat menggunakan sekitar ${_currencyFormat.format(harian.toInt())} per hari.';

      case 'Mingguan':
        final mingguan = nominalBulanan / 4;
        return 'Dari $totalBulanan/bulan, kamu dapat menggunakan sekitar ${_currencyFormat.format(mingguan.toInt())} per minggu.';

      case 'Bulanan':
        return '$totalBulanan akan digunakan untuk 1 bulan penuh.';

      default:
        return '';
    }
  }

  void _showValidationPopup() {
    final sisa = _sisaBelumDialokasikan;
    final isOver = sisa < 0;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFE57373),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOver ? 'Budget Melebihi Batas' : 'Saldo Masih Tersisa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isOver
                      ? 'Total melebihi ${_currencyFormat.format(sisa.abs().toInt())}'
                      : 'Sisa ${_currencyFormat.format(sisa.toInt())}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sisa = _sisaBelumDialokasikan;
    final isOver = _isOverBudget;
    final isPas = _isAlokasiPas;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text(
                'Budget Kategori',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // 🔥 INDIKATOR SISA (FINAL)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _isValid
                      ? Colors.green.shade50
                      : isOver
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPas
                        ? Colors.green.shade50
                        : isOver
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPas
                          ? '✅ Alokasi sudah pas!'
                          : isOver
                          ? '⚠️ Melebihi budget'
                          : 'Sisa belum dialokasikan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isValid
                            ? Colors.green.shade700
                            : isOver
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      isPas
                          ? 'Rp 0'
                          : _currencyFormat.format(sisa.abs().toInt()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isValid
                            ? Colors.green.shade700
                            : isOver
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: widget.kategoriList.length,
                  itemBuilder: (context, index) {
                    final kategori = widget.kategoriList[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getColorBg(kategori),
                                child: Icon(
                                  _getIcon(kategori),
                                  color: _getColor(kategori),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                kategori,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(
                            height: (_showNominalWarning[index] ?? false)
                                ? 4
                                : 8,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masukkan budget bulanan untuk ${kategori.toLowerCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 6),
                              TextFormField(
                                controller: controllers[index],
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final amount = ValidationHelper.parseRupiah(
                                    value,
                                  );
                                  if (amount < 100000000 &&
                                      (_showNominalWarning[index] ?? false)) {
                                    setState(
                                      () => _showNominalWarning[index] = false,
                                    );
                                  }
                                },
                                inputFormatters: [
                                  RupiahInputFormatter(
                                    max: 100000000,
                                    onMaxExceeded: () {
                                      if (!(_showNominalWarning[index] ??
                                          false)) {
                                        _nominalWarningTimers[index]?.cancel();
                                        setState(
                                          () =>
                                              _showNominalWarning[index] = true,
                                        );
                                        _nominalWarningTimers[index] = Timer(
                                          const Duration(milliseconds: 2200),
                                          () {
                                            if (mounted)
                                              setState(
                                                () =>
                                                    _showNominalWarning[index] =
                                                        false,
                                              );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'Contoh: Rp 600.000',

                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),

                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FA),

                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),

                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),

                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD6E85A),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              if (_showNominalWarning[index] ?? false)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4, left: 12),
                                  child: Text(
                                    'Max Rp 100.000.000!',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          const SizedBox(height: 12),

                          const Text(
                            'Pilih periode penggunaan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: ['Harian', 'Mingguan', 'Bulanan'].map((
                                item,
                              ) {
                                final selected = periodeList[index] == item;

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        periodeList[index] = item;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFD6E85A)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selected
                                                ? Colors.black
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          Builder(
                            builder: (_) {
                              final nominal = _parseRupiah(
                                controllers[index].text,
                              );
                              final preview = _getPreviewPeriode(
                                nominal,
                                periodeList[index],
                              );
                              if (preview.isEmpty) return const SizedBox();

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  preview,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Sudah cocok?',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _lanjut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6E85A),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Lanjut →', style: TextStyle(fontSize: 22)),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
