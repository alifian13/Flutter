import '../screens/add_transaction_screen.dart';
import '../../data/local/models/account_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../services/notification_service.dart';
import '../screens/settings_screen.dart';
import '../widgets/transaction_list_item.dart';
import '../../../core/utils/constants.dart';
import '/core/utils/formatter.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Tambahkan definisi kAccountsBox jika belum ada
const String kAccountsBox = 'accounts';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- MULAI BLOK PERBAIKAN ---
  @override
  void initState() {
    super.initState();
    // Panggil fungsi untuk memulai layanan notifikasi setelah frame UI pertama selesai dibangun.
    // Ini adalah kunci untuk mencegah crash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateNotificationService();
    });
  }

  /// Fungsi baru untuk memulai layanan notifikasi secara aman.
  Future<void> _initiateNotificationService() async {
    // Cek dulu apakah izin sudah diberikan oleh pengguna.
    if (await AppNotificationService.isPermissionGranted()) {
      // Jika ya, baru mulai mendengarkan notifikasi.
      // Melakukan ini di sini (setelah UI stabil) jauh lebih aman daripada di main().
      await AppNotificationService.startListening();
      debugPrint("Notification service started safely from HomeScreen.");
    } else {
      debugPrint("Notification permission not granted. Service not started.");
    }
  }
  // --- AKHIR BLOK PERBAIKAN ---


  // Fungsi _calculateBalance Anda tetap dipertahankan seperti semula.
  double _calculateBalance(Account account, List<Transaction> allTransactions) {
    double balance = 0;
    // Filter transaksi hanya untuk akun ini
    final accountTransactions = allTransactions.where((t) => t.account.key == account.key);
    for (var trx in accountTransactions) {
      if (trx.type == TransactionType.pemasukan) {
        balance += trx.amount;
      } else {
        balance -= trx.amount;
      }
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    // Keseluruhan method build Anda tidak diubah sama sekali.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceban - Dompetku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => setState(() {})); // Refresh UI setelah kembali dari pengaturan
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Transaction>>(
        valueListenable: Hive.box<Transaction>(kTransactionsBox).listenable(),
        builder: (context, transactionBox, _) {
          final allTransactions = transactionBox.values.toList();
          allTransactions.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian 1: Daftar Akun
              SizedBox(
                height: 110,
                child: ValueListenableBuilder<Box<Account>>(
                  valueListenable: Hive.box<Account>(kAccountsBox).listenable(),
                  builder: (context, accountBox, __) {
                    final accounts = accountBox.values.toList();
                    if (accounts.isEmpty) {
                      return const Center(child: Text("Tidak ada akun."));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final balance = _calculateBalance(account, allTransactions);
                        return AccountCard(account: account, balance: balance);
                      },
                    );
                  },
                ),
              ),

              // Bagian 2: Riwayat Transaksi
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Riwayat Transaksi Terbaru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: allTransactions.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada transaksi.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: allTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = allTransactions[index];
                          return TransactionListItem(transaction: transaction);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        tooltip: 'Tambah Transaksi',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget untuk kartu akun Anda tidak diubah.
class AccountCard extends StatelessWidget {
  final Account account;
  final double balance;

  const AccountCard({
    super.key,
    required this.account,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, Colors.deepPurple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              account.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              AppFormatters.toRupiah(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
