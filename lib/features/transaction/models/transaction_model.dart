import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  /// Membuat object [TransactionModel] dari Firestore [DocumentSnapshot]
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    // Cast data ke bentuk Map
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? 'expense',
      category: data['category'] ?? '',
      // Konversi Timestamp dari Firestore kembali menjadi DateTime
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Mengubah object [TransactionModel] menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      // Konversi DateTime menjadi Timestamp agar sesuai dengan format Firestore
      'date': Timestamp.fromDate(date),
    };
  }
}
