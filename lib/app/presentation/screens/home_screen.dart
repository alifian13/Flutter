import 'dart:async';
import '../screens/add_transaction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/models/account_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../services/notification_service.dart';
import '../screens/settings_screen.dart';
import '../widgets/transaction_list_item.dart';
import '../../../core/utils/constants.dart';
import '/core/utils/formatter.dart';
import '../../data/local/database_helper.dart'; 
import '../../services/transaction_stream.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbHelper = DatabaseHelper();
  List<Account> _accounts = [];
  List<Transaction> _allTransactions = [];
  bool _isLoading = true;
  late StreamSubscription _transactionSubscription;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _transactionSubscription = TransactionStream.stream.listen((_) {
      debugPrint("New transaction signal received! Refreshing UI...");
      _refreshData();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateNotificationService();
    });
  }

  @override
  void dispose() {
    _transactionSubscription.cancel(); // Mencegah memory leak
    super.dispose();
  }

  Future<void> _refreshData() async {
    // Cek 'mounted' untuk memastikan widget masih ada di tree sebelum setState
    if (!mounted) return; 
    setState(() => _isLoading = true);
    try {
      final accountsData = await dbHelper.getAccounts();
      final transactionsData = await dbHelper.getTransactions();
      if (!mounted) return;
      setState(() {
        _accounts = accountsData;
        _allTransactions = transactionsData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error refreshing data: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiateNotificationService() async {
    if (await AppNotificationService.isPermissionGranted()) {
      await AppNotificationService.startListening();
      debugPrint("Notification service started safely from HomeScreen.");
    } else {
      debugPrint("Notification permission not granted. Service not started.");
    }
  }

  double _calculateBalance(Account account, List<Transaction> allTransactions) {
    double balance = account.initialBalance;
    final accountTransactions =
        allTransactions.where((t) => t.accountId == account.id);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceban - Dompetku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _refreshData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 110,
                  child: _accounts.isEmpty
                      ? const Center(child: Text("Tidak ada akun."))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: _accounts.length,
                          itemBuilder: (context, index) {
                            final account = _accounts[index];
                            final balance =
                                _calculateBalance(account, _allTransactions);
                            return AccountCard(account: account, balance: balance);
                          },
                        ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Riwayat Transaksi Terbaru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _allTransactions.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada transaksi.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _allTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _allTransactions[index];
                            // --- PERBAIKAN DI SINI ---
                            // Sekarang kita menyediakan parameter onDelete dan onEdit
                            return TransactionListItem(
                              transaction: transaction,
                              onEdit: _refreshData,
                              onDelete: (id) async {
                                await dbHelper.deleteTransaction(id);
                                _refreshData();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
          _refreshData();
        },
        tooltip: 'Tambah Transaksi',
        child: const Icon(Icons.add),
      ),
    );
  }
}

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
              overflow: TextOverflow.ellipsis,
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


