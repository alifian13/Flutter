import '../../data/local/models/account_model.dart';
import '../../data/local/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
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
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(labelText: 'Saldo Awal (Rp)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newAccount = Account()
                    ..name = nameController.text
                    ..initialBalance = double.parse(balanceController.text)
                    ..icon = 'wallet';

                  await Hive.box<Account>('accounts').add(newAccount);

                  final newTransaction = Transaction()
                    ..description = 'Saldo Awal'
                    ..amount = newAccount.initialBalance
                    ..date = DateTime.now()
                    ..type = TransactionType.pemasukan
                    ..account = newAccount;

                  await Hive.box<Transaction>('transactions').add(newTransaction);
                  
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
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
      body: ValueListenableBuilder<Box<Account>>(
        valueListenable: Hive.box<Account>('accounts').listenable(),
        builder: (context, box, _) {
          final accounts = box.values.toList();
          if (accounts.isEmpty) {
            return const Center(child: Text('Tidak ada akun.'));
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(account.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    // Logika hapus bisa ditambahkan di sini,
                    // perlu konfirmasi dan menghapus transaksi terkait.
                    // Untuk saat ini, kita disable dulu.
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
