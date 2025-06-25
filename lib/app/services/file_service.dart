import 'dart:io';
import '../data/local/models/transaction_model.dart';
import '/core/utils/constants.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {

  // --- FUNGSI UNTUK EKSPOR ---
  Future<String?> exportToCsv() async {
    // 1. Minta Izin Penyimpanan
    // Perizinan di Android versi baru lebih ketat.
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    
    if (!status.isGranted) {
        // Jika pengguna menolak, kita tidak bisa melanjutkan.
        return "Izin penyimpanan ditolak. Tidak dapat mengekspor file.";
    }

    try {
      final transactionBox = Hive.box<Transaction>(kTransactionsBox);
      final transactions = transactionBox.values.toList();
      if (transactions.isEmpty) return "Tidak ada data untuk diekspor.";

      List<List<dynamic>> rows = [];
      // Header CSV
      rows.add(['description', 'amount', 'date', 'type', 'account_name']);
      // Data Transaksi
      for (var trx in transactions) {
        rows.add([
          trx.description,
          trx.amount,
          trx.date.toIso8601String(),
          describeEnum(trx.type),
          trx.account.name,
        ]);
      }

      String csvString = const ListToCsvConverter().convert(rows);

      // 2. Dapatkan Path ke Folder Downloads
      // Menggunakan path_provider untuk direktori Downloads
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return "Tidak dapat menemukan folder Downloads.";
      }
      // Biasanya folder Download ada di bawah direktori eksternal
      final downloadsDir = Directory("${externalDir.path}/Download");
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final path = "${downloadsDir.path}/$kBackupFileName";
      final file = File(path);

      // 3. Tulis File
      await file.writeAsString(csvString);
      debugPrint("Data berhasil diekspor ke: $path");
      
      return "Ekspor berhasil! File disimpan di folder Downloads.";
    } catch (e) {
      debugPrint("Error saat ekspor data: $e");
      return "Terjadi error saat mengekspor: $e";
    }
  }

  // --- FUNGSI UNTUK IMPOR ---
  Future<List<Transaction>?> importFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();

      // Ubah string CSV menjadi List<List<dynamic>>
      List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(csvString);

      // Hapus baris header
      if (rows.isNotEmpty) {
        rows.removeAt(0);
      }

      List<Transaction> importedTransactions = [];
      for (var row in rows) {
        final transaction = Transaction()
          ..description = row[0]
          ..amount = double.parse(row[1].toString())
          ..date = DateTime.parse(row[2])
          ..type = TransactionType.values.firstWhere(
            (e) => describeEnum(e) == row[3],
            orElse: () => TransactionType.pengeluaran, // Default jika ada error
          );
        importedTransactions.add(transaction);
      }

      debugPrint("${importedTransactions.length} transaksi berhasil diimpor.");
      return importedTransactions;
    } catch (e) {
      debugPrint("Error saat impor data: $e");
      return null;
    }
  }
}