import '../app/presentation/screens/home_screen.dart';
import '../app/data/local/models/transaction_model.dart';
// import '../app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../app/data/local/models/account_model.dart';
import '/core/utils/constants.dart';
import '/app/presentation/screens/onboarding_screen.dart';

// Tambahkan konstanta untuk nama Hive box jika belum ada
const String kAccountsBox = 'accounts';
const String kTransactionsBox = 'transactions';

void main() async {
  // 1. Pastikan Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi format tanggal
  await initializeDateFormatting('id_ID', null);

  // 3. Inisialisasi Hive
  await Hive.initFlutter();

  // 4. Daftarkan semua Adapter
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  // Jika Anda punya model Category, daftarkan adapter-nya di sini
  // Hive.registerAdapter(CategoryAdapter());

  // 5. Buka semua box yang diperlukan
  await Hive.openBox('settings');
  await Hive.openBox<Account>(kAccountsBox);
  await Hive.openBox<Transaction>(kTransactionsBox);
  // Jika Anda punya model Category, buka box-nya di sini
  // await Hive.openBox<Category>(kCategoriesBox);

  // 6. Ambil referensi box
  final settingsBox = Hive.box('settings');
  final accountsBox = Hive.box<Account>(kAccountsBox);

  // --- LOGIKA PENGAMAN DATA HILANG (Tetap Dipertahankan) ---
  bool onboardingCompleted = settingsBox.get(kOnboardingCompletedKey, defaultValue: false);
  bool accountDataExists = accountsBox.isNotEmpty;

  if (accountDataExists && !onboardingCompleted) {
    await settingsBox.put(kOnboardingCompletedKey, true);
    onboardingCompleted = true;
  }
  // --- Akhir Logika Pengaman ---

  // 7. Hapus logika memulai Notification Service dari sini untuk mencegah crash

  // 8. Jalankan aplikasi
  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;

  const MyApp({
    super.key,
    required this.onboardingCompleted,
  });

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
      home: onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}