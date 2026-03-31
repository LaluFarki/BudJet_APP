import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Sesuaikan dengan nama package kamu
import 'package:flutter_application_1/features/algoritma_pembagian/algoritma_pembagian.dart';
import 'package:flutter_application_1/features/algoritma_pembagian/utils/date_formatter.dart';

/// ─────────────────────────────────────────────────────────────
/// PLAYGROUND — Test Algoritma Pembagian Budget
///
/// Cara pakai:
/// 1. Taruh file ini di lib/features/algoritma_pembagian/
/// 2. Di main.dart, ganti home: sementara jadi:
///    home: const AlgoritmaPlayground(),
/// 3. Jalankan app, coba-coba input nominalnya
/// 4. Kalau sudah oke, kembalikan home: ke widget aslinya
/// ─────────────────────────────────────────────────────────────

// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: AlgoritmaPlayground(),
//   ));
// }

class AlgoritmaPlayground extends StatefulWidget {
  const AlgoritmaPlayground({super.key});

  @override
  State<AlgoritmaPlayground> createState() => _AlgoritmaPlaygroundState();
}

class _AlgoritmaPlaygroundState extends State<AlgoritmaPlayground> {
  // Controllers
  final _budgetCtrl = BudgetController();
  late final TransactionController _transaksiCtrl;
  final _kategoriCtrl = CategoryController();

  // Form controllers
  final _budgetInput = TextEditingController(text: '3000000');
  final _nominalInput = TextEditingController();
  final _keteranganInput = TextEditingController();
  KategoriTransaksi _kategoriDipilih = KategoriTransaksi.makananMinuman;

  // Alokasi kategori (input fields)
  final Map<KategoriTransaksi, TextEditingController> _alokasiInputs = {
    for (final k in KategoriTransaksi.values)
      k: TextEditingController(text: '0'),
  };

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _transaksiCtrl = TransactionController(
      onTransaksiChanged: (list) {
        _budgetCtrl.perbaruiTransaksi(list);
        _kategoriCtrl.perbaruiRealisasi(
          transaksi: list,
          bulan: DateTime.now(),
        );
        setState(() {});
      },
    );
    // Inisialisasi budget awal
    _inisialisasiBudget();
  }

  void _inisialisasiBudget() {
    final nominal = double.tryParse(_budgetInput.text) ?? 0;
    if (nominal > 0) {
      _budgetCtrl.inisialisasi(
        budgetBulanan: nominal,
        bulan: DateTime.now(),
      );
      // Set alokasi default dari input
      _terapkanAlokasi();
      setState(() {});
    }
  }

  void _terapkanAlokasi() {
    for (final entry in _alokasiInputs.entries) {
      final nominal = double.tryParse(entry.value.text) ?? 0;
      _kategoriCtrl.aturAlokasi(entry.key, nominal);
    }
    _kategoriCtrl.perbaruiRealisasi(
      transaksi: _transaksiCtrl.semuaTransaksi,
      bulan: DateTime.now(),
    );
    setState(() {});
  }

  void _tambahTransaksi() {
    final nominal = double.tryParse(_nominalInput.text) ?? 0;
    if (nominal <= 0) return;

    final id = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    _transaksiCtrl.tambahTransaksi(TransactionModel(
      id: id,
      nominal: nominal,
      kategori: _kategoriDipilih,
      tanggal: DateTime.now(),
      keterangan: _keteranganInput.text.isEmpty ? null : _keteranganInput.text,
    ));

    _nominalInput.clear();
    _keteranganInput.clear();
  }

  @override
  void dispose() {
    _budgetInput.dispose();
    _nominalInput.dispose();
    _keteranganInput.dispose();
    for (final c in _alokasiInputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '🧪 Playground — Algoritma Budget',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _tabBtn(0, 'Budget & Transaksi'),
              _tabBtn(1, 'Kategori'),
              _tabBtn(2, 'Hasil'),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _tabBudgetTransaksi(),
          _tabKategori(),
          _tabHasil(),
        ],
      ),
    );
  }

  Widget _tabBtn(int index, String label) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF00D4AA) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF00D4AA) : Colors.white60,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 1: Budget & Transaksi
  // ─────────────────────────────────────────
  Widget _tabBudgetTransaksi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Set Budget Bulanan
          _sectionCard(
            title: '💰 Set Budget Bulanan',
            child: Row(
              children: [
                Expanded(
                  child: _inputField(
                    controller: _budgetInput,
                    label: 'Nominal (Rp)',
                    hint: 'contoh: 3000000',
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _inisialisasiBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  child: const Text('Set',
                      style: TextStyle(color: Color(0xFF00D4AA))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tambah Transaksi
          _sectionCard(
            title: '➕ Tambah Transaksi',
            child: Column(
              children: [
                _inputField(
                  controller: _nominalInput,
                  label: 'Nominal Pengeluaran (Rp)',
                  hint: 'contoh: 25000',
                ),
                const SizedBox(height: 12),
                _inputField(
                  controller: _keteranganInput,
                  label: 'Keterangan (opsional)',
                  hint: 'contoh: Makan siang',
                  isNumber: false,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<KategoriTransaksi>(
                  initialValue: _kategoriDipilih,
                  decoration: _inputDecoration('Kategori'),
                  items: KategoriTransaksi.values
                      .map((k) => DropdownMenuItem(
                            value: k,
                            child: Text(k.label),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _kategoriDipilih = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _tambahTransaksi,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Tambah Transaksi',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daftar Transaksi
          _sectionCard(
            title:
                '📋 Transaksi (${_transaksiCtrl.semuaTransaksi.length})',
            child: _transaksiCtrl.semuaTransaksi.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Belum ada transaksi',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: _transaksiCtrl.transaksiTerbaru(limit: 999)
                        .map((t) => _transaksiTile(t))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _transaksiTile(TransactionModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.keterangan ?? t.kategori.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                    '${t.kategori.label}  •  ${DateFormatter.relatif(t.tanggal)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '- Rp ${_formatAngka(t.nominal)}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
            onPressed: () => _transaksiCtrl.hapusTransaksi(t.id),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 2: Kategori
  // ─────────────────────────────────────────
  Widget _tabKategori() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _sectionCard(
            title: '🗂️ Atur Alokasi per Kategori (Rp)',
            child: Column(
              children: [
                ...KategoriTransaksi.values.map((k) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: Text(k.label,
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Expanded(
                            child: _inputField(
                              controller: _alokasiInputs[k]!,
                              label: '',
                              hint: '0',
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                // Validasi total alokasi
                if (_budgetCtrl.sudahDiinisialisasi)
                  _infoChip(
                    label:
                        'Sisa belum dialokasikan: Rp ${_formatAngka(_kategoriCtrl.sisaAlokasiDari(_budgetCtrl.budget!.budgetBulanan))}',
                    isWarning: _kategoriCtrl
                        .isAlokasiMelebihi(_budgetCtrl.budget!.budgetBulanan),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _terapkanAlokasi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Terapkan Alokasi',
                        style: TextStyle(color: Color(0xFF00D4AA))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 3: Hasil Algoritma
  // ─────────────────────────────────────────
  Widget _tabHasil() {
    if (!_budgetCtrl.sudahDiinisialisasi) {
      return const Center(
        child: Text('Set budget bulanan dulu di tab pertama!'),
      );
    }

    final ringkasanHarian =
        _transaksiCtrl.ringkasanHariIni();
    final ringkasanBulanan =
        _transaksiCtrl.ringkasanBulanan(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _resultCard(
                  label: 'Budget Bulanan',
                  value:
                      'Rp ${_formatAngka(_budgetCtrl.budget!.budgetBulanan)}',
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _resultCard(
                  label: 'Budget Harian',
                  value: 'Rp ${_formatAngka(_budgetCtrl.budgetHarian)}',
                  color: const Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _resultCard(
                  label: 'Total Pengeluaran',
                  value:
                      'Rp ${_formatAngka(_budgetCtrl.totalPengeluaran)}',
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _resultCard(
                  label: 'Sisa Budget',
                  value: 'Rp ${_formatAngka(_budgetCtrl.sisaBudget)}',
                  color: _budgetCtrl.isMelebihiBudget
                      ? Colors.red
                      : const Color(0xFF00D4AA),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar pemakaian
          _sectionCard(
            title: '📊 Pemakaian Budget Bulanan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(_budgetCtrl.persentasePemakaian * 100).toStringAsFixed(1)}% terpakai',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _budgetCtrl.isMelebihiBudget
                          ? '⚠️ Over Budget!'
                          : '✅ Aman',
                      style: TextStyle(
                        color: _budgetCtrl.isMelebihiBudget
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _budgetCtrl.persentasePemakaian.clamp(0.0, 1.0),
                    minHeight: 16,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      _budgetCtrl.isMelebihiBudget
                          ? Colors.red
                          : const Color(0xFF00D4AA),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Harian
          _sectionCard(
            title: '🌤️ Hari Ini',
            child: Column(
              children: [
                _resultRow('Pengeluaran hari ini',
                    'Rp ${_formatAngka(ringkasanHarian.total)}'),
                _resultRow('Jumlah transaksi',
                    '${ringkasanHarian.jumlahTransaksi} transaksi'),
                _resultRow(
                  'Selisih vs budget harian',
                  _budgetCtrl.selisihBudgetHariIni >= 0
                      ? '⚠️ Over Rp ${_formatAngka(_budgetCtrl.selisihBudgetHariIni)}'
                      : '✅ Sisa Rp ${_formatAngka(_budgetCtrl.selisihBudgetHariIni.abs())}',
                ),
                _resultRow('Budget kumulatif seharusnya',
                    'Rp ${_formatAngka(_budgetCtrl.budgetKumulatifSeharusnya)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Per Kategori
          if (_kategoriCtrl.kategoriList.isNotEmpty)
            _sectionCard(
              title: '🗂️ Realisasi per Kategori',
              child: Column(
                children: _kategoriCtrl.kategoriList
                    .where((k) => k.budgetDiAlokasikan > 0)
                    .map((k) => _kategoriRow(k))
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Kategori terboros
          if (_kategoriCtrl.kategoriTerboros != null)
            _sectionCard(
              title: '🔥 Kategori Terboros',
              child: _resultRow(
                _kategoriCtrl.kategoriTerboros!.kategori.label,
                'Rp ${_formatAngka(_kategoriCtrl.kategoriTerboros!.totalDigunakan)}',
              ),
            ),
          const SizedBox(height: 16),

          // Kategori over budget
          if (_kategoriCtrl.kategoriOverBudget.isNotEmpty)
            _sectionCard(
              title:
                  '⚠️ Kategori Over Alokasi (${_kategoriCtrl.kategoriOverBudget.length})',
              child: Column(
                children: _kategoriCtrl.kategoriOverBudget
                    .map((k) => _resultRow(
                          k.kategori.label,
                          'Over Rp ${_formatAngka((k.totalDigunakan - k.budgetDiAlokasikan).abs())}',
                          valueColor: Colors.red,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _resultCard({
    required String label,
    required String value,
    required Color color,
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: textColor.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              )),
        ],
      ),
    );
  }

  Widget _kategoriRow(CategoryBudgetModel k) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k.kategori.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              Text(
                'Rp ${_formatAngka(k.totalDigunakan)} / Rp ${_formatAngka(k.budgetDiAlokasikan)}',
                style: TextStyle(
                  fontSize: 12,
                  color: k.isMelebihiAlokasi ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: k.persentasePemakaian.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                k.isMelebihiAlokasi ? Colors.red : const Color(0xFF00D4AA),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required String label, bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.red.shade50
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isWarning ? Colors.red.shade700 : Colors.green.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters:
          isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      filled: true,
      fillColor: const Color(0xFFF5F5F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  String _formatAngka(double angka) {
    // Format: 1000000 → 1.000.000
    final parts = angka.toStringAsFixed(0).split('');
    final result = <String>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return result.join();
  }
}