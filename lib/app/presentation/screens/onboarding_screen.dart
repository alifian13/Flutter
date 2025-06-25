import '../../data/local/models/account_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/local/database_helper.dart';
import '../screens/home_screen.dart';
import '/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // List untuk menampung akun yang akan dibuat sementara di memori
  final List<Account> _accounts = [];
  bool _isLoading = false;
  final dbHelper = DatabaseHelper();

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
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
                  decoration: const InputDecoration(labelText: 'Nama Akun (Contoh: BCA, Gopay)'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nama tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(labelText: 'Saldo Awal (Rp)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Saldo tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _accounts.add(Account(
                      name: nameController.text,
                      initialBalance: double.parse(balanceController.text),
                      icon: 'wallet', // Ikon default
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  /// Menyimpan semua akun dan transaksi awal ke database SQLite.
  Future<void> _finishOnboarding() async {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap tambahkan minimal satu akun.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Proses setiap akun satu per satu untuk disimpan ke database
      for (var account in _accounts) {
        // 1. Simpan akun ke database dan dapatkan ID yang baru dibuat.
        final accountId = await dbHelper.insertAccount(account);

        // 2. Jika saldo awal lebih dari 0, buat transaksi "Saldo Awal"
        if (account.initialBalance > 0) {
          final initialTransaction = Transaction(
            description: 'Saldo Awal',
            amount: account.initialBalance,
            date: DateTime.now(),
            type: TransactionType.pemasukan,
            accountId: accountId, // Gunakan ID dari akun yang baru disimpan
          );
           // 3. Simpan transaksi awal tersebut.
          await dbHelper.insertTransaction(initialTransaction);
        }
      }

      // 4. Tandai bahwa proses onboarding telah selesai menggunakan SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingCompletedKey, true);

      // 5. Pindahkan pengguna ke halaman utama.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
        setState(() => _isLoading = false);
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Terjadi error: $e')),
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selamat Datang di Ceban!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Langkah 1: Tambahkan Akun Anda',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tambahkan semua sumber dana Anda, seperti rekening bank, e-wallet, atau dompet tunai.'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Akun Baru'),
                    onPressed: _showAddAccountDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: _accounts.isEmpty
                        ? const Center(child: Text('Belum ada akun ditambahkan.'))
                        : ListView.builder(
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) {
                              final account = _accounts[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.account_balance_wallet),
                                  title: Text(account.name),
                                  subtitle: Text('Saldo Awal: Rp ${account.initialBalance.toStringAsFixed(0)}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _accounts.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  ElevatedButton(
                    onPressed: _finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Selesai & Mulai Gunakan Aplikasi'),
                  ),
                ],
              ),
      ),
    );
  }
}
