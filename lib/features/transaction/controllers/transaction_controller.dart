import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State Reaktif (Observable)
  var transactions = <TransactionModel>[].obs;
  var userBalance = 0.0.obs;

  // --- GETTER KOMPUTASI REAKTIF ---
  // Menghitung total seluruh pengeluaran
  double get totalExpense => transactions
      .where((tx) => tx.type == 'expense')
      .fold(0.0, (sum, item) => sum + item.amount);

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

  /// Mengambil data transaksi secara real-time dari Firestore
  void _listenToTransactions() {
    _firestore
        .collection('transactions')
        .orderBy('date', descending: true) // Urutkan dari yang terbaru (descending)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      transactions.value = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
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
  Future<void> addTransaction(TransactionModel transaction) async {
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

      Get.snackbar(
        'Berhasil',
        'Transaksi sukses ditambahkan!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan saat menambahkan transaksi: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Menghapus Transaksi dan mengembalikan Saldo seperti semula
  Future<void> deleteTransaction(TransactionModel transaction) async {
    try {
      await _firestore.runTransaction((Transaction tx) async {
        DocumentReference userRef = _firestore.collection('users').doc('users_farki');
        // Mengambil referensi dokumen transaksi spesifik menggunakan ID dari model
        DocumentReference txnRef = _firestore.collection('transactions').doc(transaction.id);

        DocumentSnapshot userSnapshot = await tx.get(userRef);

        double currentBalance = 0.0;
        if (userSnapshot.exists) {
          final data = userSnapshot.data() as Map<String, dynamic>? ?? {};
          currentBalance = (data['balance'] ?? 0).toDouble();
        }

        // Hitung Saldo Baru (Logika Kembalikan Uang)
        double newBalance = currentBalance;
        if (transaction.type == 'income') {
          // Kebalikan income (dikurangi)
          newBalance -= transaction.amount;
        } else if (transaction.type == 'expense') {
          // Kebalikan expense (ditambah)
          newBalance += transaction.amount;
        }

        // Update ke saldo yang direstore
        tx.set(userRef, {'balance': newBalance}, SetOptions(merge: true));

        // Hapus dokumen transaksi
        tx.delete(txnRef);
      });

      Get.snackbar(
        'Berhasil',
        'Transaksi berhasil dihapus!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan saat menghapus transaksi: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
