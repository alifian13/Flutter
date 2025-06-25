import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

// Penting: Fungsi ini harus berada di level atas (top-level) atau static
// agar bisa dipanggil dari background.
@pragma('vm:entry-point')
void onNotificationPosted() {
  // Fungsi ini dipanggil setiap kali ada notifikasi baru masuk
  // Kita akan menambahkan logika parsing di sini nanti.
  // Untuk sekarang, biarkan kosong atau tambahkan print sederhana jika perlu.
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
      
      // Di sinilah nanti kita akan memanggil logika parsing
      // untuk mendeteksi transaksi dari GoPay, OVO, m-Banking, dll.
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