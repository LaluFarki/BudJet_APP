import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State Reaktif (Observable)
  var transactions = <TransactionModel>[].obs;
  var userBalance = 0.0.obs;
  var isBalanceVisible = true.obs;

  // --- GETTER KOMPUTASI REAKTIF ---
  // Menghitung pengeluaran bulan ini (akan otomatis reset tiap berganti bulan)
  double get totalExpense {
    final now = DateTime.now();
    return transactions
        .where((tx) => 
            tx.type == 'expense' && 
            tx.date.year == now.year && 
            tx.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Menghitung total pengeluaran khusus hari ini
  double get todayExpense {
    final now = DateTime.now();
    return transactions
        .where((tx) =>
            tx.type == 'expense' &&
            tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // --- MENGAMBIL LIST TRANSAKSI HARI INI SAJA ---
  List<TransactionModel> get todayTransactions {
    final now = DateTime.now();
    return transactions.where((tx) =>
        tx.date.year == now.year &&
        tx.date.month == now.month &&
        tx.date.day == now.day).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _listenToTransactions();
    _listenToBalance();
  }

  /// Update Saldo Utama Secara Manual (Topup/Koreksi)
  Future<void> updateBalance(double newBalance) async {
    try {
      await _firestore.collection('users').doc('users_farki').set(
        {'balance': newBalance},
        SetOptions(merge: true),
      );
      Get.back(); // Tutup Pop-up (Default Dialog)
      Get.snackbar(
        'Berhasil', 
        'Saldo utama berhasil diperbarui!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal', 
        'Terjadi kesalahan saat update saldo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// FUNGSI DUMMY: Membuat 15 data sembarang yang masuk ke firebase
  Future<void> injectDummyData() async {
    for (int i = 0; i < 15; i++) {
      final isIncome = i % 3 == 0;
      final dummyTx = TransactionModel(
        id: '',
        amount: isIncome ? 150000.0 : 25000.0 + (i * 1000),
        createdAt: DateTime.now(),
        date: i < 10 ? DateTime.now() : DateTime.now().subtract(Duration(days: i)), 
        // 10 pertama di set hari ini, sisanya mundur ke belakang
        kategori: isIncome ? 'Gaji/Bonus' : 'Makan & Minuman',
        note: 'Dummy data $i',
        title: isIncome ? 'Bonus $i' : 'Pengeluaran $i',
        type: isIncome ? 'income' : 'expense',
      );
      await addTransaction(dummyTx, showSnackbar: false);
    }
    Get.snackbar('Sukses', '15 Data Dummy berhasil disuntikkan ke Firebase!', snackPosition: SnackPosition.BOTTOM);
  }

  /// FUNGSI HAPUS: Menghapus transaksi dan otomatis merekap saldo (Refund/Deduct) secara Atomic
  Future<void> deleteTransaction(TransactionModel tx) async {
    try {
      final userDocRef = _firestore.collection('users').doc('users_farki');
      final txDocRef = _firestore.collection('transactions').doc(tx.id);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDocRef);
        double currentBalance = 0.0;
        if (userSnapshot.exists && userSnapshot.data()!.containsKey('balance')) {
          currentBalance = (userSnapshot.data()!['balance'] as num).toDouble();
        }

        // Hitung saldo baru (karena dihapus, efeknya DIBALIK)
        double newBalance = currentBalance;
        if (tx.type == 'expense') {
          newBalance += tx.amount; // Uang kembali
        } else {
          newBalance -= tx.amount; // Uang ditarik balik
        }

        transaction.update(userDocRef, {'balance': newBalance});
        transaction.delete(txDocRef);
      });

      Get.snackbar('Terhapus', 'Transaksi berhasil dihapus!', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Gagal', 'Kesalahan menghapus: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// FUNGSI UBAH: Menyimpan perubahan transaksi dan menghitung selisih nominal ke Saldo secara Atomic
  Future<void> updateTransaction(TransactionModel oldTx, TransactionModel newTx) async {
    try {
      final userDocRef = _firestore.collection('users').doc('users_farki');
      final txDocRef = _firestore.collection('transactions').doc(oldTx.id);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDocRef);
        double currentBalance = 0.0;
        if (userSnapshot.exists && userSnapshot.data()!.containsKey('balance')) {
          currentBalance = (userSnapshot.data()!['balance'] as num).toDouble();
        }

        double newBalance = currentBalance;

        // Langkah 1: Batalkan efek transaksi lama (Refund)
        if (oldTx.type == 'expense') {
          newBalance += oldTx.amount;
        } else {
          newBalance -= oldTx.amount;
        }

        // Langkah 2: Terapkan efek transaksi baru
        if (newTx.type == 'expense') {
          newBalance -= newTx.amount;
        } else {
          newBalance += newTx.amount;
        }

        transaction.update(userDocRef, {'balance': newBalance});
        transaction.update(txDocRef, newTx.toFirestore());
      });

      Get.snackbar('Tersimpan', 'Perubahan transaksi berhasil disimpan!', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan edit: $e', snackPosition: SnackPosition.BOTTOM);
      rethrow; 
    }
  }

  /// Mengambil data transaksi secara real-time dari Firestore
  void _listenToTransactions() {
    _firestore
        .collection('transactions')
        .orderBy('date', descending: true) // Urutkan utama dari tanggal
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      
      // Sort tambahan: Jika tanggal sama, urutkan berdasarkan waktu diinput (terbaru di atas)
      list.sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      transactions.value = list;
    });
  }

  /// Mengambil data saldo user_farki secara real-time
  void _listenToBalance() {
    _firestore
        .collection('users')
        .doc('users_farki')
        .snapshots()
        .listen((DocumentSnapshot doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        // Memastikan validasi .toDouble() untuk field balance
        userBalance.value = (data['balance'] ?? 0).toDouble();
      } else {
        userBalance.value = 0.0;
      }
    });
  }

  /// Menambahkan Transaksi baru sekaligus Update Saldo Otomatis
  Future<void> addTransaction(TransactionModel transaction, {bool showSnackbar = true}) async {
    try {
      // Menggunakan runTransaction agar proses Read & Write dilakukan secara bersamaan dengan aman
      await _firestore.runTransaction((Transaction tx) async {
        DocumentReference userRef = _firestore.collection('users').doc('users_farki');
        // Membuat referensi dokumen baru di transaksi
        DocumentReference txnRef = _firestore.collection('transactions').doc();

        DocumentSnapshot userSnapshot = await tx.get(userRef);

        double currentBalance = 0.0;
        if (userSnapshot.exists) {
          final data = userSnapshot.data() as Map<String, dynamic>? ?? {};
          // Validasi tipe data saat membaca dari Firestore
          currentBalance = (data['balance'] ?? 0).toDouble();
        }

        // Hitung Saldo Baru
        double newBalance = currentBalance;
        if (transaction.type == 'income') {
          newBalance += transaction.amount;
        } else if (transaction.type == 'expense') {
          newBalance -= transaction.amount;
        }

        // Simpan update saldo secara aman
        tx.set(userRef, {'balance': newBalance}, SetOptions(merge: true));

        // Simpan dokumen model transaksi ke Firestore
        final txMap = transaction.toFirestore();
        tx.set(txnRef, txMap);
      });

      if (showSnackbar) {
        Get.snackbar(
          'Berhasil',
          'Transaksi sukses ditambahkan!',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan saat menambahkan transaksi: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // (Old deleteTransaction dihapus karena sudah digantikan oleh fungsi atomic di atas)
}
