import 'package:frontend/core/utils/formatter.dart';
import '../../data/local/models/transaction_model.dart';
import '../../presentation/screens/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  /// Callback yang akan dipanggil saat item dihapus.
  /// Ini akan meneruskan ID transaksi yang akan dihapus.
  final Future<void> Function(int) onDelete;
  /// Callback untuk merefresh data setelah edit.
  final VoidCallback onEdit;


  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan warna dan ikon berdasarkan tipe transaksi
    final bool isExpense = transaction.type == TransactionType.pengeluaran;
    final Color color = isExpense ? Colors.redAccent : Colors.green;
    final IconData iconData =
        isExpense ? Icons.arrow_upward : Icons.arrow_downward;

    final amountFormatted = AppFormatters.toRupiah(transaction.amount);
    final dateFormatted =
        DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(transaction.date);

    // BUNGKUS DENGAN DISMISSIBLE UNTUK FUNGSI GESER-HAPUS
    return Dismissible(
      key: ValueKey(transaction.id), // Gunakan ID transaksi sebagai kunci unik
      direction: DismissDirection.endToStart, // Arah swipe dari kanan ke kiri
      // Tampilan latar belakang saat di-swipe
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // Konfirmasi sebelum menghapus
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Konfirmasi Hapus"),
              content: Text("Anda yakin ingin menghapus transaksi '${transaction.description}'?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      // Aksi yang dijalankan setelah item dikonfirmasi untuk dihapus
      onDismissed: (direction) {
        onDelete(transaction.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaksi "${transaction.description}" dihapus')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          onTap: () async {
            // Navigasi ke halaman edit saat item di-tap
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransactionScreen(transactionToEdit: transaction),
              ),
            );
            // Refresh data di home screen setelah kembali dari edit
            onEdit();
          },
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(iconData, color: color),
          ),
          title: Text(
            transaction.description,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            // Gunakan `accountName` yang didapat dari JOIN query di database helper
            '${transaction.accountName ?? 'Tanpa Akun'} • $dateFormatted',
          ),
          trailing: Text(
            '${isExpense ? '-' : '+'} $amountFormatted',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
