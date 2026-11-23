import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final supabaseKey = supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : supabaseAnonKey;
  final configured = supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
  if (configured) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  runApp(InventoryApp(configured: configured));
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key, required this.configured});

  final bool configured;

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
      home: configured
          ? const AuthenticationGate()
          : const SupabaseConfigurationScreen(),
    );
  }
}

class SupabaseConfigurationScreen extends StatelessWidget {
  const SupabaseConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 54),
            const SizedBox(height: 16),
            Text('Falta configurar Supabase', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Inicia la aplicación con SUPABASE_URL y SUPABASE_ANON_KEY. '
              'Consulta README.md para configurar el servicio y sus políticas de seguridad.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({super.key});

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  late Session? _session;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _session = auth.currentSession;
    _authSubscription = auth.onAuthStateChange.listen((state) {
      if (mounted) setState(() => _session = state.session);
    });
  }

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _session == null ? const AuthScreen() : const HomeScreen();
}
