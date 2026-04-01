import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // RxList untuk menampung semua transaksi agar UI bisa update otomatis (Reaktif)
  var transactions = <TransactionModel>[].obs;
  
  // State untuk budget bulanan dari Firestore
  var budgetBulanan = 0.0.obs;
  // Sisa Saldo (budgetBulanan - totalExpense)
  var userBalance = 0.0.obs;
  
  // State untuk show/hide saldo
  var isBalanceVisible = true.obs;

  late CollectionReference _txnCollection;
  late DocumentReference _userDoc;

  @override
  void onInit() {
    super.onInit();
    _txnCollection = _firestore.collection('users').doc(_uid).collection('transactions');
    _userDoc = _firestore.collection('users').doc(_uid);
    
    // Bind stream dari Firestore ke RxList
    transactions.bindStream(
      _txnCollection
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList()),
    );

    // Listen data budgetBulanan dari Firestore
    _userDoc.snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        budgetBulanan.value = (data['budgetBulanan'] ?? 0).toDouble();
      }
    });

    // Update userBalance setiap kali budget atau transaksi berubah
    everAll([budgetBulanan, transactions], (_) {
      userBalance.value = budgetBulanan.value - totalExpense;
    });
  }

  // Getter helper untuk filter transaksi (misal: hanya pengeluaran)
  double get totalExpense => transactions
      .where((t) => t.type == 'expense' && t.date.year == DateTime.now().year && t.date.month == DateTime.now().month)
      .fold(0.0, (total, item) => total + item.amount);

  double get totalIncome => transactions
      .where((t) => t.type == 'income' && t.date.year == DateTime.now().year && t.date.month == DateTime.now().month)
      .fold(0.0, (total, item) => total + item.amount);

  // Ambil total pengeluaran hari ini
  double get todayExpense => transactions
      .where((t) => 
        t.type == 'expense' && 
        t.date.year == DateTime.now().year && 
        t.date.month == DateTime.now().month && 
        t.date.day == DateTime.now().day
      )
      .fold(0.0, (total, item) => total + item.amount);

  // Ambil transaksi hari ini saja
  List<TransactionModel> get todayTransactions {
    final now = DateTime.now();
    return transactions.where((t) => 
      t.date.year == now.year && 
      t.date.month == now.month && 
      t.date.day == now.day
    ).toList();
  }

  // 7 Transaksi terakhir untuk Home Screen
  List<TransactionModel> get recentTransactions {
    return transactions.take(7).toList();
  }

  /// FUNGSI TAMBAH: Menyimpan transaksi baru dan update Saldo secara Atomic (Transaksi Firestore)
  Future<void> addTransaction(TransactionModel tx) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Baca saldo user saat ini
        final userSnapshot = await transaction.get(_userDoc);
        double currentBalance = 0.0;
        Map<String, dynamic> data = {};
        if (userSnapshot.exists) {
          data = userSnapshot.data() as Map<String, dynamic>? ?? {};
          currentBalance = (data['balance'] ?? 0).toDouble();
        }

        // 2. Hitung saldo baru
        double newBalance = currentBalance;
        if (tx.type == 'expense') {
          newBalance -= tx.amount;
        } else {
          newBalance += tx.amount;
        }

        // 3. Update saldo & Tambah transaksi
        transaction.update(_userDoc, {
          'balance': newBalance,
          if (tx.type == 'income') 'budgetBulanan': (data['budgetBulanan'] ?? 0).toDouble() + tx.amount,
        });
        transaction.set(_txnCollection.doc(), tx.toFirestore());
      });
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// FUNGSI HAPUS: Menghapus transaksi dan mengembalikan saldo secara Atomic
  Future<void> deleteTransaction(TransactionModel tx) async {
    try {
      final txDocRef = _txnCollection.doc(tx.id);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(_userDoc);
        double currentBalance = 0.0;
        Map<String, dynamic> data = {};
        if (userSnapshot.exists) {
          data = userSnapshot.data() as Map<String, dynamic>? ?? {};
          currentBalance = (data['balance'] ?? 0).toDouble();
        }

        double newBalance = currentBalance;
        // Jika yang dihapus pengeluaran -> saldo bertambah (refund)
        if (tx.type == 'expense') {
          newBalance += tx.amount;
        } else {
          newBalance -= tx.amount;
        }

        transaction.update(_userDoc, {
          'balance': newBalance,
          if (tx.type == 'income') 'budgetBulanan': (data['budgetBulanan'] ?? 0).toDouble() - tx.amount,
        });
        transaction.delete(txDocRef);
      });
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak bisa menghapus: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// FUNGSI UBAH: Menyimpan perubahan transaksi dan menghitung selisih nominal ke Saldo secara Atomic
  Future<void> updateTransaction(TransactionModel oldTx, TransactionModel newTx) async {
    try {
      final txDocRef = _txnCollection.doc(oldTx.id);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(_userDoc);
        double currentBalance = 0.0;
        if (userSnapshot.exists) {
          final data = userSnapshot.data() as Map<String, dynamic>? ?? {};
          currentBalance = (data['balance'] ?? 0).toDouble();
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

        transaction.update(_userDoc, {'balance': newBalance});
        transaction.update(txDocRef, newTx.toFirestore());
      });
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan edit: $e', snackPosition: SnackPosition.BOTTOM);
      rethrow; 
    }
  }
}
