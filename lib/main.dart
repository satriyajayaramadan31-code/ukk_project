import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/supabase_service.dart';
import '../service/navigation_service.dart';

import '../screen/page/login.dart';
import '../screen/page/dashboard.dart';
import '../screen/page/kategori.dart';
import '../screen/utils/theme.dart';
import '../screen/page/daftar_alat.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wepurbkcpvwxuevcqzmd.supabase.co',
    anonKey: 'sb_publishable_wKOyVfDrzFSrScFebReB1g_scuHipUK',
  );

  Supabase.instance.client.realtime.onError((error) {
    debugPrint('🔥 Supabase Realtime Error: $error');
  });

  FlutterError.onError = (details) {
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint(details.stack.toString());
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey, // HARUS ADA
      debugShowCheckedModeBanner: false,
      title: 'PeMeJam',
      theme: AppTheme.lightTheme(context),

      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        '/login': (_) => const LoginPage(),

        '/dashboard': (context) {
          final role =
              ModalRoute.of(context)!.settings.arguments as String?;
          return DashboardPage(role: role ?? 'peminjam');
        },

        '/kategori': (_) => const KategoriPage(),
        '/daftaralat': (_) => const DaftarAlatPage(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    if (_hasNavigated) return;

    final isLoggedIn = await SupabaseService.isLoggedIn();
    if (!mounted) return;

    _hasNavigated = true;

    if (isLoggedIn) {
      final role = await SupabaseService.getRole();
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (_) => false,
        arguments: role ?? 'peminjam',
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
