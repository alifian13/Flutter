import 'package:flutter/foundation.dart';
import 'notification_parser.dart';

// Penting: Fungsi ini harus top-level agar bisa dijalankan di isolate terpisah.
@pragma('vm:entry-point')
Future<void> parseNotificationInBackground(
  Map<String, String> notificationData,
) async {
  // Karena ini berjalan di isolate terpisah, kita tidak perlu inisialisasi
  // database di sini. Cukup panggil logika parser inti yang sudah
  // diatur untuk menggunakan instance DatabaseHelper.
  
  final packageName = notificationData['packageName'] ?? '';
  final text = notificationData['text'] ?? '';

  // Panggil logika parser inti. NotificationParser akan bertanggung jawab
  // untuk mendapatkan instance DatabaseHelper dan menyimpan data.
  // Ini membuat kode lebih bersih dan terpusat.
  debugPrint("Background Isolate: Parsing notification for $packageName");
  await NotificationParser.parseAndSave(packageName, text);
  debugPrint("Background Isolate: Parsing finished.");
}
