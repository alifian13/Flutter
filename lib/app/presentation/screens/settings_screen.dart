import '../../services/notification_service.dart';
import '/app/data/local/models/transaction_model.dart';
import '../../services/file_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '/core/utils/constants.dart';

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

    final transactionBox = Hive.box<Transaction>(kTransactionsBox);
    final transactions = transactionBox.values.toList();
    final fileService = FileService();
    final filePath = await fileService.exportToCsv(transactions);

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(filePath != null ? 'Data diekspor ke $filePath' : 'Gagal mengekspor data.'),
      ),
    );
  }

  Future<void> _handleImport() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final filePath = result.files.single.path!;
      final fileService = FileService();
      final importedTransactions = await fileService.importFromCsv(filePath);

      if (mounted) Navigator.pop(context);

      if (importedTransactions != null) {
        final transactionBox = Hive.box<Transaction>(kTransactionsBox);
        await transactionBox.clear();
        await transactionBox.addAll(importedTransactions);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${importedTransactions.length} data berhasil diimpor!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengimpor data. Pastikan format file benar.')),
        );
      }
    }
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Ekspor Data ke CSV'),
            subtitle: const Text('Simpan salinan data di penyimpanan ponsel'),
            onTap: _handleExport,
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline),
            title: const Text('Impor Data dari CSV'),
            subtitle: const Text('Pulihkan data dari file backup'),
            onTap: _handleImport,
          ),
          const Divider(),
        ],
      ),
    );
  }
}