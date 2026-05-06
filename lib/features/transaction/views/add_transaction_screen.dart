import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_helpers.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = NumberFormat('#,###', 'id_ID').format(int.parse(digits));
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddTransactionScreen extends StatelessWidget {
  // Load kategori dari Firestore (budget user)
  final bool isVoiceDraft;
  final TransactionModel? existingTx;

  AddTransactionScreen({super.key})
      : isVoiceDraft = Get.arguments is Map && (Get.arguments as Map)['isVoiceDraft'] == true,
        existingTx = Get.arguments is TransactionModel ? Get.arguments as TransactionModel : null {
    _loadCategories();

    // Persiapkan model mana yang akan dipakai untuk mengisi Field form
    TransactionModel? draftToFill;

    if (isVoiceDraft) {
      draftToFill = (Get.arguments as Map)['draftTx'] as TransactionModel;
    } else if (existingTx != null) {
      draftToFill = existingTx;
    }

    // Jika ada data (dari Edit atau Voice Draft), isi controller form secara otomatis
    if (draftToFill != null) {
      _titleController.text = draftToFill.title;
      _amountController.text = NumberFormat('#,###', 'id_ID').format(draftToFill.amount.toInt());
      _selectedCategory.value = draftToFill.kategori;
      _selectedDate.value = draftToFill.date;
    }
  }

  void _showSuccessDialog(String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F069),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4F069).withValues(alpha: 0.4),
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 32),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // close dialog
                    Get.back(); // back to history
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4F069),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  final TransactionController txController = Get.find<TransactionController>();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  final RxString _selectedCategory = ''.obs;
  final RxDouble _enteredAmount = 0.0.obs;
  final Rx<DateTime> _selectedDate = DateTime.now().obs;
  final RxBool _isLoading = false.obs;

  final RxList<String> _categories = <String>[].obs;

  final RxMap<String, Map<String, dynamic>> _categoryBudgetData =
      <String, Map<String, dynamic>>{}.obs;

  final RxMap<String, double> _categoryDailyBudget = <String, double>{}.obs;

  static const _defaultCategories = [
    'Makanan & Minuman',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Lainnya',
  ];

  String _periodLabel(String periode) {
    switch (periode) {
      case 'daily':
        return 'harian';
      case 'weekly':
        return 'mingguan';
      case 'monthly':
      default:
        return 'bulanan';
    }
  }

  bool _isSameCategory(String txCategory, String selectedCategory) {
    final txLower = txCategory.toLowerCase();
    final selectedLower = selectedCategory.toLowerCase();

    if (txLower == selectedLower) return true;

    final keywords = selectedLower.split(RegExp(r'[\s&]+'));
    for (final keyword in keywords) {
      if (keyword.length >= 3 && txLower.contains(keyword)) return true;
    }

    return false;
  }

  DateTime _startOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  double _usedByCategoryAndPeriod({
    required String category,
    required String period,
    required DateTime selectedDate,
  }) {
    return txController.transactions
        .where((tx) {
          if (tx.type != 'expense') return false;
          if (!_isSameCategory(tx.kategori, category)) return false;

          if (period == 'daily') {
            return tx.date.year == selectedDate.year &&
                tx.date.month == selectedDate.month &&
                tx.date.day == selectedDate.day;
          }

          if (period == 'weekly') {
            final start = _startOfWeek(selectedDate);
            final end = start.add(const Duration(days: 7));

            return tx.date.isAtSameMomentAs(start) ||
                (tx.date.isAfter(start) && tx.date.isBefore(end));
          }

          return tx.date.year == selectedDate.year &&
              tx.date.month == selectedDate.month;
        })
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<void> _loadCategories() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      _categories.value = _defaultCategories.toList();
      if (_selectedCategory.value.isEmpty) {
        _selectedCategory.value = _categories.first;
      }
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      final categoriesRaw = data['categories'] as List<dynamic>? ?? [];

      if (categoriesRaw.isNotEmpty) {
        final loadedCategories = <String>[];
        final budgetMap = <String, Map<String, dynamic>>{};
        final dailyBudgetMap = <String, double>{};

        for (final item in categoriesRaw) {
          final map = item as Map<String, dynamic>;
          final nama = map['nama'] as String? ?? '';

          if (nama.isEmpty) continue;

          final periode = map['periode'] as String? ?? 'monthly';
          final alokasiBulanan = (map['alokasiBulanan'] ?? map['alokasi'] ?? 0)
              .toDouble();
          final alokasiInput = (map['alokasiInput'] ?? alokasiBulanan)
              .toDouble();

          loadedCategories.add(nama);
          budgetMap[nama] = {
            'periode': periode,
            'alokasiInput': alokasiInput,
            'alokasiBulanan': alokasiBulanan,
          };

          if (periode == 'daily') {
            dailyBudgetMap[nama] = alokasiInput;
          } else if (periode == 'weekly') {
            dailyBudgetMap[nama] = alokasiInput / 7;
          } else {
            dailyBudgetMap[nama] = alokasiInput / 30;
          }
        }

        _categories.value = loadedCategories;
        _categoryBudgetData.value = budgetMap;
        _categoryDailyBudget.value = dailyBudgetMap;
      }
    }

    if (_categories.isEmpty) {
      _categories.value = _defaultCategories.toList();
    }

    if (_selectedCategory.value.isEmpty ||
        !_categories.contains(_selectedCategory.value)) {
      _selectedCategory.value = _categories.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate.value) {
      _selectedDate.value = picked;
    }
  }

  void _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      // final TransactionModel? existingTx = Get.arguments as TransactionModel?;
      final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.parse(cleanAmount.isEmpty ? '0' : cleanAmount);

      // Cek saldo jika ini transaksi baru (bukan edit)
      if (existingTx == null) {
        final sisaSaldo = txController.budgetBulanan.value - txController.totalExpense;
        if (amount > sisaSaldo) {
          Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECEC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: Color(0xFFEC6A6A), size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Saldo Tidak Cukup',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sisa saldo kamu hanya ${AppHelpers.formatCurrency(sisaSaldo < 0 ? 0 : sisaSaldo)}, tidak cukup untuk transaksi ini.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC6A6A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Mengerti'),
                  ),
                ),
              ],
            ),
          );
          return;
        }

        // Cek budget harian kategori (kumulatif: total hari ini + transaksi baru)
        final dailyBudget = _categoryDailyBudget[_selectedCategory.value] ?? 0;
        if (dailyBudget > 0) {
          final today = DateTime.now();
          // Hitung total pengeluaran hari ini untuk kategori yang dipilih
          final todaySpent = txController.transactions
              .where((t) =>
                  t.type == 'expense' &&
                  t.kategori == _selectedCategory.value &&
                  t.date.year == today.year &&
                  t.date.month == today.month &&
                  t.date.day == today.day)
              .fold(0.0, (sum, t) => sum + t.amount);

          final totalSetelahTransaksi = todaySpent + amount;

          if (totalSetelahTransaksi > dailyBudget) {
            // Tanya konfirmasi sebelum lanjut
            final confirmed = await Get.dialog<bool>(
              AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3CD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: Color(0xFFF59E0B), size: 38),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Melewati Budget Harian',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      todaySpent > 0
                          ? 'Total pengeluaran hari ini untuk "${_selectedCategory.value}" '
                            'akan menjadi ${AppHelpers.formatCurrency(totalSetelahTransaksi)}, '
                            'melebihi budget harian sebesar ${AppHelpers.formatCurrency(dailyBudget)}.\n\n'
                            'Kamu sudah menghabiskan ${AppHelpers.formatCurrency(todaySpent)} hari ini.'
                          : 'Pengeluaran ini (${AppHelpers.formatCurrency(amount)}) '
                            'melebihi budget harian kategori "${_selectedCategory.value}" '
                            'sebesar ${AppHelpers.formatCurrency(dailyBudget)}.\n\n'
                            'Melanjutkan dapat mengganggu rencana keuangan harianmu.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(result: false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Batalkan', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Tetap Lanjut'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
            if (confirmed != true) return; // User pilih Batalkan
          }
        }
      }

    _isLoading.value = true;

    final newTransaction = TransactionModel(
      id: existingTx?.id ?? '',
      amount: amount,
      createdAt: existingTx?.createdAt ?? DateTime.now(),
      date: _selectedDate.value,
      kategori: _selectedCategory.value,
      note: '',
      title: _titleController.text,
      type: existingTx?.type ?? 'expense',
    );

      if (existingTx != null) {
        await txController.updateTransaction(existingTx!, newTransaction);
      } else {
        await txController.addTransaction(newTransaction);
      }

    _isLoading.value = false;

    if (existingTx != null) {
      _showSuccessDialog('Transaksi Berhasil Diperbarui');
    } else {
      Get.offNamed('/success-tx', arguments: newTransaction);
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          existingTx != null ? 'Edit Transaksi' : 'Tambah Transaksi',
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Pengeluaran',
                            labelStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            suffixIcon: Icon(
                              Icons.edit_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Isi judul' : null,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ThousandsSeparatorFormatter(),
                          ],
                          onChanged: (val) {
                            final digits = val.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            double parsed = double.tryParse(digits) ?? 0;

                            final sisaSaldo =
                                txController.budgetBulanan.value -
                                txController.totalExpense;

                            if (sisaSaldo > 0 && parsed > sisaSaldo) {
                              parsed = sisaSaldo.floorToDouble();

                              final capped = NumberFormat(
                                '#,###',
                                'id_ID',
                              ).format(parsed.toInt());

                              _amountController.text = capped;
                              _amountController.selection =
                                  TextSelection.collapsed(
                                    offset: capped.length,
                                  );
                            }

                            _enteredAmount.value = parsed;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Nominal',
                            labelStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            prefixText: 'Rp ',
                            prefixStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                            border: InputBorder.none,
                            suffixIcon: Icon(
                              Icons.edit_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Isi nominal';
                            }
                            final cleanVal = val.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );

                            if (double.tryParse(cleanVal) == null) {
                              return 'Angka tidak valid';
                            }

                            return null;
                          },
                        ),
                      ),
                      // Indikator sisa saldo real-time
                      if (existingTx == null)
                        Obx(() {
                          final sisaSaldo = txController.budgetBulanan.value -
                              txController.totalExpense;
                          final setelahTransaksi =
                              sisaSaldo - _enteredAmount.value;
                          final cukup = setelahTransaksi >= 0;
                          if (_enteredAmount.value <= 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Row(
                              children: [
                                Icon(
                                  cukup
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  size: 14,
                                  color: cukup ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cukup
                                      ? 'Sisa saldo: ${AppHelpers.formatCurrency(setelahTransaksi)}'
                                      : 'Saldo tidak cukup! Kurang ${AppHelpers.formatCurrency(-setelahTransaksi)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cukup ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                'Kategori',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Obx(() {
                                  final catColor = AppHelpers.getCategoryColor(
                                    _selectedCategory.value,
                                    '',
                                  );
                                  final catIcon = AppHelpers.getCategoryIcon(
                                    _selectedCategory.value,
                                    '',
                                  );

                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      catIcon,
                                      color: catColor,
                                      size: 20,
                                    ),
                                  );
                                }),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Obx(() {
                                    if (_categories.isEmpty ||
                                        _selectedCategory.value.isEmpty) {
                                      return const Text(
                                        'Memuat...',
                                        style: TextStyle(color: Colors.grey),
                                      );
                                    }

                                    final items = _categories.toList();

                                    if (!items.contains(
                                      _selectedCategory.value,
                                    )) {
                                      items.add(_selectedCategory.value);
                                    }

                                    return DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCategory.value,
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.grey,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textDark,
                                        ),
                                        items: [
                                          ...items.map(
                                            (cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat),
                                            ),
                                          ),
                                          const DropdownMenuItem(
                                            value: '__ADD_NEW__',
                                            child: Text(
                                              'Kategori tidak ada?',
                                              style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val == '__ADD_NEW__') {
                                            final previousCategory =
                                                _selectedCategory.value;

                                            Get.defaultDialog(
                                              title: 'Kategori Tidak Ada?',
                                              middleText:
                                                  'Anda akan diarahkan ke halaman Edit Budget untuk menambahkan kategori baru.',
                                              textConfirm: 'Ya, Ke Pengaturan',
                                              textCancel: 'Batal',
                                              confirmTextColor: Colors.white,
                                              buttonColor: const Color(
                                                0xFFDCE775,
                                              ),
                                              cancelTextColor:
                                                  AppColors.textDark,
                                              onConfirm: () {
                                                Get.back();

                                                _selectedCategory.value =
                                                    previousCategory;

                                                Get.toNamed(
                                                  '/edit-budget',
                                                )?.then((_) async {
                                                  await _loadCategories();

                                                  if (_categories.isNotEmpty &&
                                                      !_categories.contains(
                                                        _selectedCategory.value,
                                                      )) {
                                                    _selectedCategory.value =
                                                        _categories.last;
                                                  }
                                                });
                                              },
                                            );
                                          } else if (val != null) {
                                            _selectedCategory.value = val;
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  'Tanggal',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Obx(() {
                                      final isToday =
                                          _selectedDate.value.day ==
                                              DateTime.now().day &&
                                          _selectedDate.value.month ==
                                              DateTime.now().month &&
                                          _selectedDate.value.year ==
                                              DateTime.now().year;

                                      return Text(
                                        isToday
                                            ? 'Hari ini'
                                            : DateFormat(
                                                'dd MMM yyyy',
                                              ).format(_selectedDate.value),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textDark,
                                        ),
                                      );
                                    }),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existingTx != null
                        ? 'Simpan Perubahan?'
                        : 'Sudah Cocok?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: _isLoading.value ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDCE775),
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.textDark,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
    );
  }
}
