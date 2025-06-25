import '../data/local/models/account_model.dart';
import '../data/local/models/transaction_model.dart';
import '/core/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class NotificationParser {
  /// Titik masuk utama untuk mem-parsing notifikasi.
  /// Bertindak sebagai router untuk memanggil parser yang sesuai berdasarkan nama paket.
  static Future<void> parseAndSave(String packageName, String text) async {
    // Menormalkan nama paket untuk pencocokan yang lebih mudah
    final lowerCasePackage = packageName.toLowerCase();

    // Router untuk setiap layanan keuangan
    if (lowerCasePackage.contains('seabank')) {
      _parseTransaction(text, _seaBankRules, 'SeaBank');
    } else if (lowerCasePackage.contains('bca')) {
      _parseTransaction(text, _bcaRules, 'BCA');
    } else if (lowerCasePackage.contains('bri.brimo')) {
      _parseTransaction(text, _briRules, 'BRI');
    } else if (lowerCasePackage.contains('bni.mobile')) {
      _parseTransaction(text, _bniRules, 'BNI');
    } else if (lowerCasePackage.contains('bankmandiri.livin')) {
      _parseTransaction(text, _mandiriRules, 'Mandiri');
    } else if (lowerCasePackage.contains('jago')) {
      _parseTransaction(text, _jagoRules, 'Jago');
    } else if (lowerCasePackage.contains('ocbc.mobile')) {
      _parseTransaction(text, _ocbcRules, 'OCBC');
    } else if (lowerCasePackage.contains('gojek.app') || lowerCasePackage.contains('gopay')) {
      _parseTransaction(text, _gopayRules, 'Gopay');
    } else if (lowerCasePackage.contains('id.dana')) {
      _parseTransaction(text, _danaRules, 'Dana');
    } else if (lowerCasePackage.contains('shopee')) {
      _parseTransaction(text, _shopeePayRules, 'ShopeePay');
    } else if (lowerCasePackage.contains('id.ovo')) {
      _parseTransaction(text, _ovoRules, 'OVO');
    } else if (lowerCasePackage.contains('linkaja')) {
      _parseTransaction(text, _linkAjaRules, 'LinkAja');
    }
  }

  /// Fungsi generik untuk memproses teks notifikasi berdasarkan sekumpulan aturan.
  static void _parseTransaction(String text, List<Map<String, dynamic>> rules, String accountHint) {
    for (var rule in rules) {
      final match = (rule['regex'] as RegExp).firstMatch(text);
      if (match != null) {
        final amountString = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
        final amount = double.tryParse(amountString);

        if (amount != null) {
          // Menggunakan deskripsi dari aturan, dengan fallback.
          String description = rule['description'] ?? 'Transaksi $accountHint';
          // Jika ada grup deskripsi di regex, gunakan itu.
          if (match.groupCount > 1 && match.group(2) != null) {
            description = '${rule['desc_prefix'] ?? ''}${match.group(2)}'.trim();
          }

          _saveTransaction(rule['type'], amount, description, accountHint);
          // Hentikan setelah aturan pertama yang cocok ditemukan
          return;
        }
      }
    }
  }

  /// Menyimpan transaksi yang berhasil di-parsing ke database.
  static Future<void> _saveTransaction(TransactionType type, double amount, String description, String accountHint) async {
    final accountBox = Hive.box<Account>('accounts');
    Account? targetAccount;
    try {
      targetAccount = accountBox.values.firstWhere(
        (acc) => acc.name.toLowerCase().contains(accountHint.toLowerCase()),
      );
    } catch (e) {
      debugPrint('Akun untuk "$accountHint" tidak ditemukan. Transaksi otomatis dibatalkan.');
      return;
    }

    final newTransaction = Transaction()
      ..description = description
      ..amount = amount
      ..date = DateTime.now()
      ..type = type
      ..account = targetAccount;

    final transactionBox = Hive.box<Transaction>(kTransactionsBox);
    await transactionBox.add(newTransaction);
    debugPrint('Transaksi otomatis dari $accountHint berhasil disimpan: $description sejumlah $amount');
  }

  // --- KUMPULAN ATURAN PARSING UNTUK SETIAP APLIKASI ---

  static final List<Map<String, dynamic>> _seaBankRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"menerima transfer sebesar Rp([\d.,]+)"), 'description': 'Transfer Masuk SeaBank'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"mengirimkan uang sebesar Rp([\d.,]+)"), 'description': 'Transfer Keluar SeaBank'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Pembayaran QRIS sebesar Rp([\d.,]+) di (.+) berhasil"), 'desc_prefix': 'QRIS: '},
  ];

  static final List<Map<String, dynamic>> _bcaRules = [
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"m-Transfer dari (.+) BERHASIL Rp([\d.,]+)"), 'desc_prefix': 'Trf. dari: '},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"m-Transfer ke (.+) BERHASIL Rp([\d.,]+)"), 'desc_prefix': 'Trf. ke: '},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Pembayaran QR Rp([\d.,]+) di (.+) berhasil"), 'desc_prefix': 'QRIS: '},
  ];
  
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

  static final List<Map<String, dynamic>> _gopayRules = [
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"GoPay terpakai Rp([\d.,]+) bwt bayar"), 'description': 'Bayar pakai GoPay'},
    {'type': TransactionType.pengeluaran, 'regex': RegExp(r"Kamu bayar Rp([\d.,]+) ke (.+)."), 'desc_prefix': 'Bayar ke: '},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Kamu berhasil top up GoPay Rp([\d.,]+)"), 'description': 'Top Up GoPay'},
    {'type': TransactionType.pemasukan, 'regex': RegExp(r"Dapet cashback Rp([\d.,]+)"), 'description': 'Cashback GoPay'},
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