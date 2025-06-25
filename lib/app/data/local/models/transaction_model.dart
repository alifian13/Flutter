// Hapus import dan anotasi hive
import 'account_model.dart';
import 'package:flutter/foundation.dart'; // untuk describeEnum

// Enum bisa tetap sama
enum TransactionType {
  pemasukan,
  pengeluaran,
}

class Transaction {
  int? id;
  late String description;
  late double amount;
  late DateTime date;
  late TransactionType type;
  
  // Ubah dari objek Account menjadi accountId (Integer) dan accountName (String)
  late int accountId;
  String? accountName; // Untuk menampung nama akun dari join query

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.accountId,
    this.accountName,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: TransactionType.values.firstWhere((e) => describeEnum(e) == map['type']),
      accountId: map['accountId'],
      accountName: map['accountName'], // Ambil nama dari hasil join
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': describeEnum(type),
      'accountId': accountId,
    };
  }
}