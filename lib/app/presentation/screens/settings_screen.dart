import '../../services/notification_service.dart';
import '/app/data/local/models/transaction_model.dart';
import '../../services/file_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '/core/utils/constants.dart';
import '../screens/manage_accounts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  void _checkPermissionStatus() async {
    bool isEnabled = await AppNotificationService.isPermissionGranted();
    setState(() {
      _isServiceEnabled = isEnabled;
    });
  }

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

  Future<void> _handleImport() async {
    final fileService = FileService();
    final message = await fileService.importDatabase();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Aktifkan Pencatatan Otomatis'),
            subtitle: const Text('Membaca notifikasi dari aplikasi keuangan'),
            value: _isServiceEnabled,
            onChanged: (bool value) async {
              if (value) await AppNotificationService.requestPermission();
              _checkPermissionStatus();
            },
          ),
          ListTile( // <-- TAMBAHKAN BLOK INI
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Ekspor Data'),
            subtitle: const Text('Simpan salinan data di penyimpanan ponsel'),
            onTap: _handleExport,
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline),
            title: const Text('Impor Data'),
            subtitle: const Text('Pulihkan data dari file backup'),
            onTap: _handleImport,
          ),
          const Divider(),
        ],
      ),
    );
  }
}