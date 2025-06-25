import 'package:intl/intl.dart';

class AppFormatters {
  // Formatter untuk Rupiah
  static String toRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Formatter untuk Tanggal dan Waktu
  static String toDateTime(DateTime dateTime) {
    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }
}