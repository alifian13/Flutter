import '../data/local/models/account_model.dart';
import '../data/local/models/transaction_model.dart';
import '/core/utils/constants.dart';
import '../services/notification_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

// Penting: Fungsi ini harus top-level agar bisa dijalankan di isolate terpisah
@pragma('vm:entry-point')
Future<void> parseNotificationInBackground(
  Map<String, String> notificationData,
) async {
  // Setiap isolate perlu menginisialisasi Hive-nya sendiri
  final directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);

  // Daftarkan adapter yang diperlukan
  if (!Hive.isAdapterRegistered(AccountAdapter().typeId)) {
    Hive.registerAdapter(AccountAdapter());
  }
  if (!Hive.isAdapterRegistered(TransactionTypeAdapter().typeId)) {
    Hive.registerAdapter(TransactionTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(TransactionAdapter().typeId)) {
    Hive.registerAdapter(TransactionAdapter());
  }

  // Buka box yang diperlukan
  await Hive.openBox<Account>('accounts');
  await Hive.openBox<Transaction>(kTransactionsBox);

  final packageName = notificationData['packageName'] ?? '';
  final text = notificationData['text'] ?? '';

  // Panggil logika parser inti
  await NotificationParser.parseAndSave(packageName, text);

  // Tutup box setelah selesai
  await Hive.close();
}
