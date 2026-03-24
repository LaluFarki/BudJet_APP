import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final DateTime createdAt;
  final DateTime date;
  final String kategori;
  final String note;
  final String title;
  final String type; // 'income' or 'expense'

  TransactionModel({
    required this.id,
    required this.amount,
    required this.createdAt,
    required this.date,
    required this.kategori,
    required this.note,
    required this.title,
    required this.type,
  });

  /// Membuat object [TransactionModel] dari Firestore [DocumentSnapshot]
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    // Cast data ke bentuk Map secara aman
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TransactionModel(
      id: doc.id,   // Selalu best-practice menyimpan ID dokumen Firestore
      amount: (data['amount'] ?? 0).toDouble(),
      title: data['title'] ?? '',
      kategori: data['kategori'] ?? '',
      note: data['note'] ?? '',
      type: data['type'] ?? 'expense',
      // Konversi Timestamp dari Firestore kembali menjadi DateTime
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Mengubah object [TransactionModel] menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'title': title,
      'kategori': kategori,
      'note': note,
      'type': type,
      // Konversi DateTime menjadi Timestamp agar dikenali oleh Firestore
      'created_at': Timestamp.fromDate(createdAt),
      'date': Timestamp.fromDate(date),
    };
  }
}
