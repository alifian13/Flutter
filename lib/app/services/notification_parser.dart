import 'package:flutter/foundation.dart';
import '../data/local/database_helper.dart';
import '../data/local/models/account_model.dart';
import '../data/local/models/transaction_model.dart';
import 'transaction_stream.dart'; // <-- 1. IMPORT STREAM SERVICE

class NotificationParser {
  static final dbHelper = DatabaseHelper();

  // === HYBRID PARSING SYSTEM ===
  /// Titik masuk utama untuk mem-parsing notifikasi.
  static Future<void> parseAndSave(String packageName, String text) async {
    final lowerCasePackage = packageName.toLowerCase();
    
    // 1. Coba parsing menggunakan aturan Regex yang spesifik terlebih dahulu
    final bool parsedWithRegex = await _tryParseWithSpecificRules(lowerCasePackage, text);

    // 2. Jika gagal dengan Regex, gunakan metode kata kunci sebagai cadangan
    if (!parsedWithRegex) {
      debugPrint("Regex parsing failed. Falling back to keyword-based method.");
      await _tryParseWithKeywords(lowerCasePackage, text);
    }
  }

  /// [PRIORITAS 1] Mencoba mem-parsing menggunakan aturan Regex yang spesifik.
  static Future<bool> _tryParseWithSpecificRules(String lowerCasePackage, String text) async {
    final Map<String, List<Map<String, dynamic>>> allRules = {
      'seabank': _seaBankRules,
      'bca': _bcaRules,
      'bri.brimo': _briRules,
      'bni.mobile': _bniRules,
      'bankmandiri.livin': _mandiriRules,
      'jago': _jagoRules,
      'ocbc.mobile': _ocbcRules,
      'gopay': _gopayRules,
      'gojek': _gopayRules,
      'dana': _danaRules,
      'shopee': _shopeePayRules,
      'ovo': _ovoRules,
      'linkaja': _linkAjaRules,
    };

    for (var entry in allRules.entries) {
      if (lowerCasePackage.contains(entry.key)) {
        for (var rule in entry.value) {
          final match = (rule['regex'] as RegExp).firstMatch(text);
          if (match != null) {
            final amountString = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
            final amount = double.tryParse(amountString);

            if (amount != null) {
              String description = rule['description'] ?? 'Transaksi ${entry.key}';
              if (match.groupCount > 1 && match.group(2) != null) {
                description = '${rule['desc_prefix'] ?? ''}${match.group(2)}'.trim();
              }
              await _saveTransaction(rule['type'], amount, description, entry.key);
              debugPrint("Success parsing with specific Regex rule for ${entry.key}.");
              return true; // Berhasil, hentikan proses.
            }
          }
        }
      }
    }
    return false; // Tidak ada aturan Regex yang cocok.
  }

  /// [CADANGAN] Mencoba mem-parsing menggunakan kata kunci umum.
  static Future<void> _tryParseWithKeywords(String lowerCasePackage, String text) async {
    final lowerCaseText = text.toLowerCase();
    
    final amountPattern = RegExp(r'(?:Rp|sebesar)\s*([\d.,]+)', caseSensitive: false);
    final amountMatch = amountPattern.firstMatch(text);
    if (amountMatch == null) return;
    
    final amountString = amountMatch.group(1)!.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountString);
    if (amount == null) return;
    
    const expenseKeywords = ['transfer ke', 'mengirim', 'bayar', 'pembayaran', 'terpakai', 'transaksi keluar'];
    const incomeKeywords = ['menerima', 'transfer dari', 'masuk', 'diterima', 'terima uang', 'penerimaan dana', 'top up'];
    
    TransactionType? type;
    if (expenseKeywords.any((keyword) => lowerCaseText.contains(keyword))) {
      type = TransactionType.pengeluaran;
    } else if (incomeKeywords.any((keyword) => lowerCaseText.contains(keyword))) {
      type = TransactionType.pemasukan;
    }

    if (type == null) return;

    final packageHints = {
      'seabank': 'SeaBank', 'bca': 'BCA', 'bri.brimo': 'BRI', 'bni.mobile': 'BNI',
      'bankmandiri.livin': 'Mandiri', 'jago': 'Jago', 'ocbc.mobile': 'OCBC',
      'gopay': 'Gopay', 'gojek': 'Gopay', 'dana': 'DANA', 'shopee': 'ShopeePay',
      'ovo': 'OVO', 'linkaja': 'LinkAja',
    };
    
    String? accountHint;
    for (var key in packageHints.keys) {
      if (lowerCasePackage.contains(key)) {
        accountHint = packageHints[key];
        break;
      }
    }
    
    if (accountHint != null) {
      await _saveTransaction(type, amount, 'Transaksi Otomatis', accountHint);
    }
  }

  /// Fungsi utilitas untuk menyimpan transaksi ke database.
  static Future<void> _saveTransaction(TransactionType type, double amount, String description, String accountHint) async {
    final allAccounts = await dbHelper.getAccounts();
    if (allAccounts.isEmpty) {
        debugPrint('Parser: No accounts available. Transaction cancelled.');
        return;
    }

    Account? targetAccount;
    try {
      targetAccount = allAccounts.firstWhere(
        (acc) => acc.name.toLowerCase().contains(accountHint.toLowerCase()),
      );
    } catch (e) {
      debugPrint('Parser: Account for "$accountHint" not found. Using the first account as default.');
      targetAccount = allAccounts.first;
    }

    final newTransaction = Transaction(
      description: description,
      amount: amount,
      date: DateTime.now(),
      type: type,
      accountId: targetAccount.id!,
    );
    
    await dbHelper.insertTransaction(newTransaction);
    
    // <-- 2. KIRIM SINYAL SETELAH TRANSAKSI BERHASIL DISIMPAN
    TransactionStream.newTransactionAdded();

    debugPrint('Parser: Auto transaction from "$accountHint" saved successfully and signal sent.');
  }

  // --- KUMPULAN ATURAN REGEX SPESIFIK ---

  static final List<Map<String, dynamic>> _seaBankRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"menerima transfer sebesar Rp([\d.,]+)"), 'description': 'Transfer Masuk SeaBank'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Kamu baru melakukan transfer senilai Rp([\d.,]+)"), 'description': 'Realtime Transfer'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Pembayaran QRIS sebesar Rp([\d.,]+) di (.+) berhasil"), 'desc_prefix': 'QRIS: '},
  ];

  static final List<Map<String, dynamic>> _bcaRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"m-Transfer dari (.+) BERHASIL Rp([\d.,]+)"), 'desc_prefix': 'Trf. dari: '},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"m-Transfer ke (.+) BERHASIL Rp([\d.,]+)"), 'desc_prefix': 'Trf. ke: '},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Pembayaran QR Rp([\d.,]+) di (.+) berhasil"), 'desc_prefix': 'QRIS: '},
  ];

  static final List<Map<String, dynamic>> _gopayRules = [
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"GoPay terpakai Rp([\d.,]+) bwt bayar"), 'description': 'Bayar pakai GoPay'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Kamu bayar Rp([\d.,]+) ke (.+)\."), 'desc_prefix': 'Bayar ke: '},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Kamu berhasil transfer Rp([\d.,]+) ke (.+)\."), 'desc_prefix': 'Transfer ke: '},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Kamu berhasil top up GoPay Rp([\d.,]+)"), 'description': 'Top Up GoPay'},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Dapet cashback Rp([\d.,]+)"), 'description': 'Cashback GoPay'},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Kamu dapet GoPay, nih Rp([\d.,]+)"), 'description': 'Terima GoPay'},
  ];

  // ... (Sisa aturan lainnya bisa ditambahkan di sini dengan format yang sama)
  static final List<Map<String, dynamic>> _briRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"penerimaan dana Rp([\d.,]+) dari"), 'description': 'Penerimaan Dana BRI'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Transaksi Keluar: Rp ([\d.,]+)"), 'description': 'Transaksi Keluar BRI'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Pembayaran QR sejumlah Rp ([\d.,]+) pada"), 'description': 'Pembayaran QRIS BRI'},
  ];

  static final List<Map<String, dynamic>> _bniRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Anda menerima Rp([\d.,]+) dari"), 'description': 'Penerimaan Dana BNI'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Trf keluar Rp([\d.,]+) ke"), 'description': 'Transfer Keluar BNI'},
  ];

  static final List<Map<String, dynamic>> _mandiriRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"terima transfer Rp ([\d.,]+) dari"), 'description': 'Terima Transfer Livin'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Transfer Rp ([\d.,]+) ke (.+) Berhasil"), 'desc_prefix': 'Trf. ke: '},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Bayar Rp ([\d.,]+) di (.+) pakai QRIS Berhasil"), 'desc_prefix': 'QRIS: '},
  ];
  
  static final List<Map<String, dynamic>> _jagoRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Kamu terima uang Rp([\d.,]+)"), 'description': 'Terima Uang Jago'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Kamu bayar Rp([\d.,]+) ke (.+)"), 'desc_prefix': 'Bayar ke: '},
  ];

  static final List<Map<String, dynamic>> _ocbcRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Anda menerima dana sebesar Rp ([\d.,]+)"), 'description': 'Terima Dana OCBC'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Anda telah mentransfer Rp ([\d.,]+)"), 'description': 'Transfer OCBC'},
  ];

  static final List<Map<String, dynamic>> _danaRules = [
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Berhasil bayar Rp([\d.,]+) di"), 'description': 'Bayar pakai DANA'},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Kamu terima Rp([\d.,]+) dari"), 'description': 'Terima DANA'},
  ];

  static final List<Map<String, dynamic>> _shopeePayRules = [
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Pembayaran sebesar Rp([\d.,]+) ke (.+) telah berhasil"), 'desc_prefix': 'Bayar ke: '},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Kamu menerima transfer ShopeePay sebesar Rp([\d.,]+)"), 'description': 'Terima ShopeePay'},
  ];

  static final List<Map<String, dynamic>> _ovoRules = [
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Pembayaran ke (.+) sebesar Rp([\d.,]+) berhasil"), 'desc_prefix': 'Bayar ke: '},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Transfer sebesar Rp([\d.,]+) dari (.+) diterima"), 'desc_prefix': 'Trf. dari: '},
  ];
  
  static final List<Map<String, dynamic>> _linkAjaRules = [
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Transaksi sebesar Rp ([\d.,]+) di (.+) SUKSES"), 'desc_prefix': 'Bayar di: '},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Kamu terima uang Rp([\d.,]+)"), 'description': 'Terima LinkAja'},
  ];
}
