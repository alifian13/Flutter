// lib/app/services/file_service.dart

import 'dart:io';
import '../data/local/models/transaction_model.dart';
import '/core/utils/constants.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileService {

  // --- FUNGSI UNTUK EKSPOR ---
  Future<String?> exportToCsv(List<Transaction> transactions) async {
    try {
      // Buat daftar dari daftar data (List of Lists) untuk CSV
      List<List<dynamic>> rows = [];

      // Tambahkan baris header
      rows.add(['description', 'amount', 'date', 'type']);

      // Tambahkan data transaksi
      for (var trx in transactions) {
        rows.add([
          trx.description,
          trx.amount,
          trx.date.toIso8601String(), // Simpan dalam format ISO agar mudah dibaca kembali
          describeEnum(trx.type), // Ubah enum menjadi string (misal: 'pengeluaran')
        ]);
      }

      // Ubah data menjadi string CSV
      String csvString = const ListToCsvConverter().convert(rows);

      // Dapatkan direktori Downloads di perangkat
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        debugPrint("Tidak bisa menemukan direktori eksternal.");
        return null;
      }

      final path = "${directory.path}/$kBackupFileName";
      final file = File(path);

      // Tulis string CSV ke dalam file
      await file.writeAsString(csvString);
      debugPrint("Data berhasil diekspor ke: $path");

      return path; // Kembalikan path file yang berhasil dibuat
    } catch (e) {
      debugPrint("Error saat ekspor data: $e");
      return null;
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