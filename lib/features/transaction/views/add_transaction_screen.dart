import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';

class AddTransactionScreen extends StatelessWidget {
  AddTransactionScreen({Key? key}) : super(key: key) {
    final TransactionModel? existingTx = Get.arguments as TransactionModel?;
    if (existingTx != null) {
      _titleController.text = existingTx.title;
      _amountController.text = existingTx.amount.toInt().toString();
      _selectedCategory.value = existingTx.kategori;
      _selectedDate.value = existingTx.date;
    }
  }

  final TransactionController txController = Get.find<TransactionController>();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  // Karena desainnya Kategori itu Dropdown:
  final RxString _selectedCategory = 'Makanan & Minuman'.obs;
  
  // Tanggal Picker
  final Rx<DateTime> _selectedDate = DateTime.now().obs;

  final RxBool _isLoading = false.obs;

  // List kategori statis sesuai mock-up
  final List<String> _categories = [
    'Makanan & Minuman',
    'Transportasi',
    'Belanja',
    'Hiburan',
    'Lainnya'
  ];

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
        Get.back(); // Kembali ke halaman history sesudah edit
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
        child: Padding(
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
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.restaurant, color: Colors.orange, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Obx(() => DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory.value,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                items: _categories.map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) _selectedCategory.value = val;
                                },
                              ),
                            )),
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
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                                color: Colors.blue.withOpacity(0.1),
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
                const Spacer(),

                // === Teks Sudah Cocok? ===
                Center(
                  child: Text(
                    Get.arguments != null ? 'Simpan Perubahan?' : 'Sudah Cocok?',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // === Tombol Simpan ===
                Obx(() => ElevatedButton(
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
