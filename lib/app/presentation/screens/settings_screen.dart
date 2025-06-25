import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../services/file_service.dart';
import '../screens/manage_accounts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Menggunakan nama variabel Anda agar konsisten
  bool _isServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  /// Cek status izin saat ini dan perbarui UI.
  void _checkPermissionStatus() async {
    bool isEnabled = await AppNotificationService.isPermissionGranted();
    if (mounted) {
      setState(() {
        _isServiceEnabled = isEnabled;
      });
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Menangani logika untuk impor database.
  Future<void> _handleImport() async {
    final fileService = FileService();
    final message = await fileService.importDatabase();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // Memberi judul pada setiap seksi agar lebih rapi
          const ListTile(
            title: Text('Otomatisasi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Pencatatan Otomatis'),
            // Menggunakan subtitle yang lebih deskriptif untuk memberi tahu statusnya
            subtitle: Text(
              _isServiceEnabled
                ? 'Aktif. Aplikasi akan membaca notifikasi transaksi.'
                : 'Nonaktif. Klik untuk memberikan izin akses notifikasi.',
            ),
            value: _isServiceEnabled,
            onChanged: (bool value) async {
              if (value) {
                await AppNotificationService.requestPermission();
              }
              // Beri jeda sejenak agar dialog sistem sempat tertutup
              // sebelum kita cek ulang status izinnya.
              Future.delayed(const Duration(seconds: 1), _checkPermissionStatus);
            },
          ),
          const Divider(),

          const ListTile(
            title: Text('Manajemen Data & Akun', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Kelola Akun'),
            subtitle: const Text('Tambah atau hapus akun bank & e-wallet'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageAccountsScreen()),
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
