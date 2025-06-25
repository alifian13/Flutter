import 'package:frontend/core/utils/formatter.dart';

import '../../data/local/models/transaction_model.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Tentukan warna dan ikon berdasarkan tipe transaksi
    final bool isExpense = transaction.type == TransactionType.pengeluaran;
    final Color color = isExpense ? Colors.red : Colors.green;
    final IconData iconData = isExpense ? Icons.arrow_upward : Icons.arrow_downward;

    final amountFormatted = AppFormatters.toRupiah(transaction.amount);

    final dateFormatted = DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(transaction.date);

    // BUNGKUS DENGAN DISMISSIBLE
    return Dismissible(
      key: UniqueKey(), // Kunci unik untuk setiap item
      direction: DismissDirection.endToStart, // Arah swipe dari kanan ke kiri
      // Tampilan latar belakang saat di-swipe
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // Aksi yang dijalankan setelah item di-swipe penuh
      onDismissed: (direction) {
        // Hapus transaksi dari database
        transaction.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${transaction.description} dihapus')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(iconData, color: color),
          ),
          title: Text(
            transaction.description,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(dateFormatted),
          trailing: Text(
            amountFormatted,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color, // Gunakan warna yang sudah ditentukan
            ),
          ),
        ),
      ),
    );
  }
}