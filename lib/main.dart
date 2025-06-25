import '../app/presentation/screens/home_screen.dart';
import '../app/data/local/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Pastikan Flutter siap sebelum menjalankan kode lain
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null); 

  // Inisialisasi Hive
  await Hive.initFlutter();

  // Daftarkan Adapter yang sudah kita generate
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());

  // Buka "box" (seperti tabel) untuk menyimpan transaksi
  await Hive.openBox<Transaction>('transactions');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceban',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      home: const HomeScreen(), // Halaman pertama yang dibuka
    );
  }
}