// Hapus semua import dan anotasi Hive
// part 'account_model.g.dart';

// @HiveType(typeId: 2)
class Account {
  // Tambahkan 'id' yang akan menjadi primary key di SQLite
  int? id;
  
  // @HiveField(0)
  late String name;

  // @HiveField(1)
  late double initialBalance;

  // @HiveField(2)
  late String icon;

  Account({this.id, required this.name, required this.initialBalance, this.icon = 'wallet'});

  // Konversi dari Map (data dari DB) ke Objek
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      initialBalance: map['initialBalance'],
      icon: map['icon'],
    );
  }

  // Konversi dari Objek ke Map (untuk dimasukkan ke DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initialBalance': initialBalance,
      'icon': icon,
    };
  }
}   