import 'package:flutter/material.dart';
import '../../data/local/models/account_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/local/database_helper.dart';
import '/core/utils/constants.dart';

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
  final dbHelper = DatabaseHelper();

  List<Account> _accounts = [];
  Account? _selectedAccount;
  late TransactionType _selectedType;
  late bool _isEditMode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transactionToEdit != null;
    _loadInitialData();
  }
  
  /// Memuat data awal seperti daftar akun dari database.
  Future<void> _loadInitialData() async {
    final accountsData = await dbHelper.getAccounts();
    setState(() {
      _accounts = accountsData;
      
      if (_isEditMode) {
        final trx = widget.transactionToEdit!;
        _descriptionController.text = trx.description;
        _amountController.text = trx.amount.toStringAsFixed(0);
        _selectedType = trx.type;
        // Cari akun yang cocok berdasarkan ID
        if (_accounts.isNotEmpty) {
          _selectedAccount = _accounts.firstWhere((acc) => acc.id == trx.accountId, orElse: () => _accounts.first);
        }
      } else {
        _selectedType = TransactionType.pengeluaran;
        if (_accounts.isNotEmpty) {
          _selectedAccount = _accounts.first;
        }
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Menyimpan data transaksi baru atau perubahan ke database.
  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada akun tersedia. Harap buat akun terlebih dahulu.')),
        );
        return;
      }
      
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;

      if (_isEditMode) {
        // Buat objek baru untuk update, pastikan ID dan tanggal tidak berubah
        final updatedTransaction = Transaction(
          id: widget.transactionToEdit!.id,
          description: description,
          amount: amount,
          date: widget.transactionToEdit!.date, // Gunakan tanggal asli
          type: _selectedType,
          accountId: _selectedAccount!.id!,
        );
        await dbHelper.updateTransaction(updatedTransaction);
      } else {
        final newTransaction = Transaction(
          description: description,
          amount: amount,
          date: DateTime.now(),
          type: _selectedType,
          accountId: _selectedAccount!.id!,
        );
        await dbHelper.insertTransaction(newTransaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaksi berhasil ${_isEditMode ? 'diperbarui' : 'disimpan'}!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi Baru'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty && !_isEditMode
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Anda belum memiliki akun.\nHarap buat akun di menu Pengaturan terlebih dahulu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        ElevatedButton(
                          onPressed: _submitData,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(_isEditMode ? 'Simpan Perubahan' : 'Simpan'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}