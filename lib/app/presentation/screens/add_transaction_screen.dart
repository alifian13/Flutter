import 'package:flutter/material.dart';
import '../../data/local/models/transaction_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State untuk menyimpan tipe transaksi yang dipilih, default-nya pengeluaran
  TransactionType _selectedType = TransactionType.pengeluaran;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget untuk memilih tipe Pemasukan atau Pengeluaran
              SegmentedButton<TransactionType>(
                segments: const <ButtonSegment<TransactionType>>[
                  ButtonSegment<TransactionType>(
                    value: TransactionType.pengeluaran,
                    label: Text('Pengeluaran'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.pemasukan,
                    label: Text('Pemasukan'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: <TransactionType>{_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Form untuk Keterangan
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  hintText: 'Contoh: Bayar Listrik',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Keterangan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Form untuk Nominal
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  hintText: 'Contoh: 150000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Cek jika semua form valid
                    if (_formKey.currentState!.validate()) {
                      // Ambil box Hive
                      final transactionBox = Hive.box<Transaction>(
                        'transactions',
                      );

                      // Buat objek transaksi baru dari input pengguna
                      final newTransaction =
                          Transaction()
                            ..description = _descriptionController.text
                            ..amount = double.parse(_amountController.text)
                            ..date = DateTime.now()
                            ..type = _selectedType; // Simpan tipe yang dipilih

                      // Tambahkan objek ke box
                      transactionBox.add(newTransaction);

                      // Tampilkan notifikasi snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaksi berhasil disimpan!'),
                        ),
                      );

                      // Kembali ke halaman sebelumnya
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
