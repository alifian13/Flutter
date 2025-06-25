import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 2) // ID tipe harus unik
class Account extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late double initialBalance;

  @HiveField(2)
  late String icon; // Untuk menyimpan nama ikon, misal: 'account_balance'
}