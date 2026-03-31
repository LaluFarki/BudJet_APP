import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Sesuaikan dengan nama package kamu

import 'layar_budget_kategori.dart';

/// Layar 1 dari 2: Input budget bulanan + pilih kategori.
///
/// Setelah user tekan "Lanjut", layar ini meneruskan:
/// - [budgetBulanan]  : nominal budget dalam double
/// - [bulan]          : bulan yang dipilih (dari date picker)
/// - [kategoriDipilih]: daftar nama kategori yang dicentang user
///
/// Semua kalkulasi (budget harian, sisa, dll) dilakukan di LayarBudgetKategori
/// menggunakan BudgetController dari algoritma_pembagian.
class LayarFormAnggaran extends StatefulWidget {
  const LayarFormAnggaran({super.key});

  @override
  State<LayarFormAnggaran> createState() => _LayarFormAnggaranState();
}

class _LayarFormAnggaranState extends State<LayarFormAnggaran> {
  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────

  DateTime? selectedDate;
  final TextEditingController _budgetController = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  final int totalStep = 3;

  /// Kategori default + kategori yang ditambah user.
  List<String> kategoriList = [
    'Makanan & Minuman',
    'Transportasi',
    'Hiburan',
    'Tabungan',
  ];

  late List<bool> isSelected;

  // ─────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    isSelected = List.generate(kategoriList.length, (_) => false);

    // Format input angka jadi rupiah otomatis saat user mengetik
    _budgetController.addListener(() {
      final raw = _budgetController.text.replaceAll('.', '');
      if (raw.isEmpty) return;
      final value = int.tryParse(raw);
      if (value == null) return;
      final formatted = _formatter.format(value).replaceAll(',', '.');
      if (formatted != _budgetController.text) {
        _budgetController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _tambahKategori() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Masukkan kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final nama = controller.text.trim();
              if (nama.isNotEmpty && !kategoriList.contains(nama)) {
                setState(() {
                  kategoriList.add(nama);
                  isSelected.add(true); // otomatis dicentang
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  /// Validasi semua field sebelum lanjut ke Page 2.
  void _lanjut() {
    // 1. Cek budget diisi
    final rawText = _budgetController.text.replaceAll('.', '');
    final budgetBulanan = double.tryParse(rawText) ?? 0;
    if (budgetBulanan <= 0) {
      _showSnackbar('Masukkan nominal budget terlebih dahulu');
      return;
    }

    // 2. Cek tanggal dipilih
    if (selectedDate == null) {
      _showSnackbar('Pilih tanggal dana masuk terlebih dahulu');
      return;
    }

    // 3. Cek minimal 1 kategori dipilih
    final dipilih = <String>[];
    for (int i = 0; i < kategoriList.length; i++) {
      if (isSelected[i]) dipilih.add(kategoriList[i]);
    }
    if (dipilih.isEmpty) {
      _showSnackbar('Pilih minimal satu kategori');
      return;
    }

    // ✅ Semua valid — teruskan ke Page 2
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LayarBudgetKategori(
          // Diteruskan ke Page 2
          budgetBulanan: budgetBulanan,
          bulan: selectedDate!,
          kategoriList: dipilih,
        ),
      ),
    );
  }

  void _showSnackbar(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double progress = 1 / totalStep;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),

              const SizedBox(height: 50),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Detail Budget',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Input Budget
                      const Text(
                        'Budget Anda',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            prefixText: 'Rp ',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Date Picker
                      const Text(
                        'Tanggal Dana Masuk',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pilihTanggal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedDate == null
                                    ? 'Pilih tanggal'
                                    : DateFormat(
                                        'dd MMMM yyyy',
                                      ).format(selectedDate!),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Kategori
                      const Text(
                        'Kategori Belanja',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 15),

                      ElevatedButton(
                        onPressed: _tambahKategori,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Buat Kategori'),
                      ),

                      const SizedBox(height: 20),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(
                          kategoriList.length,
                          (index) => GestureDetector(
                            onTap: () => setState(
                              () => isSelected[index] = !isSelected[index],
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected[index]
                                    ? const Color(0xFFD4E858)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected[index]
                                      ? const Color(0xFFD4E858)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(kategoriList[index]),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected[index] ? Icons.check : Icons.add,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Tombol Lanjut
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
                  child: const Text('Lanjut', style: TextStyle(fontSize: 22)),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
