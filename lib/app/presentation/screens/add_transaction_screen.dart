import 'package:flutter/material.dart';
import '../../data/local/models/account_model.dart';
import '../../data/local/models/transaction_model.dart';
import '/core/utils/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late List<Account> _accounts;
  Account? _selectedAccount;
  late TransactionType _selectedType;
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _accounts = Hive.box<Account>('accounts').values.toList();
    _isEditMode = widget.transactionToEdit != null;

    if (_isEditMode) {
      final trx = widget.transactionToEdit!;
      _descriptionController.text = trx.description;
      _amountController.text = trx.amount.toStringAsFixed(0);
      _selectedType = trx.type;
      _selectedAccount = trx.account;
    } else {
      _selectedType = TransactionType.pengeluaran;
      if (_accounts.isNotEmpty) {
        _selectedAccount = _accounts.first;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitData() {
    if (_formKey.currentState!.validate() && _selectedAccount != null) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;

      if (_isEditMode) {
        final editedTransaction = widget.transactionToEdit!;
        editedTransaction.description = description;
        editedTransaction.amount = amount;
        editedTransaction.type = _selectedType;
        editedTransaction.account = _selectedAccount!;
        editedTransaction.save();
      } else {
        final newTransaction = Transaction()
          ..description = description
          ..amount = amount
          ..date = DateTime.now()
          ..type = _selectedType
          ..account = _selectedAccount!;

        final transactionBox = Hive.box<Transaction>(kTransactionsBox);
        transactionBox.add(newTransaction);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi berhasil ${_isEditMode ? 'diperbarui' : 'disimpan'}!')),
      );
      Navigator.pop(context);
    } else if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada akun tersedia. Harap buat akun terlebih dahulu.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi Baru'),
      ),
      body: _accounts.isEmpty && !_isEditMode
          ? const Center(
              child: Text(
                'Anda belum memiliki akun.\nHarap buat akun di menu Pengaturan terlebih dahulu.',
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown untuk memilih akun
                    DropdownButtonFormField<Account>(
                      value: _selectedAccount,
                      items: _accounts.map((Account account) {
                        return DropdownMenuItem<Account>(
                          value: account,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (Account? newValue) {
                        setState(() {
                          _selectedAccount = newValue;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Akun',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null ? 'Harap pilih akun' : null,
                    ),
                    const SizedBox(height: 16),
                    // Tombol Pemasukan/Pengeluaran
                    SegmentedButton<TransactionType>(
                      segments: const <ButtonSegment<TransactionType>>[
                        ButtonSegment<TransactionType>(
                            value: TransactionType.pengeluaran,
                            label: Text('Pengeluaran')),
                        ButtonSegment<TransactionType>(
                            value: TransactionType.pemasukan,
                            label: Text('Pemasukan')),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<TransactionType> newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Form Keterangan
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Keterangan tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    // Form Nominal
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Nominal (Rp)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Nominal tidak boleh kosong';
                        if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitData,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_isEditMode ? 'Simpan Perubahan' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}