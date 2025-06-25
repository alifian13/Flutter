import '../app/presentation/screens/home_screen.dart';
import '../app/data/local/models/transaction_model.dart';
import '../app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/data/local/models/account_model.dart';
import '/core/utils/constants.dart';
import '/app/presentation/screens/onboarding_screen.dart';

// Variabel global untuk melacak apakah ini peluncuran pertama
late bool isFirstLaunch;

void main() async {
  // 1. Pastikan Flutter siap sebelum menjalankan kode lain
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi format tanggal untuk Bahasa Indonesia
  await initializeDateFormatting('id_ID', null); 

  // 3. Inisialisasi Hive
  await Hive.initFlutter();

  // 4. Daftarkan semua Adapter yang kita miliki
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(AccountAdapter()); // <-- ADAPTER BARU DIDAFTARKAN

  // 5. Buka semua "box" yang diperlukan aplikasi
  await Hive.openBox<Transaction>(kTransactionsBox);
  await Hive.openBox<Account>('accounts'); // <-- BOX BARU DIBUKA

  // 6. Cek apakah ini pertama kalinya aplikasi dijalankan
  final prefs = await SharedPreferences.getInstance();
  // Menggunakan key dari file constants untuk konsistensi
  isFirstLaunch = prefs.getBool(kFirstLaunchKey) ?? true;

  // 7. Mulai mendengarkan notifikasi di background (jika diizinkan)
  if (await AppNotificationService.isPermissionGranted()) {
    await AppNotificationService.startListening();
  }
  
  // 8. Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceban',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          )
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: isFirstLaunch ? const OnboardingScreen() : const HomeScreen(), 
    );
  }
}
