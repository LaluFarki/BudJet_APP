import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

class EditBudgetScreen extends StatefulWidget {
  const EditBudgetScreen({super.key});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final _currencyFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  double _budgetBulanan = 0.0;
  List<Map<String, dynamic>> _categories = [];
  
  final TextEditingController _totalBudgetCtrl = TextEditingController();
  List<TextEditingController> _catControllers = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    _totalBudgetCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _totalBudgetCtrl.dispose();
    for (var c in _catControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _budgetBulanan = (data['budgetBulanan'] ?? 0).toDouble();
        
        final catsRaw = data['categories'] ?? [];
        _categories = List<Map<String, dynamic>>.from(catsRaw);

        // Set text
        _formatRupiah(_totalBudgetCtrl, _budgetBulanan.toStringAsFixed(0));
        
        _catControllers = _categories.map((c) {
          final ctrl = TextEditingController();
          final alokasi = (c['alokasi'] ?? 0).toDouble();
          _formatRupiah(ctrl, alokasi.toStringAsFixed(0));
          ctrl.addListener(() {
            setState(() {});
          });
          return ctrl;
        }).toList();
      }
    } catch (e) {
      debugPrint("Error loading: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  double _parseRupiah(String text) {
    if (text.isEmpty) return 0;
    final angka = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(angka) ?? 0;
  }

  void _formatRupiah(TextEditingController controller, String value) {
    if (value.isEmpty) {
      controller.clear();
      return;
    }
    final angka = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (angka.isEmpty) {
      controller.clear();
      return;
    }
    final formatted = _currencyFmt.format(int.parse(angka));
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  double get _currentTotalBudget => _parseRupiah(_totalBudgetCtrl.text);

  double get _totalDialokasikan {
    double sum = 0;
    for (var c in _catControllers) {
      sum += _parseRupiah(c.text);
    }
    return sum;
  }

  double get _sisaBudget => _currentTotalBudget - _totalDialokasikan;

  bool get _isValid => _sisaBudget.abs() < 1;

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
      Color(0xFFFFEAE0), Color(0xFFDCF3FB), Color(0xFFE9F8C6), Color(0xFFF0E5FA), Color(0xFFFFE4EE),
    ];
    return bgs[i % bgs.length];
  }
  
  Color _iconColFor(int i) {
    const cols = [
      Color(0xFFFF7B33), Color(0xFF1D9CCB), Color(0xFFBCE037), Color(0xFFAB6AEA), Color(0xFFFC5A8D),
    ];
    return cols[i % cols.length];
  }

  void _onSimpan() async {
    if (!_isValid) {
      _showValidationPopup();
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Build the new categories array
    final updatedCategories = [];
    final totalBudget = _currentTotalBudget;

    for (int i = 0; i < _categories.length; i++) {
      final name = _categories[i]['nama'];
      final alokasi = _parseRupiah(_catControllers[i].text);
      final persentase = totalBudget > 0 ? (alokasi / totalBudget * 100) : 0;
      final harian = alokasi / 30; // standard per day calculation applied elsewhere
      
      updatedCategories.add({
        'nama': name,
        'alokasi': alokasi,
        'persentase': persentase,
        'harian': harian,
      });
    }

    // Save to Firestore
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'budgetBulanan': totalBudget,
        'categories': updatedCategories,
      }, SetOptions(merge: true));
      
      Get.back(); // close progress
      Get.back(); // close page
      Get.snackbar('Berhasil', 'Budget telah diupdate.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.back(); // close progress
      Get.snackbar('Gagal', 'Terjadi kesalahan: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showValidationPopup() {
    final sisa = _sisaBudget;
    final isOver = sisa < -0.5;
    final judul = isOver ? 'Budget Melebihi Batas' : 'Saldo Masih Tersisa';
    final pesan = isOver
        ? 'Total alokasi melebihi budget sebesar ${_currencyFmt.format(sisa.abs().toInt())}. Silakan kurangi alokasi Anda.'
        : 'Saldo alokasi Anda masih tersisa ${_currencyFmt.format(sisa.toInt())}.\nSesuaikan seluruh saldo agar bisa disimpan.';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFE57373),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  pesan,
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
             title: const Text(
               'Edit Budget Bulanan',
               style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700),
             ),
             centerTitle: true,
             backgroundColor: AppColors.backgroundLight,
             elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textDark, size: 22),
                onPressed: () => Get.back(),
              ),
           ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budget Anda',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _totalBudgetCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _formatRupiah(_totalBudgetCtrl, val),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Budget Anda',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              const Text(
                                'Sisa Budget: ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              Text(
                                _currencyFmt.format(_sisaBudget.abs()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _sisaBudget == 0 ? Colors.green : (_sisaBudget < 0 ? Colors.red : AppColors.textDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Categories Edit
                          ...List.generate(_categories.length, (i) {
                            final catName = _categories[i]['nama'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    margin: const EdgeInsets.only(top: 24), // center-align with field approx
                                    decoration: BoxDecoration(color: _iconBgFor(i), shape: BoxShape.circle),
                                    child: Icon(_iconForKategori(catName), color: _iconColFor(i), size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          catName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _catControllers[i],
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) => _formatRupiah(_catControllers[i], val),
                                          decoration: InputDecoration(
                                            hintText: 'Budget anda',
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            'Sudah Cocok?',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onSimpan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4E858), // Lime Green
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('Simpan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
