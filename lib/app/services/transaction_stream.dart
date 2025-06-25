import 'dart:async';

/// Global stream controller untuk memberitahu UI bahwa ada transaksi baru.
/// Ini bertindak sebagai jembatan antara background service dan UI.
class TransactionStream {
  // Membuat StreamController yang bisa diakses dari mana saja di aplikasi.
  // 'broadcast' memungkinkan stream ini memiliki lebih dari satu pendengar.
  static final StreamController<void> _controller = StreamController.broadcast();

  /// Stream yang akan didengarkan oleh UI (misalnya HomeScreen).
  static Stream<void> get stream => _controller.stream;

  /// Fungsi yang dipanggil oleh background parser setelah berhasil menyimpan transaksi.
  /// Ini akan mengirim sinyal ke semua pendengar.
  static void newTransactionAdded() {
    _controller.add(null);
  }

  // Penting untuk menutup controller saat aplikasi tidak lagi digunakan,
  // namun untuk stream global seperti ini, biasanya dibiarkan terbuka.
  // void dispose() {
  //   _controller.close();
  // }
}
