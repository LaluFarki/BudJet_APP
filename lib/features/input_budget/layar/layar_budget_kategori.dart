import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Sesuaikan dengan nama package kamu
import 'package:budjet/features/algoritma_pembagian/algoritma_pembagian.dart';
import 'layar_analisis_budget.dart';
import '../../../../core/utils/app_helpers.dart';

/// Layar 2 dari 2: Bagi budget per kategori + validasi + simpan ke Firebase.
///
/// Menerima dari LayarFormAnggaran:
/// - [budgetBulanan]  : total budget (double)
/// - [bulan]          : bulan berlaku (DateTime)
/// - [kategoriList]   : kategori yang dipilih user di Page 1
///
/// Aturan utama: total semua alokasi HARUS tepat = budgetBulanan.
/// Tombol Simpan baru aktif kalau sisa = Rp 0.
///
/// Setelah simpan, data tersedia di Firestore:
///   budgets/{userId}/{yyyy-MM}/
///     budgetBulanan, bulan, categories[], totalPengeluaran, createdAt
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
  // ─────────────────────────────────────────
  // STATE
  // ─────────────────────────────────────────

  late List<TextEditingController> controllers;

  /// Controller algoritma — menghitung budget harian, sisa, dll.
  late final BudgetController _budgetCtrl;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // ─────────────────────────────────────────
  // COMPUTED (dari input user)
  // ─────────────────────────────────────────

  /// Total yang sudah dialokasikan user ke semua kategori.
  double get _totalDialokasikan {
    double total = 0;
    for (final c in controllers) {
      total += _parseRupiah(c.text);
    }
    return total;
  }

  /// Sisa budget yang belum dialokasikan (bisa negatif = over).
  double get _sisaBelumDialokasikan =>
      widget.budgetBulanan - _totalDialokasikan;

  /// True kalau total sudah pas = budgetBulanan (toleransi < Rp 1 untuk floating point).
  bool get _isValid => _sisaBelumDialokasikan.abs() < 1;

  // ─────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Inisialisasi BudgetController dengan data dari Page 1
    _budgetCtrl = BudgetController();
    _budgetCtrl.inisialisasi(
      budgetBulanan: widget.budgetBulanan,
      bulan: widget.bulan,
    );

    // Buat controller untuk tiap kategori, pasang listener
    controllers = List.generate(
      widget.kategoriList.length,
      (_) => TextEditingController(),
    );
    for (final c in controllers) {
      c.addListener(() => setState(() {})); // update sisa realtime
    }
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────

  /// Parsing "Rp 1.200.000" → 1200000.0
  double _parseRupiah(String text) {
    final angka = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(angka) ?? 0;
  }

  /// Format angka ke "Rp 1.200.000" dan update cursor ke akhir.
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

  // ─────────────────────────────────────────
  // LANJUT KE HALAMAN ANALISIS
  // ─────────────────────────────────────────

  void _lanjut() {
    if (_sisaBelumDialokasikan > 0.5 || _sisaBelumDialokasikan < -0.5) {
      _showValidationPopup();
      return;
    }

    // Kumpulkan alokasi per kategori
    final Map<String, double> allocations = {};
    for (int i = 0; i < widget.kategoriList.length; i++) {
      allocations[widget.kategoriList[i]] = _parseRupiah(controllers[i].text);
    }

    // Navigasi ke Layar Analisis Budget (Layar 10)
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
    final isOver = sisa < -0.5;
    final judul = isOver ? 'Budget Melebihi Batas' : 'Saldo Masih Tersisa';
    final pesan = isOver
        ? 'Total alokasi melebihi budget sebesar ${_currencyFormat.format(sisa.abs().toInt())}. Silakan kurangi alokasi Anda.'
        : 'Saldo Anda masih tersisa ${_currencyFormat.format(sisa.toInt())},\nalokasikan semua saldo anda untuk bisa simpan';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFE57373), // Warna merah/salmon seperti di lampiran
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  pesan,
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

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const int totalStep = 3;
    const double progress = 2 / totalStep;

    final sisa = _sisaBelumDialokasikan;
    final isOver = sisa < 0;

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
                child: const LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  'Budget Kategori',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              // ── Info Budget Harian (dari BudgetController) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Budget',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          _currencyFormat.format(widget.budgetBulanan.toInt()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Budget Harian',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          // hitungBudgetHarian() dari BudgetController
                          _currencyFormat.format(
                            _budgetCtrl.budgetHarian.toInt(),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF00D4AA),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Indikator Sisa Realtime ──
              // Ini adalah validasi utama: total harus pas = 0
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
                    color: _isValid
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
                      _isValid
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
                      _isValid
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

              // ── List Kategori ──
              Expanded(
                child: ListView.builder(
                  itemCount: widget.kategoriList.length,
                  itemBuilder: (context, index) {
                    final kategori = widget.kategoriList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: _getColorBg(kategori),
                            child: Icon(
                              _getIcon(kategori),
                              color: _getColor(kategori),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kategori,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: controllers[index],
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) =>
                                      _formatRupiah(controllers[index], value),
                                  decoration: InputDecoration(
                                    hintText: 'Rp 0',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  'Sudah cocok?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ── Tombol Lanjut ──
              // Selalu aktif secara visual (hijau), validasi ditangani di _lanjut()
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
