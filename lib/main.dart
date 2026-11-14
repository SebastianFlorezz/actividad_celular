import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/home_screen.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  await DatabaseService.instance.database;
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF172B4D);
    const green = Color(0xFF167D68);

    return MaterialApp(
      title: 'Nexo Inventario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: green,
          secondary: const Color(0xFFE7A94B),
          surface: Colors.white,
          onSurface: ink,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF657184)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F6),
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
