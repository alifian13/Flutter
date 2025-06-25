import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../services/background_parser.dart';

class AppNotificationService {
  /// Memulai service di background jika izin sudah diberikan.
  static Future<void> startListening() async {
    // Pastikan lagi izin sudah diberikan.
    if (!await isPermissionGranted()) {
      debugPrint("SERVICE: Izin belum diberikan. Service tidak dimulai.");
      return;
    }
    
    debugPrint("SERVICE: Izin sudah ada. Memulai listener...");
    
    // Stream ini akan menerima data notifikasi secara real-time
    // saat aplikasi sedang dibuka (foreground) atau berjalan di background.
    NotificationListenerService.notificationsStream.listen((event) {
      debugPrint("--- Notifikasi Baru Diterima oleh Service ---");
      debugPrint("Dari App: ${event.packageName}");
      
      // Filter notifikasi yang tidak relevan.
      if (event.packageName != null &&
          event.content != null &&
          event.title != null &&
          !event.title!.toLowerCase().contains('pesan baru')) { // Contoh filter
          
        debugPrint("Mengirim notifikasi ke background parser...");
        // Kirim data ke background isolate untuk di-parsing.
        compute(parseNotificationInBackground, {
          'packageName': event.packageName!,
          'text': "${event.title!} ${event.content!}", // Gabungkan judul & isi untuk konteks lebih
        });
      } else {
        debugPrint("Notifikasi diabaikan (tidak relevan).");
      }
    });
  }

  /// Cek apakah izin sudah diberikan oleh pengguna.
  static Future<bool> isPermissionGranted() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  /// Meminta izin kepada pengguna. Ini akan membuka halaman pengaturan sistem.
  static Future<void> requestPermission() async {
    debugPrint("SERVICE: Meminta izin akses notifikasi...");
    await NotificationListenerService.requestPermission();
  }
}
