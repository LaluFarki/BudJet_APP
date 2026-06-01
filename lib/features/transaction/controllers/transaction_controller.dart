import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';

class TransactionController extends GetxController {
  // Untuk mencegah double submit saat tambah income
  var isAddingIncome = false.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // RxList untuk menampung semua transaksi agar UI bisa update otomatis (Reaktif)
  var transactions = <TransactionModel>[].obs;

  // State untuk budget bulanan dari Firestore
  var budgetBulanan = 0.0.obs;
  // Sisa Saldo (budgetBulanan - totalExpense)
  var userBalance = 0.0.obs;

  // State untuk show/hide saldo
  var isBalanceVisible = true.obs;

  // State untuk categories dari Firestore (sinkron dengan budget)
  var userCategories = <String>[].obs;

  late CollectionReference _txnCollection;
  late DocumentReference _userDoc;

  @override
  void onInit() {
    super.onInit();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _txnCollection = _firestore
        .collection('users')
        .doc(_uid)
        .collection('transactions');
    _userDoc = _firestore.collection('users').doc(_uid);

    // Bind stream dari Firestore ke RxList
    transactions.bindStream(
      _txnCollection
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .toList(),
          ),
    );

    // Listen data budgetBulanan dari Firestore
    _userDoc.snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        budgetBulanan.value = (data['budgetBulanan'] ?? 0).toDouble();

        final catsRaw = data['categories'] as List? ?? [];
        userCategories.value = catsRaw
            .map((c) => (c['nama'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    });

    // Update userBalance setiap kali budget atau transaksi berubah
    everAll([budgetBulanan, transactions], (_) {
      userBalance.value = budgetBulanan.value - totalExpense;
    });
  }

  // Getter helper untuk filter transaksi (misal: hanya pengeluaran)
  double get totalExpense => transactions
      .where(
        (t) =>
            t.type == 'expense' &&
            t.date.year == DateTime.now().year &&
            t.date.month == DateTime.now().month,
      )
      .fold(0.0, (total, item) => total + item.amount);

  double get totalIncome => transactions
      .where(
        (t) =>
            t.type == 'income' &&
            t.date.year == DateTime.now().year &&
            t.date.month == DateTime.now().month,
      )
      .fold(0.0, (total, item) => total + item.amount);

  // Ambil total pengeluaran hari ini
  double get todayExpense => transactions
      .where(
        (t) =>
            t.type == 'expense' &&
            t.date.year == DateTime.now().year &&
            t.date.month == DateTime.now().month &&
            t.date.day == DateTime.now().day,
      )
      .fold(0.0, (total, item) => total + item.amount);

  // Ambil transaksi hari ini saja
  List<TransactionModel> get todayTransactions {
    final now = DateTime.now();
    return transactions
        .where(
          (t) =>
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day,
        )
        .toList();
  }

  // 7 Transaksi terakhir untuk Home Screen
  List<TransactionModel> get recentTransactions {
    return transactions.take(7).toList();
  }

  /// FUNGSI TAMBAH (REVISED): Menyimpan transaksi baru dan memotong saldo/budget kategori
  Future<void> addTransaction(TransactionModel tx) async {
    if (isAddingIncome.value) return;
    isAddingIncome.value = true;
    try {
      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(_userDoc);
        double currentBalance = 0.0;
        double currentBudgetBulanan = 0.0;
        Map<String, dynamic> data = {};

        if (userSnapshot.exists) {
          data = userSnapshot.data() as Map<String, dynamic>? ?? {};
          currentBalance = (data['balance'] ?? 0).toDouble();
          currentBudgetBulanan = (data['budgetBulanan'] ?? 0).toDouble();
        }

        double newBalance = currentBalance;
        double newBudgetBulanan = currentBudgetBulanan;

        if (tx.type == 'expense') {
          newBalance -= tx.amount;
          // PENTING: Pengeluaran dipotong langsung dari sisa alokasi bulanan agar sinkron ke komponen UI
        } else {
          newBalance += tx.amount;
          newBudgetBulanan += tx.amount;
        }

        transaction.update(_userDoc, {
          'balance': newBalance,
          'budgetBulanan': newBudgetBulanan,
        });

        transaction.set(_txnCollection.doc(), tx.toFirestore());
      });
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isAddingIncome.value = false;
    }
  }

  /// FUNGSI HAPUS (REVISED): Menghapus transaksi dan MENGEMBALIKAN (REFUND) kuota budget secara otomatis
  Future<void> deleteTransaction(TransactionModel tx) async {
    try {
      final txDocRef = _txnCollection.doc(tx.id);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(_userDoc);
        double currentBalance = 0.0;
        double currentBudgetBulanan = 0.0;
        Map<String, dynamic> data = {};

        if (userSnapshot.exists) {
          data = userSnapshot.data() as Map<String, dynamic>? ?? {};
          currentBalance = (data['balance'] ?? 0).toDouble();
          currentBudgetBulanan = (data['budgetBulanan'] ?? 0).toDouble();
        }

        double newBalance = currentBalance;
        double newBudgetBulanan = currentBudgetBulanan;

        // PROSES REFUND AKURAT: Kembalikan kondisi uang saat transaksi dihapus
        if (tx.type == 'expense') {
          newBalance += tx.amount; // Uang kembali ke saldo utama
        } else {
          newBalance -= tx.amount;
          newBudgetBulanan -=
              tx.amount; // Jika income dihapus, budget bulanan ikut berkurang
        }

        transaction.update(_userDoc, {
          'balance': newBalance,
          'budgetBulanan': newBudgetBulanan,
        });

        transaction.delete(txDocRef);
      });

      // GetX snackbar sukses pemberitahuan refund
      Get.snackbar(
        'Sukses',
        'Transaksi berhasil dihapus dan dana telah dipulihkan.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFECFFEC),
        colorText: const Color(0xFF1B5E20),
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Tidak bisa menghapus: $e',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// FUNGSI UBAH: Menyimpan perubahan transaksi dan menghitung selisih nominal ke Saldo secara Atomic
  Future<void> updateTransaction(
    TransactionModel oldTx,
    TransactionModel newTx,
  ) async {
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
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan edit: $e',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      );
      rethrow;
    }
  }
}
