import 'package:hive/hive.dart';
part 'transaction_model.g.dart';

// Enum untuk tipe transaksi
@HiveType(typeId: 1) // Gunakan typeId yang berbeda untuk enum
enum TransactionType {
  @HiveField(0)
  pemasukan,

  @HiveField(1)
  pengeluaran,
}

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  late String description;

  @HiveField(1)
  late double amount;

  @HiveField(2)
  late DateTime date;

  // Field baru untuk tipe transaksi
  @HiveField(3)
  late TransactionType type;
}