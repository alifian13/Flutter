import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/file_service.dart';
import '../screens/manage_accounts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Tambahkan "with WidgetsBindingObserver" untuk memantau siklus hidup aplikasi
class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    // Daftarkan observer untuk mendengarkan perubahan state aplikasi
    WidgetsBinding.instance.addObserver(this);
    // Cek status izin saat halaman pertama kali dibuka
    _checkPermissionStatus();
  }

  @override
  void dispose() {
    // Hapus observer untuk mencegah memory leak
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Metode ini akan dipanggil setiap kali state aplikasi berubah
  /// (misalnya: dari background ke foreground).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Jika pengguna kembali ke aplikasi (misal setelah dari pengaturan HP),
    // kita cek ulang status izinnya.
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  /// Cek status izin, perbarui UI, dan mulai layanan jika diizinkan.
  void _checkPermissionStatus() async {
    bool isEnabled = await AppNotificationService.isPermissionGranted();
    if (mounted) {
      setState(() {
        _isServiceEnabled = isEnabled;
      });

      // SOLUSI MASALAH 2: Jika izin sudah aktif, kita mulai layanan notifikasi.
      // Ini memastikan layanan berjalan setelah izin diberikan tanpa perlu restart.
      if (isEnabled) {
        // PERBAIKAN: Menggunakan nama metode yang benar 'startListening'.
        AppNotificationService.startListening();
      }
    }
  }

  /// Menangani logika untuk ekspor database.
  Future<void> _handleExport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final fileService = FileService();
    final message = await fileService.exportDatabase();

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Menangani logika untuk impor database.
  Future<void> _handleImport() async {
    final fileService = FileService();
    final message = await fileService.importDatabase();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Otomatisasi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Pencatatan Otomatis'),
            subtitle: Text(
              _isServiceEnabled
                  ? 'Aktif. Aplikasi akan membaca notifikasi transaksi.'
                  : 'Nonaktif. Klik untuk memberikan izin akses notifikasi.',
            ),
            value: _isServiceEnabled,
            onChanged: (bool value) async {
              // SOLUSI MASALAH 1: Hilangkan `Future.delayed`.
              // Cukup minta izin. Pengecekan status akan ditangani oleh
              // `didChangeAppLifecycleState` saat pengguna kembali ke aplikasi.
              if (value) {
                await AppNotificationService.requestPermission();
              }
            },
          ),
          const Divider(),

          const ListTile(
            title: Text(
              'Manajemen Data & Akun',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Kelola Akun'),
            subtitle: const Text('Tambah atau hapus akun bank & e-wallet'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageAccountsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Ekspor Data'),
            subtitle: const Text('Simpan salinan data di penyimpanan ponsel'),
            onTap: _handleExport,
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Impor Data'),
            subtitle: const Text('Pulihkan data dari file cadangan'),
            onTap: _handleImport,
          ),
          const Divider(),
        ],
      ),
    );
  }
}
