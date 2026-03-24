import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';

class AddTransactionScreen extends StatelessWidget {
  AddTransactionScreen({Key? key}) : super(key: key);

  // Akses TransactionController yang sudah dipanggil (Get.put) di HomeScreen
  final TransactionController txController = Get.find<TransactionController>();

  // GlobalKey untuk validasi Form
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk setiap field input
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();

  // State reaktif lokal menggunakan Rx GetX untuk Dropdown dan Loading
  final RxString _selectedType = 'expense'.obs;
  final RxBool _isLoading = false.obs;

  void _submit() async {
    // Jalankan validasi
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;

      // Membuat objek model dari input pengguna
      final newTransaction = TransactionModel(
        id: '', // Dikosongkan karena Firestore DocumentReference() otomatis men-generate ID baru
        amount: double.parse(_amountController.text),
        createdAt: DateTime.now(),
        date: DateTime.now(), // Saat ini default ke Hari Ini
        kategori: _categoryController.text,
        note: _noteController.text,
        title: _titleController.text,
        type: _selectedType.value,
      );

      // Panggil fungsi controller
      await txController.addTransaction(newTransaction);

      _isLoading.value = false;
      // Kembali ke layar sebelumnya setelah sukses
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Tambah Transaksi',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- INPUt: Judul ---
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Transaksi',
                  hintText: 'Cth: Makan Siang',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- INPUt: Nominal ---
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  // Cek apakah angka yang dimasukkan valid
                  if (double.tryParse(value) == null) {
                    return 'Hanya boleh diisi dengan angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- INPUt: Tipe (Income/Expense) menggunakan Dropdown ---
              Obx(() => DropdownButtonFormField<String>(
                    value: _selectedType.value,
                    decoration: InputDecoration(
                      labelText: 'Tipe Transaksi',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Pengeluaran (Expense)'),
                      ),
                      DropdownMenuItem(
                        value: 'income',
                        child: Text('Pemasukan (Income)'),
                      ),
                    ],
                    onChanged: (newValue) {
                      if (newValue != null) {
                        _selectedType.value = newValue;
                      }
                    },
                  )),
              const SizedBox(height: 16),

              // --- INPUt: Kategori ---
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'Cth: Makanan, Transportasi',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kategori tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- INPUt: Catatan ---
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- TOMBOL SIMPAN ---
              Obx(() => ElevatedButton(
                    onPressed: _isLoading.value ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF4CAF50), // Warna Hijau Primary
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Simpan Transaksi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
