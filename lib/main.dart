import '../app/presentation/screens/home_screen.dart';
import '../app/data/local/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../app/data/local/models/account_model.dart';
import '/core/utils/constants.dart';
import '/app/presentation/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // 1. Pastikan Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi format tanggal untuk bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // 3. Gunakan SharedPreferences untuk mengecek status onboarding
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted =
      prefs.getBool(kOnboardingCompletedKey) ?? false;

  // 4. Jalankan aplikasi, arahkan ke layar yang sesuai
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
        )),
      ),
      debugShowCheckedModeBanner: false,
      home: onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
