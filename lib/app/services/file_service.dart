import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FileService {
  // --- FUNGSI UNTUK EKSPOR DATABASE ---
  Future<String> exportDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = join(dbPath, 'ceban.db');
      final file = File(sourcePath);

      if (!await file.exists()) {
        return "Database tidak ditemukan.";
      }

      final bytes = await file.readAsBytes();

      String? savedPath = await FileSaver.instance.saveFile(
        name: 'ceban_backup_${DateTime.now().toIso8601String()}.db',
        bytes: bytes,
        ext: 'db',
        mimeType: MimeType.other, // atau MimeType.sqlite
      );

      if (savedPath != null) {
        return "Ekspor berhasil!";
      } else {
        return "Ekspor dibatalkan.";
      }
    } catch (e) {
      debugPrint("Error saat ekspor database: $e");
      return "Terjadi error: $e";
    }
  }

  // --- FUNGSI UNTUK IMPOR DATABASE ---
  Future<String> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null && result.files.single.path != null) {
        final importFile = File(result.files.single.path!);
        
        // Dapatkan path database saat ini
        final dbPath = await getDatabasesPath();
        final destinationPath = join(dbPath, 'ceban.db');

        // Tutup koneksi database yang ada jika terbuka
        // (Anda mungkin perlu menambahkan logika untuk menutup DB di DatabaseHelper)
        
        // Salin file yang diimpor untuk menimpa database lama
        await importFile.copy(destinationPath);

        return "Impor berhasil! Silakan restart aplikasi.";
      } else {
        return "Impor dibatalkan.";
      }
    } catch (e) {
      debugPrint("Error saat impor database: $e");
      return "Terjadi error: $e";
    }
  }
}