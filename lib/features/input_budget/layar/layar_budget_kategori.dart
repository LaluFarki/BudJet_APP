import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:budjet/features/algoritma_pembagian/smart_budget_engine.dart';
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

  final SmartBudgetEngine _engine = SmartBudgetEngine();

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
      final period = _periodFromString(periodeList[i]);

      total += _engine.convertToMonthly(nominal, period);
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

  void _formatRupiah(TextEditingController controller, String value) {
    // Hanya ambil angka
    final angka = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (angka.isEmpty) {
      controller.clear();
      return;
    }
    final formatted = _currencyFormat.format(int.parse(angka));
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

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

  String _getPreviewBulanan(double nominal, String periode) {
    int multiplier = 1;

    switch (periode) {
      case 'Harian':
        multiplier = 30;
        break;
      case 'Mingguan':
        multiplier = 4;
        break;
      case 'Bulanan':
        multiplier = 1;
        break;
    }

    final total = nominal * multiplier;

    if (nominal == 0) return '';

    return 'Alokasi 1 bulan = ${_currencyFormat.format(nominal.toInt())} × $multiplier = ${_currencyFormat.format(total.toInt())}';
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
                          const Text(
                            'Nominal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controllers[index],
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final amount = ValidationHelper.parseRupiah(value);
                              if (amount < 100000000 && (_showNominalWarning[index] ?? false)) {
                                setState(() => _showNominalWarning[index] = false);
                              }
                              _formatRupiah(controllers[index], value);
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                final amount = ValidationHelper.parseRupiah(newValue.text);
                                if (amount > 100000000) {
                                  if (!(_showNominalWarning[index] ?? false)) {
                                    _nominalWarningTimers[index]?.cancel();
                                    setState(() => _showNominalWarning[index] = true);
                                    _nominalWarningTimers[index] = Timer(const Duration(seconds: 3), () {
                                      if (mounted) setState(() => _showNominalWarning[index] = false);
                                    });
                                  }
                                  return const TextEditingValue(
                                    text: 'Rp 100.000.000',
                                    selection: TextSelection.collapsed(offset: 14),
                                  );
                                }
                                return newValue;
                              }),
                            ],
                            decoration: InputDecoration(
                              hintText:
                                  'Nominal per ${periodeList[index].toLowerCase()}',
                              helperText:
                                  'Jatah ${kategori.toLowerCase()} per ${periodeList[index].toLowerCase()}',
                              helperStyle: const TextStyle(fontSize: 12),
                              errorText: (_showNominalWarning[index] ?? false) ? 'Max Rp 100.000.000!' : null,
                              errorStyle: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                height: 0.8, // Naikkan posisi tanpa merusak box
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF1F3F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          // 👇 TAMBAHKAN DI SINI
                          Builder(
                            builder: (_) {
                              final nominal = _parseRupiah(
                                controllers[index].text,
                              );
                              final preview = _getPreviewBulanan(
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

                          const SizedBox(height: 12),

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
