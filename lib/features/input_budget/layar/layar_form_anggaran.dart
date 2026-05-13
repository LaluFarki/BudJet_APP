import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Sesuaikan dengan nama package kamu

import 'layar_budget_kategori.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../../../core/utils/validation_helper.dart';

class LayarFormAnggaran extends StatefulWidget {
  const LayarFormAnggaran({super.key});

  @override
  State<LayarFormAnggaran> createState() => _LayarFormAnggaranState();
}

class _LayarFormAnggaranState extends State<LayarFormAnggaran> {
  DateTime? selectedDate;
  final TextEditingController _budgetController = TextEditingController();
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');
  bool _showBudgetWarning = false;
  Timer? _budgetWarningTimer;

  final int totalStep = 3;

  List<String> kategoriList = [
    'Makanan & Minuman',
    'Transportasi',
    'Hiburan',
    'Tabungan',
  ];

  late List<bool> isSelected;

  @override
  void initState() {
    super.initState();
    isSelected = List.generate(kategoriList.length, (_) => false);

    // Budget controller listener removed, handled by RupiahInputFormatter
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _budgetWarningTimer?.cancel();
    super.dispose();
  }

  // 🔥 FINAL PERUBAHAN ADA DI SINI
  Future<void> _pilihTanggal() async {
    final DateTime today = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(2020),
      lastDate: today, // 🔥 MAKSIMAL = HARI INI
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _tambahKategori() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool showNameWarning = false;
          Timer? nameWarningTimer;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  
                  // Title and Subtitle
                  const Text(
                    'Kategori Baru',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan kategori pengeluaran khusus\nuntuk kemudahan pencatatan Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nama Kategori',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: showNameWarning ? Colors.red.shade300 : Colors.grey.shade200,
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          onChanged: (val) {
                            if (val.length < 20 && showNameWarning) {
                              setDialogState(() => showNameWarning = false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Misal: Belanja Bulanan',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              if (newValue.text.length > 20) {
                                if (!showNameWarning) {
                                  nameWarningTimer?.cancel();
                                  setDialogState(() => showNameWarning = true);
                                  nameWarningTimer = Timer(const Duration(seconds: 3), () {
                                    if (context.mounted) {
                                      setDialogState(() => showNameWarning = false);
                                    }
                                  });
                                }
                                return oldValue;
                              }
                              return newValue;
                            }),
                          ],
                        ),
                      ),
                      if (showNameWarning)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 12, color: Colors.red.shade400),
                              const SizedBox(width: 4),
                              Text(
                                'Maksimal 20 Karakter!',
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final nama = controller.text.trim();
                            if (ValidationHelper.isLengthExceeded(nama, 20)) return;
                            if (nama.isNotEmpty && !kategoriList.contains(nama)) {
                              setState(() {
                                kategoriList.add(nama);
                                isSelected.add(true);
                              });
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6E85A),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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

  void _lanjut() {
    final rawText = _budgetController.text.replaceAll('.', '');
    final budgetBulanan = double.tryParse(rawText) ?? 0;
    if (budgetBulanan <= 0) {
      _showSnackbar('Masukkan nominal budget terlebih dahulu');
      return;
    }

    if (selectedDate == null) {
      _showSnackbar('Pilih tanggal dana masuk terlebih dahulu');
      return;
    }

    final dipilih = <String>[];
    for (int i = 0; i < kategoriList.length; i++) {
      if (isSelected[i]) dipilih.add(kategoriList[i]);
    }
    if (dipilih.isEmpty) {
      _showSnackbar('Pilih minimal satu kategori');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LayarBudgetKategori(
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

                      const Text(
                        'Budget Anda',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: _showBudgetWarning ? 4 : 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              onChanged: (val) {
                                final amount = ValidationHelper.parseRupiah(val);
                                if (amount < 100000000 && _showBudgetWarning) {
                                  setState(() => _showBudgetWarning = false);
                                }
                              },
                              inputFormatters: [
                                RupiahInputFormatter(
                                  max: 100000000,
                                  onMaxExceeded: () {
                                    if (!_showBudgetWarning) {
                                      _budgetWarningTimer?.cancel();
                                      setState(() => _showBudgetWarning = true);
                                      _budgetWarningTimer = Timer(const Duration(milliseconds: 2200), () {
                                        if (mounted) setState(() => _showBudgetWarning = false);
                                      });
                                    }
                                  },
                                ),
                              ],
                              decoration: const InputDecoration(
                                prefixText: 'Rp ',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Harap masukkan anggaran';
                                }
                                return null;
                              },
                            ),
                            if (_showBudgetWarning)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
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
                      ),

                      const SizedBox(height: 25),

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
                                    : DateFormat('dd MMMM yyyy')
                                    .format(selectedDate!),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Kategori Belanja',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 15),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Tombol Tambah Kategori Spesial
                          GestureDetector(
                            onTap: _tambahKategori,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Buat Kategori',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // List Kategori
                          ...List.generate(
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
                                    Icon(
                                      AppHelpers.getCategoryIcon(
                                          kategoriList[index]),
                                      size: 18,
                                      color: isSelected[index]
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      kategoriList[index],
                                      style: TextStyle(
                                        color: isSelected[index]
                                            ? Colors.black87
                                            : Colors.grey.shade700,
                                        fontWeight: isSelected[index]
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isSelected[index]
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      size: 14,
                                      color: isSelected[index]
                                          ? Colors.black54
                                          : Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
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
                  child: const Text('Lanjut',
                      style: TextStyle(fontSize: 22)),
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