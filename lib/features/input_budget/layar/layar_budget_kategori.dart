import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:budjet/features/algoritma_pembagian/algoritma_pembagian.dart';
import 'layar_analisis_budget.dart';
import '../../../../core/utils/app_helpers.dart';

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

  late final BudgetController _budgetCtrl;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double get _totalDialokasikan {
    double total = 0;
    for (final c in controllers) {
      total += _parseRupiah(c.text);
    }
    return total;
  }

  double get _sisaBelumDialokasikan =>
      widget.budgetBulanan - _totalDialokasikan;

  bool get _isValid => _sisaBelumDialokasikan.abs() < 1;

  @override
  void initState() {
    super.initState();

    _budgetCtrl = BudgetController();
    _budgetCtrl.inisialisasi(
      budgetBulanan: widget.budgetBulanan,
      bulan: widget.bulan,
    );

    controllers = List.generate(
      widget.kategoriList.length,
          (_) => TextEditingController(),
    );

    periodeList = List.generate(
      widget.kategoriList.length,
          (_) => 'Mingguan',
    );

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

  void _formatRupiah(TextEditingController controller, String value) {
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

    final Map<String, double> allocations = {};
    for (int i = 0; i < widget.kategoriList.length; i++) {
      allocations[widget.kategoriList[i]] =
          _parseRupiah(controllers[i].text);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LayarAnalisisBudget(
          budgetBulanan: widget.budgetBulanan,
          budgetHarian: _budgetCtrl.budgetHarian,
          bulan: widget.bulan,
          kategoriList: widget.kategoriList,
          allocations: allocations,
        ),
      ),
    );
  }

  void _showValidationPopup() {
    final sisa = _sisaBelumDialokasikan;
    final isOver = sisa < 0;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFE57373),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOver
                      ? 'Budget Melebihi Batas'
                      : 'Saldo Masih Tersisa',
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
                    child: const Text('OK',
                        style: TextStyle(color: Colors.white)),
                  ),
                )
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Atur Budget',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),

              const SizedBox(height: 10),

              /// SISA BUDGET
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sisa Budget: ${_currencyFormat.format(sisa.toInt())}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: ListView.builder(
                  itemCount: widget.kategoriList.length,
                  itemBuilder: (context, index) {
                    final kategori = widget.kategoriList[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// HEADER ITEM
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: _getColorBg(kategori),
                                child: Icon(
                                  _getIcon(kategori),
                                  color: _getColor(kategori),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                kategori,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'Periode Budget :',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// TOGGLE
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F6),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: ['Harian', 'Mingguan', 'Bulanan']
                                  .map((item) {
                                final selected = periodeList[index] == item;

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        periodeList[index] = item;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFD6E85A)
                                            : Colors.transparent,
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
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

                          const SizedBox(height: 12),

                          /// INPUT
                          TextField(
                            controller: controllers[index],
                            keyboardType: TextInputType.number,
                            onChanged: (value) =>
                                _formatRupiah(controllers[index], value),
                            decoration: InputDecoration(
                              hintText: 'Budget Anda',
                              filled: true,
                              fillColor: const Color(0xFFF1F3F6),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Sudah cocok?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 12),

              /// BUTTON
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
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}