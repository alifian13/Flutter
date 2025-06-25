import 'dart:io';
import 'package:file_saver/file_saver.dart';
import '../data/local/models/transaction_model.dart';
import '/core/utils/constants.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {

  // --- FUNGSI UNTUK EKSPOR ---
  Future<String> exportToCsv() async {
    try {
      final transactionBox = Hive.box<Transaction>(kTransactionsBox);
      final transactions = transactionBox.values.toList();
      if (transactions.isEmpty) return "Tidak ada data untuk diekspor.";

      // Siapkan header dan baris data
      List<List<dynamic>> rows = [];
      rows.add(['description', 'amount', 'date', 'type', 'account_name', 'category']);
      for (var trx in transactions) {
        rows.add([
          trx.description,
          trx.amount,
          trx.date.toIso8601String(),
          describeEnum(trx.type),
          trx.account.name,
          'N/A' // Kolom kategori belum ada di model, kita beri default
        ]);
      }

      String csvString = const ListToCsvConverter().convert(rows);

      final csvBytes = Uint8List.fromList(csvString.codeUnits);

      // Gunakan file_saver untuk memunculkan dialog 'Simpan Sebagai'
      // Ini adalah cara modern & tidak perlu izin penyimpanan
      String? filePath = await FileSaver.instance.saveFile(
        name: kBackupFileName, // Nama file default dari constants.dart
        bytes: csvBytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      if (filePath != null) {
        return "Ekspor berhasil! File disimpan oleh sistem.";
      } else {
        return "Ekspor dibatalkan oleh pengguna.";
      }
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