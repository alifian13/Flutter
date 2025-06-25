import '../../data/local/models/account_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/local/database_helper.dart';
import 'package:flutter/material.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final dbHelper = DatabaseHelper();
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAccountList();
  }

  /// Mengambil ulang daftar akun dari database.
  void _refreshAccountList() {
    setState(() {
      _accountsFuture = dbHelper.getAccounts();
    });
  }

  /// Menampilkan dialog untuk menambah akun baru.
  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false, // User harus menekan tombol
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Akun Baru'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Akun'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Nama akun wajib diisi' : null,
                ),
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(labelText: 'Saldo Awal (Rp)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Saldo awal wajib diisi';
                    if (double.tryParse(v) == null) return 'Masukkan angka yang valid';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newAccount = Account(
                    name: nameController.text,
                    initialBalance: double.parse(balanceController.text),
                    icon: 'wallet', // default icon
                  );

                  // Simpan akun baru dan dapatkan ID-nya
                  final accountId = await dbHelper.insertAccount(newAccount);

                  // Jika saldo awal lebih dari 0, buat transaksi "Saldo Awal"
                  if (newAccount.initialBalance > 0) {
                      final newTransaction = Transaction(
                          description: 'Saldo Awal',
                          amount: newAccount.initialBalance,
                          date: DateTime.now(),
                          type: TransactionType.pemasukan,
                          accountId: accountId,
                      );
                      await dbHelper.insertTransaction(newTransaction);
                  }
                  
                  if (mounted) {
                      Navigator.pop(context);
                      _refreshAccountList(); // Refresh list setelah menambah akun
                  }
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  /// Menampilkan dialog konfirmasi sebelum menghapus akun.
  void _confirmDeleteAccount(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: Text('Anda yakin ingin menghapus akun "${account.name}"? Semua transaksi yang terkait dengan akun ini juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await dbHelper.deleteAccount(account.id!);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Akun "${account.name}" berhasil dihapus.')),
                );
                _refreshAccountList();
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            onPressed: _showAddAccountDialog,
            tooltip: 'Tambah Akun',
          ),
        ],
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada akun. Tambahkan akun baru!'));
          }

          final accounts = snapshot.data!;
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(account.name),
                subtitle: Text('Saldo Awal: ${account.initialBalance.toStringAsFixed(0)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteAccount(account),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
