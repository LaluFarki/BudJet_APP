import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_helpers.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';

class AddTransactionScreen extends StatelessWidget {
  AddTransactionScreen({super.key}) {
    // Load kategori dari Firestore (budget user)
    _loadCategories();

    final TransactionModel? existingTx = Get.arguments as TransactionModel?;
    if (existingTx != null) {
      _titleController.text = existingTx.title;
      _amountController.text = existingTx.amount.toInt().toString();
      _selectedCategory.value = existingTx.kategori;
      _selectedDate.value = existingTx.date;
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
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
  
  // Tanggal Picker
  final Rx<DateTime> _selectedDate = DateTime.now().obs;

  final RxBool _isLoading = false.obs;

  // Kategori dinamis dari Firestore (budget user)
  final RxList<String> _categories = <String>[].obs;

  // Fallback jika belum ada data di Firestore
  static const _defaultCategories = [
    'Makanan & Minuman',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Lainnya'
  ];

  void _loadCategories() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _categories.value = _defaultCategories.toList();
      if (_selectedCategory.value.isEmpty) {
        _selectedCategory.value = _categories.first;
      }
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() ?? {};
      final categoriesRaw = data['categories'] as List<dynamic>? ?? [];
      if (categoriesRaw.isNotEmpty) {
        _categories.value = categoriesRaw
            .map((e) => (e as Map<String, dynamic>)['nama'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      }
    }

    // Fallback jika kosong
    if (_categories.isEmpty) {
      _categories.value = _defaultCategories.toList();
    }

    // Set default selected jika belum di-set (bukan mode edit)
    if (_selectedCategory.value.isEmpty || !_categories.contains(_selectedCategory.value)) {
      _selectedCategory.value = _categories.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate.value) {
      _selectedDate.value = picked;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      final TransactionModel? existingTx = Get.arguments as TransactionModel?;

      // Hapus karakter non-digit agar parse uang aman
      final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      final newTransaction = TransactionModel(
        id: existingTx?.id ?? '', // Diabaikan oleh Firestore create auto id jika kosong
        amount: double.parse(cleanAmount.isEmpty ? '0' : cleanAmount),
        createdAt: existingTx?.createdAt ?? DateTime.now(),
        date: _selectedDate.value,
        kategori: _selectedCategory.value,
        note: '', // Desain baru tidak ada note
        title: _titleController.text,
        type: existingTx?.type ?? 'expense', // Pertahankan tipe asli
      );

      if (existingTx != null) {
        await txController.updateTransaction(existingTx, newTransaction);
      } else {
        await txController.addTransaction(newTransaction);
      }

      _isLoading.value = false;
      if (existingTx != null) {
        _showSuccessDialog('Transaksi Berhasil Diperbarui');
      } else {
        // Pindah ke Success Screen kirim data
        Get.offNamed('/success-tx', arguments: newTransaction);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Sangat light grey / off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          Get.arguments != null ? 'Edit Transaksi' : 'Tambah Transaksi',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Bagian Atas: Form bisa di-scroll ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // === Nama Pengeluaran ===
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Pengeluaran',
                            labelStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            border: InputBorder.none,
                            suffixIcon: Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          validator: (val) => val == null || val.isEmpty ? 'Isi judul' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // === Nominal ===
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nominal',
                            labelStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            prefixText: 'Rp ',
                            prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                            border: InputBorder.none,
                            suffixIcon: Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Isi nominal';
                            final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
                            if (double.tryParse(cleanVal) == null) return 'Angka tidak valid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // === Kategori Dropdown ===
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 4),
                              child: Text('Kategori', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                            Row(
                              children: [
                                Obx(() {
                                  final catColor = AppHelpers.getCategoryColor(_selectedCategory.value, '');
                                  final catIcon = AppHelpers.getCategoryIcon(_selectedCategory.value, '');
                                  
                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(catIcon, color: catColor, size: 20),
                                  );
                                }),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Obx(() {
                                    if (_categories.isEmpty || _selectedCategory.value.isEmpty) {
                                      return const Text('Memuat...', style: TextStyle(color: Colors.grey));
                                    }
                                    // Jika kategori lama (dari edit) tidak ada di list, tambahkan sementara
                                    final items = _categories.toList();
                                    if (!items.contains(_selectedCategory.value)) {
                                      items.add(_selectedCategory.value);
                                    }
                                    return DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCategory.value,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                        items: items.map((cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(cat),
                                        )).toList(),
                                        onChanged: (val) {
                                          if (val != null) _selectedCategory.value = val;
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

                      // === Tanggal ===
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 8, bottom: 4),
                                child: Text('Tanggal', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Obx(() {
                                      final isToday = _selectedDate.value.day == DateTime.now().day &&
                                                      _selectedDate.value.month == DateTime.now().month &&
                                                      _selectedDate.value.year == DateTime.now().year;
                                      return Text(
                                        isToday ? 'Hari ini' : DateFormat('dd MMM yyyy').format(_selectedDate.value),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                      );
                                    }),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40), // Ruang lega ekstra
                    ],
                  ),
                ),
              ),
            ),
            
            // --- Bagian Bawah: Tombol Tetap Terpisah ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20), // Padding bawah
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === Teks Sudah Cocok? ===
                  Text(
                    Get.arguments != null ? 'Simpan Perubahan?' : 'Sudah Cocok?',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // === Tombol Simpan ===
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => ElevatedButton(
                      onPressed: _isLoading.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDCE775), // Lime Green
                        foregroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading.value
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.textDark, strokeWidth: 2))
                          : const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    )),
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
