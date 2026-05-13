import 'dart:async';
import '../../transaction/controllers/transaction_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/validation_helper.dart';

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

  late final TransactionController _txCtrl;

  bool _isLoading = true;
  bool _hasChanged = false;
  bool _canPopNow = false;
  bool _isSisaDana(Map<String, dynamic> c) {
    return (c['nama'] ?? '').toString().toLowerCase() == 'sisa dana' ||
        c['isAutoCategory'] == true;
  }

  double _budgetBulanan = 0.0;
  List<Map<String, dynamic>> _categories = [];

  final TextEditingController _totalBudgetCtrl = TextEditingController();
  List<TextEditingController> _catControllers = [];
  bool _showTotalBudgetWarning = false;
  Timer? _totalBudgetWarningTimer;
  final Map<int, bool> _showCatWarning = {};
  final Map<int, Timer?> _catWarningTimers = {};

  @override
  void initState() {
    super.initState();
    _txCtrl = Get.find<TransactionController>();
    _loadData();

    _totalBudgetCtrl.addListener(() {
      _hasChanged = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _totalBudgetCtrl.dispose();
    for (final c in _catControllers) {
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        _budgetBulanan = (data['budgetBulanan'] ?? 0).toDouble();

        final catsRaw = data['categories'] ?? [];
        _categories = List<Map<String, dynamic>>.from(catsRaw);

        _totalBudgetCtrl.text = NumberFormat('#,###', 'id_ID').format(_budgetBulanan).replaceAll(',', '.');

        _catControllers = _categories.map((c) {
          final ctrl = TextEditingController();

          final nama = c['nama'] as String? ?? '';
          final period = c['periode'] as String? ?? 'monthly';
          final divider = _periodDivider(period);

          final alokasiBulanan = (c['alokasiBulanan'] ?? c['alokasi'] ?? 0)
              .toDouble();

          final used = _expenseBulanan(nama);
          final sisaBulanan = alokasiBulanan - used;
          final sisaSesuaiPeriode =
              (sisaBulanan < 0 ? 0 : sisaBulanan) / divider;

          ctrl.text = NumberFormat('#,###', 'id_ID').format(sisaSesuaiPeriode).replaceAll(',', '.');

          ctrl.addListener(() {
            _hasChanged = true;
            setState(() {});
          });

          return ctrl;
        }).toList();

        _hasChanged = false;
      }
    } catch (e) {
      debugPrint('Error loading budget: $e');
    }

    setState(() => _isLoading = false);
  }

  double _parseRupiah(String text) {
    final angka = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(angka) ?? 0;
  }

  // _formatRupiah removed, handled by RupiahInputFormatter and prefixText

  bool _matchKategori(String txKategori, String budgetKat) {
    final txLower = txKategori.toLowerCase();
    final katLower = budgetKat.toLowerCase();

    if (txLower == katLower) return true;

    final keywords = katLower.split(RegExp(r'[\s&]+'));
    for (final kw in keywords) {
      if (kw.length >= 3 && txLower.contains(kw)) return true;
    }

    return false;
  }

  double _expenseBulanan(String kategori) {
    final now = DateTime.now();

    return _txCtrl.transactions
        .where(
          (tx) =>
              tx.type == 'expense' &&
              _matchKategori(tx.kategori, kategori) &&
              tx.date.year == now.year &&
              tx.date.month == now.month,
        )
        .fold(0.0, (total, item) => total + item.amount);
  }

  double _periodDivider(String period) {
    switch (period) {
      case 'daily':
        return 30;
      case 'weekly':
        return 4;
      case 'monthly':
      default:
        return 1;
    }
  }

  String _periodSuffix(String period) {
    switch (period) {
      case 'daily':
        return 'hari';
      case 'weekly':
        return 'minggu';
      case 'monthly':
      default:
        return 'bulan';
    }
  }

  double get _currentTotalBudget => _parseRupiah(_totalBudgetCtrl.text);

  double get _totalDialokasikan {
    double sum = 0;

    for (int i = 0; i < _categories.length; i++) {
      final category = _categories[i];

      if (_isSisaDana(category)) continue;

      final nama = category['nama'] as String? ?? '';
      final period = category['periode'] as String? ?? 'monthly';
      final divider = _periodDivider(period);

      final sisaInputSesuaiPeriode = _parseRupiah(_catControllers[i].text);
      final used = _expenseBulanan(nama);

      final alokasiBulananBaru = (sisaInputSesuaiPeriode * divider) + used;

      sum += alokasiBulananBaru;
    }

    return sum;
  }

  double get _sisaBudget => _currentTotalBudget - _totalDialokasikan;

  bool get _isOverBudget => _sisaBudget < 0;

  bool get _isValid => !_isOverBudget;

  IconData _iconForKategori(String k) {
    return AppHelpers.getCategoryIcon(k);
  }

  Color _iconBgFor(int i, String name) {
    return AppHelpers.getCategoryColorBg(name, i);
  }

  Color _iconColFor(int i, String name) {
    return AppHelpers.getCategoryColor(name, i);
  }

  void _handleBack() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Yakin ingin kembali?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _hasChanged
                    ? 'Perubahan Anda belum disimpan.'
                    : 'Anda belum melakukan perubahan apapun.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Ya, Kembali
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _canPopNow = true);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4E858),
                        foregroundColor: AppColors.textDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Ya, Kembali',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeCategory(int index) {
    final catName = _categories[index]['nama'] ?? 'Kategori';

    Get.defaultDialog(
      title: 'Hapus Kategori?',
      middleText:
          'Apakah Anda yakin ingin menghapus kategori "$catName" dari anggaran?',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      cancelTextColor: AppColors.textDark,
      onConfirm: () {
        setState(() {
          _categories.removeAt(index);
          _catControllers[index].dispose();
          _catControllers.removeAt(index);
          _hasChanged = true;
        });
        Get.back();
      },
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    String selectedPeriod = 'monthly';
    bool showNameWarning = false;
    Timer? nameWarningTimer;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tambah Kategori',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                      const Text(
                        'Nama kategori',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameCtrl,
                        onChanged: (val) {
                          if (val.length < 20 && showNameWarning) {
                            setDialogState(() => showNameWarning = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Nama kategori',
                          helperText: 'Hanya huruf dan spasi',
                          errorText: showNameWarning ? 'Maksimal 20 Karakter!' : null,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            height: 0.8, // Naikkan posisi tanpa merusak box
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.length > 20) {
                              if (!showNameWarning) {
                                nameWarningTimer?.cancel();
                                setDialogState(() => showNameWarning = true);
                                nameWarningTimer = Timer(const Duration(seconds: 3), () {
                                  setDialogState(() => showNameWarning = false);
                                });
                              }
                              return oldValue;
                            }
                            return newValue;
                          }),
                        ],
                      ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children:
                          [
                            {'label': 'Harian', 'value': 'daily'},
                            {'label': 'Mingguan', 'value': 'weekly'},
                            {'label': 'Bulanan', 'value': 'monthly'},
                          ].map((item) {
                            final selected = selectedPeriod == item['value'];

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedPeriod = item['value']!;
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
                                      item['label']!,
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

                  const SizedBox(height: 8),

                  Text(
                    'Nominal kategori ini nanti diisi per ${_periodSuffix(selectedPeriod)}.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameCtrl.text.trim();

                            if (name.isEmpty) return;

                            final isDuplicate = _categories.any(
                              (c) =>
                                  (c['nama'] ?? '').toString().toLowerCase() ==
                                  name.toLowerCase(),
                            );

                            if (isDuplicate) {
                              Get.snackbar(
                                'Gagal',
                                'Kategori sudah ada',
                                snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
                              return;
                            }

                            setState(() {
                              _categories.add({
                                'nama': name,
                                'periode': selectedPeriod,
                                'alokasiInput': 0.0,
                                'alokasiBulanan': 0.0,
                                'alokasi': 0.0,
                                'isAutoCategory': false,
                              });

                              final ctrl = TextEditingController();
                              ctrl.text = '0';
                              ctrl.addListener(() {
                                _hasChanged = true;
                                setState(() {});
                              });

                              _catControllers.add(ctrl);
                              _hasChanged = true;
                            });

                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4E858),
                            foregroundColor: AppColors.textDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Tambah'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onSimpan() {
    if (_isOverBudget) {
      _showValidationPopup();
      return;
    }

    if (_sisaBudget > 0) {
      _showSisaDanaConfirmation();
      return;
    }

    _saveBudget();
  }

  void _showSisaDanaConfirmation() {
    final sisa = _sisaBudget;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Saldo Masih Tersisa'),
          content: Text(
            'Masih ada ${_currencyFmt.format(sisa.toInt())} yang belum dialokasikan. '
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
                _saveBudget();
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBudget() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final totalBudget = _currentTotalBudget;
    final List<Map<String, dynamic>> updatedCategories = [];

    for (int i = 0; i < _categories.length; i++) {
      final oldCategory = _categories[i];

      if (_isSisaDana(oldCategory)) continue;

      final name = oldCategory['nama'] as String? ?? '';
      final period = oldCategory['periode'] as String? ?? 'monthly';
      final divider = _periodDivider(period);

      final sisaInputSesuaiPeriode = _parseRupiah(_catControllers[i].text);
      final used = _expenseBulanan(name);

      final alokasiBulananBaru = (sisaInputSesuaiPeriode * divider) + used;

      final alokasiInputBaru = alokasiBulananBaru / divider;

      final persentase = totalBudget > 0
          ? (alokasiBulananBaru / totalBudget * 100).roundToDouble()
          : 0.0;

      updatedCategories.add({
        ...oldCategory,
        'nama': name,
        'periode': period,
        'alokasiInput': alokasiInputBaru,
        'alokasiBulanan': alokasiBulananBaru,
        'alokasi': alokasiBulananBaru,
        'persentase': persentase,
        'harian': (alokasiBulananBaru / 30).roundToDouble(),
        'terpakai': used,
        'sisa': sisaInputSesuaiPeriode,
        'isAutoCategory': false,
      });
    }

    final sisaDana =
        totalBudget -
        updatedCategories.fold<double>(
          0,
          (sum, c) =>
              sum + ((c['alokasiBulanan'] ?? c['alokasi'] ?? 0).toDouble()),
        );

    if (sisaDana > 0) {
      updatedCategories.add({
        'nama': 'Sisa Dana',
        'periode': 'monthly',
        'alokasiInput': sisaDana,
        'alokasiBulanan': sisaDana,
        'alokasi': sisaDana,
        'persentase': totalBudget > 0
            ? (sisaDana / totalBudget * 100).roundToDouble()
            : 0.0,
        'harian': (sisaDana / 30).roundToDouble(),
        'terpakai': 0.0,
        'sisa': sisaDana,
        'isAutoCategory': true,
      });
    }

    if (_sisaBudget > 0) {
      final sisaDanaIndex = updatedCategories.indexWhere(
        (c) => (c['nama'] ?? '').toString().toLowerCase() == 'sisa dana',
      );

      final sisaDanaCategory = {
        'nama': 'Sisa Dana',
        'periode': 'monthly',
        'alokasiInput': _sisaBudget,
        'alokasiBulanan': _sisaBudget,
        'alokasi': _sisaBudget,
        'persentase': totalBudget > 0
            ? (_sisaBudget / totalBudget * 100).roundToDouble()
            : 0.0,
        'harian': (_sisaBudget / 30).roundToDouble(),
        'terpakai': 0.0,
        'sisa': _sisaBudget,
        'isAutoCategory': true,
      };

      if (sisaDanaIndex >= 0) {
        updatedCategories[sisaDanaIndex] = {
          ...updatedCategories[sisaDanaIndex],
          ...sisaDanaCategory,
        };
      } else {
        updatedCategories.add(sisaDanaCategory);
      }
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'budgetBulanan': totalBudget,
        'categories': updatedCategories,
        'selectedCategories': updatedCategories.map((c) => c['nama']).toList(),
        'allocations': {
          for (final c in updatedCategories) c['nama']: c['alokasiBulanan'],
        },
      }, SetOptions(merge: true));

      setState(() => _canPopNow = true);

      Get.back();
      Get.back();

      Get.snackbar(
        'Berhasil',
        'Budget telah diupdate.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
    }
  }

  void _showValidationPopup() {
    final sisa = _sisaBudget;
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
            padding: const EdgeInsets.all(24),
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
                      ? 'Total alokasi melebihi budget sebesar ${_currencyFmt.format(sisa.abs().toInt())}.'
                      : 'Masih ada ${_currencyFmt.format(sisa.toInt())} yang belum dialokasikan.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildSisaIndicator() {
    final isPas = _sisaBudget.abs() < 1;
    final isOver = _sisaBudget < 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPas
            ? Colors.green.shade50
            : isOver
            ? Colors.red.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPas
              ? Colors.green.shade300
              : isOver
              ? Colors.red.shade300
              : Colors.orange.shade300,
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
              color: isPas
                  ? Colors.green.shade700
                  : isOver
                  ? Colors.red.shade700
                  : Colors.orange.shade700,
            ),
          ),
          Text(
            isPas ? 'Rp 0' : _currencyFmt.format(_sisaBudget.abs().toInt()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isPas
                  ? Colors.green.shade700
                  : isOver
                  ? Colors.red.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(int i) {
    final cat = _categories[i];

    final catName = cat['nama'] as String? ?? '';
    final period = cat['periode'] as String? ?? 'monthly';

    final alokasiAwal = (cat['alokasiBulanan'] ?? cat['alokasi'] ?? 0)
        .toDouble();
    final used = _expenseBulanan(catName);
    final sisaSaatIni = alokasiAwal - used;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _iconBgFor(i, catName),
                child: Icon(
                  _iconForKategori(catName),
                  color: _iconColFor(i, catName),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  catName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _removeCategory(i),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Alokasi awal: ${_currencyFmt.format(alokasiAwal)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Sudah digunakan: ${_currencyFmt.format(used)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Sisa saat ini: ${_currencyFmt.format(sisaSaatIni < 0 ? 0 : sisaSaatIni)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Budget tersisa',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _catControllers[i],
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final amount = ValidationHelper.parseRupiah(val);
                  if (amount < 100000000 && (_showCatWarning[i] ?? false)) {
                    setState(() => _showCatWarning[i] = false);
                  }
                  // Formatting handled by RupiahInputFormatter
                  setState(() { _hasChanged = true; });
                },
                inputFormatters: [
                  RupiahInputFormatter(
                    max: 100000000,
                    onMaxExceeded: () {
                      if (!(_showCatWarning[i] ?? false)) {
                        _catWarningTimers[i]?.cancel();
                        setState(() => _showCatWarning[i] = true);
                        _catWarningTimers[i] = Timer(const Duration(seconds: 3), () {
                          if (mounted) setState(() => _showCatWarning[i] = false);
                        });
                      }
                    },
                  ),
                ],
                decoration: InputDecoration(
                  hintText: 'Budget tersisa',
                  prefixText: 'Rp ',
                  helperText:
                      'Sisa budget ${catName.toLowerCase()} per ${_periodSuffix(period)}',
                  helperStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_showCatWarning[i] ?? false)
                const Padding(
                  padding: EdgeInsets.only(top: 0, bottom: 8, left: 12),
                  child: Text(
                    'Max Rp 100.000.000!',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Edit Budget Bulanan',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 22,
          ),
          onPressed: _handleBack,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PopScope(
              canPop: _canPopNow,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                _handleBack();
              },
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                      color: AppColors.backgroundLight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budget Anda',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: _showTotalBudgetWarning ? 4 : 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _totalBudgetCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    final amount = ValidationHelper.parseRupiah(val);
                                    if (amount < 100000000 && _showTotalBudgetWarning) {
                                      setState(() => _showTotalBudgetWarning = false);
                                    }
                                    setState(() {
                                      _hasChanged = true;
                                    });
                                  },
                                  inputFormatters: [
                                    RupiahInputFormatter(
                                      max: 100000000,
                                      onMaxExceeded: () {
                                        if (!_showTotalBudgetWarning) {
                                          _totalBudgetWarningTimer?.cancel();
                                          setState(() => _showTotalBudgetWarning = true);
                                          _totalBudgetWarningTimer = Timer(const Duration(milliseconds: 2200), () {
                                            if (mounted) setState(() => _showTotalBudgetWarning = false);
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                      hintText: 'Budget Anda',
                                      prefixText: 'Rp ',
                                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: _showTotalBudgetWarning ? 12 : 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                if (_showTotalBudgetWarning)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 0, bottom: 16, left: 20),
                                    child: Text(
                                      'Max Rp 100.000.000!',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSisaIndicator(),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            ...List.generate(
                              _categories.length,
                              _buildCategoryCard,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          TextButton.icon(
                            onPressed: _showAddCategoryDialog,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFF4CAF50),
                            ),
                            label: const Text(
                              'Tambah Kategori',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'Sudah Cocok?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _onSimpan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4E858),
                                foregroundColor: AppColors.textDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
