import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_gate.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('theme_mode');
  if (saved == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (saved == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value =
        ThemeMode.system; // default / no explicit choice saved
  }
}

Future<void> saveThemePreference(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  if (mode == ThemeMode.light) {
    await prefs.setString('theme_mode', 'light');
  } else if (mode == ThemeMode.dark) {
    await prefs.setString('theme_mode', 'dark');
  } else {
    await prefs.remove('theme_mode');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await loadSavedTheme();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Study Buddy',
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey[850]!,
              primary: Colors.grey[900],
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.grey[300]!,
              primary: Colors.grey[300],
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthGate(),
        );
      },
    );
  }
}
