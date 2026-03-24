# 📊 Algoritma Pembagian — Daily Smart Budgeting

> **Backlog:** [MOBILE] Algoritma daily smart budgeting  
> **Dikerjakan oleh:** Resty
> **Status:** ✅ Selesai & Tested (40/40 unit test passed)  
> **Terakhir diupdate:** 16 Maret 2026

---

## 🎯 Tujuan Fitur

Membantu mahasiswa dengan uang saku terbatas agar **tidak kehabisan uang sebelum akhir periode** dengan cara:
- Menghitung budget harian otomatis dari budget bulanan
- Melacak sisa budget real-time setiap ada pengeluaran
- Memantau pengeluaran per kategori
- Menampilkan sisa jatah uang jajan hari ini

---

## 📁 Struktur Folder

```
lib/features/algoritma_pembagian/
│
├── models/
│   ├── budget_model.dart          → Data budget bulanan + kalkulasi harian & sisa
│   ├── transaction_model.dart     → Data transaksi + enum KategoriTransaksi
│   └── category_budget_model.dart → Alokasi & realisasi budget per kategori
│
├── services/
│   ├── budget_calculator_service.dart → Algoritma hitung budget harian & sisa
│   ├── spending_tracker_service.dart  → Lacak & rangkum pengeluaran
│   └── category_service.dart          → Hitung alokasi & realisasi per kategori
│
├── controllers/
│   ├── budget_controller.dart      → State budget aktif + getter 3 widget utama
│   ├── transaction_controller.dart → Tambah/hapus transaksi, ringkasan
│   └── category_controller.dart   → Atur alokasi & realisasi per kategori
│
├── utils/
│   └── date_formatter.dart        → Helper format tanggal & jam untuk UI
│
├── algoritma_pembagian.dart       → Barrel export (pintu masuk utama)
└── algoritma_playground.dart      → [SEMENTARA] UI test algoritma, hapus saat frontend jadi
```

---

## 🧠 Algoritma Inti

### Budget Harian
```
budget harian = budget bulanan ÷ jumlah hari dalam bulan
```
- Otomatis menyesuaikan jumlah hari tiap bulan (28/29/30/31)
- Otomatis handle tahun kabisat
- Contoh: Rp 3.000.000 ÷ 31 hari (Maret) = Rp 96.774/hari

### Sisa Budget Real-time
```
sisa budget = budget bulanan - total pengeluaran bulan ini
```

### Sisa Budget Hari Ini
```
sisa hari ini = budget harian - total pengeluaran hari ini
```

---

## 🎨 Getter untuk 3 Widget Utama di UI

Semua tersedia di `BudgetController` — jika mau menampilkan di UI tinggal panggil:

```dart
// Widget 1 — Saldo Saya (berubah real-time tiap ada transaksi)
_budgetCtrl.saldoSaya

// Widget 2 — Budget Hari Ini (sisa jatah uang jajan hari ini)
_budgetCtrl.sisaBudgetHariIni
_budgetCtrl.isOverBudgetHariIni  // true = over, untuk ubah warna jadi merah

// Widget 3 — Total Pengeluaran bulan ini
_budgetCtrl.totalPengeluaranBulanIni
```

### Contoh di Widget Flutter:
```dart
// Widget 2 dengan peringatan warna merah jika over
Text(
  'Rp ${_budgetCtrl.sisaBudgetHariIni.toStringAsFixed(0)}',
  style: TextStyle(
    color: _budgetCtrl.isOverBudgetHariIni ? Colors.red : Colors.green,
  ),
)
```

---

## 🔗 Cara Pakai (untuk yang membuat UI-nya)

### 1. Import cukup 1 baris
```dart
import 'package:flutter_application_1/features/algoritma_pembagian/algoritma_pembagian.dart';
```

### 2. Inisialisasi controller
```dart
final budgetCtrl = BudgetController();
final transaksiCtrl = TransactionController(
  // Wajib diset! Supaya budget otomatis hitung ulang tiap ada transaksi baru
  onTransaksiChanged: (list) => budgetCtrl.perbaruiTransaksi(list),
);
final kategoriCtrl = CategoryController();
```

### 3. Set budget bulanan (saat user input pertama kali)
```dart
budgetCtrl.inisialisasi(
  budgetBulanan: 3000000, // dari input user
  bulan: DateTime.now(),
);
```

### 4. Set alokasi per kategori (nominal rupiah, diatur user)
```dart
kategoriCtrl.aturAlokasi(KategoriTransaksi.makananMinuman, 800000);
kategoriCtrl.aturAlokasi(KategoriTransaksi.transportasi, 400000);
```

### 5. Catat transaksi (dari halaman catat pengeluaran)
```dart
// Tinggal panggil ini saat user tap tombol "Simpan" di halaman catat pengeluaran
transaksiCtrl.tambahTransaksi(TransactionModel(
  id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
  nominal: nominalDariInputUser,   // ← ambil dari variabel halaman
  kategori: kategoriDipilihUser,   // ← dari dropdown/pilihan user
  tanggal: DateTime.now(),         // ← otomatis real-time
  keterangan: keteranganInput,     // ← opsional
));
// Budget & sisa otomatis terhitung ulang setelah ini!
```
### 6. Edit transaksi (nominal / kategori / keterangan)
```dart
// Hapus yang lama, tambah yang sudah diedit
// Widget 1, 2, 3 otomatis update!

transaksiCtrl.hapusTransaksi(transaksiLama.id);

transaksiCtrl.tambahTransaksi(TransactionModel(
  id: transaksiLama.id,           // ← pakai id yang sama
  nominal: nominalBaru,           // ← nilai baru dari input user
  kategori: kategoriBaru,         // ← kategori baru
  keterangan: keteranganBaru,     // ← keterangan baru
  tanggal: transaksiLama.tanggal, // ← tanggal tetap tidak berubah
));
```
---

## 🗂️ Kategori yang Tersedia

```dart
KategoriTransaksi.makananMinuman  // Makanan & Minuman
KategoriTransaksi.transportasi    // Transportasi
KategoriTransaksi.hiburan         // Hiburan
KategoriTransaksi.kesehatan       // Kesehatan
KategoriTransaksi.belanja         // Belanja
KategoriTransaksi.tagihanUtilitas // Tagihan & Utilitas
KategoriTransaksi.lainnya         // Lainnya
```

---

## 🕐 Format Tanggal & Jam (DateFormatter)

```dart
DateFormatter.relatif(t.tanggal)       // → "Baru saja" / "5 menit yang lalu" / "Kemarin, 09:15"
DateFormatter.jamMenit(t.tanggal)      // → "14:32"
DateFormatter.tanggalPendek(t.tanggal) // → "16 Mar 2026"
DateFormatter.tanggalPanjang(t.tanggal)// → "Senin, 16 Maret 2026"
DateFormatter.bulanTahun(DateTime.now())// → "Maret 2026"
DateFormatter.lengkap(t.tanggal)       // → "16 Mar 2026, 14:32"
DateFormatter.pendekDenganJam(t.tanggal)// → "16/03 • 14:32"
```

> ⚠️ `DateFormatter` butuh package `intl: ^0.19.0` di `pubspec.yaml`

---

## 🏗️ Arsitektur

```
UI (Widget/Screen)
      ↓ panggil method
Controllers  ←→  Services (logika murni)
                     ↓
                  Models (data)
```

**Aturan penting:**
- `services/` = logika murni, **tidak boleh** akses UI
- `controllers/` = satu-satunya yang boleh diakses dari Widget/Screen
- `models/` = struktur data saja, tidak ada logika bisnis

---

## ✅ Unit Test

File test: `test/algoritma_pembagian_test.dart`

```bash
flutter test test/algoritma_pembagian_test.dart --reporter expanded
```

**Hasil: 40/40 tests passed ✅**

| Group | Jumlah Test |
|---|---|
| BudgetModel | 6 |
| TransactionModel | 4 |
| CategoryBudgetModel | 3 |
| BudgetCalculatorService | 5 |
| SpendingTrackerService | 5 |
| CategoryService | 4 |
| BudgetController | 4 |
| TransactionController | 3 |
| CategoryController | 6 |
| **Total** | **40** |

---

## 🔄 Alur Lengkap

```
User input budget bulanan
        ↓
BudgetController.inisialisasi()
        ↓
User atur alokasi per kategori
        ↓
CategoryController.aturAlokasi()
        ↓
User catat pengeluaran (dari halaman lain)
        ↓
TransactionController.tambahTransaksi()
        ↓ otomatis trigger onTransaksiChanged
BudgetController.perbaruiTransaksi()
        ↓ otomatis hitung ulang
saldoSaya ✓  sisaBudgetHariIni ✓  totalPengeluaranBulanIni ✓
        ↓
Tampil real-time di 3 widget utama
```

---

## 📝 Catatan untuk Session Berikutnya

Jika melanjutkan pengembangan fitur ini di chat baru, paste README ini agar Claude langsung paham kondisi project tanpa penjelasan ulang.

**File yang sudah final & tidak perlu diubah:**
- Semua file di `models/` ✅
- Semua file di `services/` ✅
- `transaction_controller.dart` ✅
- `category_controller.dart` ✅
- `utils/date_formatter.dart` ✅
- `algoritma_pembagian.dart` (barrel export) ✅

**File yang mungkin perlu update:**
- `budget_controller.dart` — jika ada getter baru yang dibutuhkan UI
- `algoritma_playground.dart` — file sementara, hapus saat frontend jadi

**Dependensi tambahan yang sudah ditambahkan:**
- `intl: ^0.19.0` → untuk DateFormatter
