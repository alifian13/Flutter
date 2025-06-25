import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../services/notification_parser.dart';

@pragma('vm:entry-point')
void onNotificationPosted() {
  debugPrint("Callback onNotificationPosted dipanggil dari background");
}


class AppNotificationService {
  // Memulai service di background
  static Future<void> startListening() async {
    // Pastikan izin sudah diberikan sebelum mendengarkan notifikasi
    if (!await NotificationListenerService.isPermissionGranted()) {
      await NotificationListenerService.requestPermission();
    }
    
    // Stream ini akan menerima data notifikasi secara real-time
    // saat aplikasi sedang dibuka (foreground).
    NotificationListenerService.notificationsStream.listen((event) {
      debugPrint("--- Notifikasi Baru Diterima (Foreground) ---");
      debugPrint("App: ${event.packageName}");
      debugPrint("Judul: ${event.title}");
      debugPrint("Isi: ${event.content}");
      debugPrint("---------------------------------------------");
      
      if (event.packageName != null && event.content != null) {
        NotificationParser.parseAndSave(event.packageName!, event.content!);
      }
    });
  }

  // Cek apakah izin sudah diberikan
  static Future<bool> isPermissionGranted() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  // Meminta izin kepada pengguna
  static Future<void> requestPermission() async {
    await NotificationListenerService.requestPermission();
  }
}