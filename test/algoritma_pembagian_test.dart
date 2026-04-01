import 'package:flutter_test/flutter_test.dart';

// Sesuaikan 'nama_app' dengan nama package di pubspec.yaml kamu
import 'package:budjet/features/algoritma_pembagian/algoritma_pembagian.dart';

void main() {
  // ─────────────────────────────────────────
  // GROUP 1: BudgetModel
  // ─────────────────────────────────────────
  group('BudgetModel', () {
    test('budget harian = budget bulanan ÷ jumlah hari dalam bulan', () {
      final budget = BudgetModel(
        budgetBulanan: 3100000, // Rp 3.100.000
        bulan: DateTime(2024, 1), // Januari = 31 hari
      );

      // 3.100.000 ÷ 31 = 100.000 per hari
      expect(budget.budgetHarian, equals(100000.0));
    });

    test('sisa budget = budget bulanan - total pengeluaran', () {
      final budget = BudgetModel(
        budgetBulanan: 3000000,
        bulan: DateTime(2024, 1),
        totalPengeluaran: 500000,
      );

      expect(budget.sisaBudget, equals(2500000.0));
    });

    test('isMelebihiBudget = true jika pengeluaran > budget', () {
      final budget = BudgetModel(
        budgetBulanan: 3000000,
        bulan: DateTime(2024, 1),
        totalPengeluaran: 3500000, // over Rp 500.000
      );

      expect(budget.isMelebihiBudget, isTrue);
    });

    test('isMelebihiBudget = false jika pengeluaran masih di bawah budget', () {
      final budget = BudgetModel(
        budgetBulanan: 3000000,
        bulan: DateTime(2024, 1),
        totalPengeluaran: 1000000,
      );

      expect(budget.isMelebihiBudget, isFalse);
    });

    test('persentasePemakaian dihitung dengan benar', () {
      final budget = BudgetModel(
        budgetBulanan: 3000000,
        bulan: DateTime(2024, 1),
        totalPengeluaran: 1500000, // 50%
      );

      expect(budget.persentasePemakaian, equals(0.5));
    });

    test('copyWith menghasilkan objek baru dengan nilai yang diubah', () {
      final budget = BudgetModel(
        budgetBulanan: 3000000,
        bulan: DateTime(2024, 1),
      );
      final budgetBaru = budget.copyWith(budgetBulanan: 5000000);

      expect(budgetBaru.budgetBulanan, equals(5000000));
      expect(budgetBaru.bulan, equals(budget.bulan)); // bulan tidak berubah
    });
  });

  // ─────────────────────────────────────────
  // GROUP 2: TransactionModel
  // ─────────────────────────────────────────
  group('TransactionModel', () {
    test('fromMap dan toMap saling konsisten', () {
      final original = TransactionModel(
        id: 'txn_001',
        nominal: 25000,
        kategori: KategoriTransaksi.makananMinuman,
        tanggal: DateTime(2024, 1, 15, 12, 0),
        keterangan: 'Makan siang',
      );

      final map = original.toMap();
      final hasil = TransactionModel.fromMap(map);

      expect(hasil.id, equals(original.id));
      expect(hasil.nominal, equals(original.nominal));
      expect(hasil.kategori, equals(original.kategori));
      expect(hasil.keterangan, equals(original.keterangan));
    });

    test('KategoriTransaksi.label mengembalikan teks yang benar', () {
      expect(KategoriTransaksi.makananMinuman.label, equals('Makanan & Minuman'));
      expect(KategoriTransaksi.transportasi.label, equals('Transportasi'));
    });

    test('KategoriTransaksi.fromString mengembalikan enum yang tepat', () {
      expect(
        KategoriTransaksi.fromString('makananMinuman'),
        equals(KategoriTransaksi.makananMinuman),
      );
    });

    test('KategoriTransaksi.fromString fallback ke lainnya jika tidak dikenal', () {
      expect(
        KategoriTransaksi.fromString('kategoriTidakAda'),
        equals(KategoriTransaksi.lainnya),
      );
    });
  });

  // ─────────────────────────────────────────
  // GROUP 3: CategoryBudgetModel
  // ─────────────────────────────────────────
  group('CategoryBudgetModel', () {
    test('sisaBudgetKategori dihitung dengan benar', () {
      final kategori = CategoryBudgetModel(
        kategori: KategoriTransaksi.makananMinuman,
        budgetDiAlokasikan: 800000,
        totalDigunakan: 300000,
      );

      expect(kategori.sisaBudgetKategori, equals(500000.0));
    });

    test('isMelebihiAlokasi = true jika pengeluaran > alokasi', () {
      final kategori = CategoryBudgetModel(
        kategori: KategoriTransaksi.hiburan,
        budgetDiAlokasikan: 200000,
        totalDigunakan: 250000,
      );

      expect(kategori.isMelebihiAlokasi, isTrue);
    });

    test('persentasePemakaian = 0 jika alokasi 0', () {
      final kategori = CategoryBudgetModel(
        kategori: KategoriTransaksi.lainnya,
        budgetDiAlokasikan: 0,
        totalDigunakan: 0,
      );

      expect(kategori.persentasePemakaian, equals(0.0));
    });
  });

  // ─────────────────────────────────────────
  // GROUP 4: BudgetCalculatorService
  // ─────────────────────────────────────────
  group('BudgetCalculatorService', () {
    late BudgetCalculatorService service;

    setUp(() {
      service = const BudgetCalculatorService();
    });

    test('hitungBudgetHarian benar untuk bulan 31 hari', () {
      final hasil = service.hitungBudgetHarian(
        budgetBulanan: 3100000,
        bulan: DateTime(2024, 1), // Januari = 31 hari
      );
      expect(hasil, equals(100000.0));
    });

    test('hitungBudgetHarian benar untuk bulan 28 hari', () {
      final hasil = service.hitungBudgetHarian(
        budgetBulanan: 2800000,
        bulan: DateTime(2023, 2), // Februari 2023 = 28 hari
      );
      expect(hasil, equals(100000.0));
    });

    test('hitungSisaBudget mengembalikan nilai negatif jika over', () {
      final hasil = service.hitungSisaBudget(
        budgetBulanan: 3000000,
        totalPengeluaran: 3200000,
      );
      expect(hasil, equals(-200000.0));
    });

    test('hitungTotalPengeluaran hanya menjumlah transaksi di bulan yang sama', () {
      final transaksi = [
        TransactionModel(
          id: '1',
          nominal: 50000,
          kategori: KategoriTransaksi.makananMinuman,
          tanggal: DateTime(2024, 1, 10), // Januari ✓
        ),
        TransactionModel(
          id: '2',
          nominal: 100000,
          kategori: KategoriTransaksi.transportasi,
          tanggal: DateTime(2024, 1, 20), // Januari ✓
        ),
        TransactionModel(
          id: '3',
          nominal: 999999,
          kategori: KategoriTransaksi.belanja,
          tanggal: DateTime(2024, 2, 1), // Februari ✗ (tidak dihitung)
        ),
      ];

      final total = service.hitungTotalPengeluaran(
        transaksi: transaksi,
        bulan: DateTime(2024, 1),
      );

      expect(total, equals(150000.0)); // hanya txn 1 + 2
    });

    test('perbaruiBudget mengupdate totalPengeluaran dari transaksi', () {
      final budget = BudgetModel(
        budgetBulanan: 3000000,
        bulan: DateTime(2024, 1),
      );
      final transaksi = [
        TransactionModel(
          id: '1',
          nominal: 200000,
          kategori: KategoriTransaksi.makananMinuman,
          tanggal: DateTime(2024, 1, 5),
        ),
      ];

      final hasil = service.perbaruiBudget(budget: budget, transaksi: transaksi);
      expect(hasil.totalPengeluaran, equals(200000.0));
    });
  });

  // ─────────────────────────────────────────
  // GROUP 5: SpendingTrackerService
  // ─────────────────────────────────────────
  group('SpendingTrackerService', () {
    late SpendingTrackerService service;
    late List<TransactionModel> dummyTransaksi;

    setUp(() {
      service = const SpendingTrackerService();
      dummyTransaksi = [
        TransactionModel(
          id: '1',
          nominal: 50000,
          kategori: KategoriTransaksi.makananMinuman,
          tanggal: DateTime(2024, 1, 10),
        ),
        TransactionModel(
          id: '2',
          nominal: 30000,
          kategori: KategoriTransaksi.transportasi,
          tanggal: DateTime(2024, 1, 10),
        ),
        TransactionModel(
          id: '3',
          nominal: 200000,
          kategori: KategoriTransaksi.belanja,
          tanggal: DateTime(2024, 1, 20),
        ),
      ];
    });

    test('ringkasanBulanan total dan jumlah transaksi benar', () {
      final hasil = service.ringkasanBulanan(
        transaksi: dummyTransaksi,
        bulan: DateTime(2024, 1),
      );

      expect(hasil.total, equals(280000.0));
      expect(hasil.jumlahTransaksi, equals(3));
    });

    test('ringkasanBulanan mengembalikan total 0 jika tidak ada transaksi', () {
      final hasil = service.ringkasanBulanan(
        transaksi: [],
        bulan: DateTime(2024, 1),
      );

      expect(hasil.total, equals(0.0));
      expect(hasil.jumlahTransaksi, equals(0));
    });

    test('transaksiTerbesar diidentifikasi dengan benar', () {
      final hasil = service.ringkasanBulanan(
        transaksi: dummyTransaksi,
        bulan: DateTime(2024, 1),
      );

      expect(hasil.transaksiTerbesar?.nominal, equals(200000.0));
    });

    test('pengeluaranPerHari mengelompokkan dengan benar', () {
      final hasil = service.pengeluaranPerHari(
        transaksi: dummyTransaksi,
        bulan: DateTime(2024, 1),
      );

      expect(hasil[10], equals(80000.0));  // txn 1 + 2 di tgl 10
      expect(hasil[20], equals(200000.0)); // txn 3 di tgl 20
      expect(hasil[15], isNull);           // tidak ada transaksi tgl 15
    });

    test('transaksiTerbaru mengembalikan N transaksi urut dari terbaru', () {
      final hasil = service.transaksiTerbaru(
        transaksi: dummyTransaksi,
        limit: 2,
      );

      expect(hasil.length, equals(2));
      expect(hasil.first.id, equals('3')); // tgl 20 = paling baru
    });
  });

  // ─────────────────────────────────────────
  // GROUP 6: CategoryService
  // ─────────────────────────────────────────
  group('CategoryService', () {
    late CategoryService service;

    setUp(() {
      service = const CategoryService();
    });

    test('hitungRealisasiPerKategori mencocokkan alokasi dengan transaksi', () {
      final alokasi = {
        KategoriTransaksi.makananMinuman: 800000.0,
        KategoriTransaksi.transportasi: 400000.0,
      };
      final transaksi = [
        TransactionModel(
          id: '1',
          nominal: 50000,
          kategori: KategoriTransaksi.makananMinuman,
          tanggal: DateTime(2024, 1, 10),
        ),
        TransactionModel(
          id: '2',
          nominal: 30000,
          kategori: KategoriTransaksi.makananMinuman,
          tanggal: DateTime(2024, 1, 15),
        ),
        TransactionModel(
          id: '3',
          nominal: 20000,
          kategori: KategoriTransaksi.transportasi,
          tanggal: DateTime(2024, 1, 10),
        ),
      ];

      final hasil = service.hitungRealisasiPerKategori(
        alokasiBudget: alokasi,
        transaksi: transaksi,
        bulan: DateTime(2024, 1),
      );

      final makan = hasil.firstWhere(
        (k) => k.kategori == KategoriTransaksi.makananMinuman,
      );
      final transport = hasil.firstWhere(
        (k) => k.kategori == KategoriTransaksi.transportasi,
      );

      expect(makan.totalDigunakan, equals(80000.0));   // 50k + 30k
      expect(makan.sisaBudgetKategori, equals(720000.0));
      expect(transport.totalDigunakan, equals(20000.0));
    });

    test('hitungSisaAlokasi benar jika ada sisa', () {
      final alokasi = {
        KategoriTransaksi.makananMinuman: 800000.0,
        KategoriTransaksi.transportasi: 400000.0,
      };

      final sisa = service.hitungSisaAlokasi(
        budgetBulanan: 3000000,
        alokasiBudget: alokasi,
      );

      expect(sisa, equals(1800000.0)); // 3jt - 1.2jt
    });

    test('isTotalAlokasiMelebihi = true jika alokasi > budget', () {
      final alokasi = {
        KategoriTransaksi.makananMinuman: 2000000.0,
        KategoriTransaksi.transportasi: 2000000.0, // total 4jt > 3jt
      };

      expect(
        service.isTotalAlokasiMelebihi(
          budgetBulanan: 3000000,
          alokasiBudget: alokasi,
        ),
        isTrue,
      );
    });

    test('kategoriTerboros mengembalikan kategori dengan pengeluaran terbesar', () {
      final list = [
        const CategoryBudgetModel(
          kategori: KategoriTransaksi.makananMinuman,
          budgetDiAlokasikan: 800000,
          totalDigunakan: 600000,
        ),
        const CategoryBudgetModel(
          kategori: KategoriTransaksi.hiburan,
          budgetDiAlokasikan: 200000,
          totalDigunakan: 190000,
        ),
      ];

      expect(
        service.kategoriTerboros(list)?.kategori,
        equals(KategoriTransaksi.makananMinuman),
      );
    });
  });

  // ─────────────────────────────────────────
  // GROUP 7: BudgetController
  // ─────────────────────────────────────────
  group('BudgetController', () {
    late BudgetController controller;

    setUp(() {
      controller = BudgetController();
    });

    test('belum diinisialisasi → semua getter return 0 atau false', () {
      expect(controller.budgetHarian, equals(0));
      expect(controller.sisaBudget, equals(0));
      expect(controller.isMelebihiBudget, isFalse);
      expect(controller.sudahDiinisialisasi, isFalse);
    });

    test('setelah inisialisasi, budgetHarian terhitung otomatis', () {
      controller.inisialisasi(
        budgetBulanan: 3100000,
        bulan: DateTime(2024, 1), // 31 hari
      );

      expect(controller.budgetHarian, equals(100000.0));
      expect(controller.sudahDiinisialisasi, isTrue);
    });

    test('perbaruiTransaksi mengubah totalPengeluaran dan sisaBudget', () {
      controller.inisialisasi(
        budgetBulanan: 3000000,
        bulan: DateTime(2024, 1),
      );

      controller.perbaruiTransaksi([
        TransactionModel(
          id: '1',
          nominal: 500000,
          kategori: KategoriTransaksi.makananMinuman,
          tanggal: DateTime(2024, 1, 5),
        ),
      ]);

      expect(controller.totalPengeluaran, equals(500000.0));
      expect(controller.sisaBudget, equals(2500000.0));
    });

    test('ubahBudgetBulanan memperbarui kalkulasi', () {
      controller.inisialisasi(
        budgetBulanan: 3000000,
        bulan: DateTime(2024, 1),
      );
      controller.ubahBudgetBulanan(6200000);

      expect(controller.budgetHarian, equals(200000.0)); // 6.2jt ÷ 31
    });
  });

  // ─────────────────────────────────────────
  // GROUP 8: TransactionController
  // ─────────────────────────────────────────
  group('TransactionController', () {
    late TransactionController controller;

    setUp(() {
      controller = TransactionController();
    });

    test('tambahTransaksi menambah ke daftar', () {
      controller.tambahTransaksi(TransactionModel(
        id: 'txn_1',
        nominal: 50000,
        kategori: KategoriTransaksi.makananMinuman,
        tanggal: DateTime.now(),
      ));

      expect(controller.semuaTransaksi.length, equals(1));
    });

    test('hapusTransaksi menghapus berdasarkan ID', () {
      controller.tambahTransaksi(TransactionModel(
        id: 'txn_hapus',
        nominal: 10000,
        kategori: KategoriTransaksi.lainnya,
        tanggal: DateTime.now(),
      ));
      controller.hapusTransaksi('txn_hapus');

      expect(controller.semuaTransaksi, isEmpty);
    });

    test('onTransaksiChanged dipanggil saat transaksi berubah', () {
      int callCount = 0;
      final ctrl = TransactionController(
        onTransaksiChanged: (_) => callCount++,
      );

      ctrl.tambahTransaksi(TransactionModel(
        id: 'x',
        nominal: 1000,
        kategori: KategoriTransaksi.lainnya,
        tanggal: DateTime.now(),
      ));

      expect(callCount, equals(1));
    });
  });

  // ─────────────────────────────────────────
  // GROUP 9: CategoryController
  // ─────────────────────────────────────────
  group('CategoryController', () {
    late CategoryController controller;

    setUp(() {
      controller = CategoryController();
    });

    test('aturAlokasi menyimpan nominal dengan benar', () {
      controller.aturAlokasi(KategoriTransaksi.makananMinuman, 800000);
      expect(
        controller.alokasiBudget[KategoriTransaksi.makananMinuman],
        equals(800000.0),
      );
    });

    test('totalAlokasi menjumlahkan semua alokasi', () {
      controller.aturAlokasi(KategoriTransaksi.makananMinuman, 800000);
      controller.aturAlokasi(KategoriTransaksi.transportasi, 400000);

      expect(controller.totalAlokasi, equals(1200000.0));
    });

    test('isAlokasiMelebihi = true jika total alokasi > budget', () {
      controller.aturAlokasi(KategoriTransaksi.makananMinuman, 2000000);
      controller.aturAlokasi(KategoriTransaksi.hiburan, 2000000);

      expect(controller.isAlokasiMelebihi(3000000), isTrue);
    });

    test('perbaruiRealisasi mengisi kategoriList dari transaksi', () {
      controller.aturAlokasi(KategoriTransaksi.makananMinuman, 800000);

      controller.perbaruiRealisasi(
        transaksi: [
          TransactionModel(
            id: '1',
            nominal: 100000,
            kategori: KategoriTransaksi.makananMinuman,
            tanggal: DateTime(2024, 1, 10),
          ),
        ],
        bulan: DateTime(2024, 1),
      );

      expect(controller.kategoriList.first.totalDigunakan, equals(100000.0));
    });

    test('hapusAlokasi menghapus kategori dari daftar', () {
      controller.aturAlokasi(KategoriTransaksi.hiburan, 200000);
      controller.hapusAlokasi(KategoriTransaksi.hiburan);

      expect(
        controller.alokasiBudget.containsKey(KategoriTransaksi.hiburan),
        isFalse,
      );
    });

    test('resetAlokasi mengosongkan semua alokasi', () {
      controller.aturAlokasi(KategoriTransaksi.makananMinuman, 800000);
      controller.aturAlokasi(KategoriTransaksi.transportasi, 400000);
      controller.resetAlokasi();

      expect(controller.totalAlokasi, equals(0.0));
    });
  });
}
