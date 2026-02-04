import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../service/supabase_service.dart';
import '../service/navigation_service.dart';

import '../screen/page/login.dart';
import '../screen/page/dashboard.dart';
import '../screen/page/kategori.dart';
import '../screen/utils/theme.dart';
import '../screen/page/daftar_alat.dart';
import '../screen/page/user.dart';
import '../screen/page/daftar_pinjam.dart';
import '../screen/page/logs.dart';
import '../screen/page/penerimaan.dart';
import '../screen/page/laporan.dart';
import '../screen/page/alat.dart';
import '../screen/page/peminjaman.dart';
import '../screen/page/splash_screen.dart';
import '../screen/page/hari.dart';
import '../screen/page/pemanjangan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id', null);

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
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MesinKita',
      theme: AppTheme.lightTheme(context),

      // 🔑 START DARI SPLASH
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/auth': (_) => const AuthGate(),
        '/login': (_) => const LoginPage(),

        '/dashboard': (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String?;
          return DashboardPage(role: role ?? 'peminjam');
        },

        '/kategori': (_) => const KategoriPage(),
        '/daftaralat': (_) => const DaftarAlatPage(),
        '/user': (_) => const UserPage(),
        '/daftarpeminjaman': (_) => const DaftarPinjam(),
        '/logs': (_) => const LogsPage(),
        '/penerimaan': (_) => const PenerimaanPage(),
        '/laporan': (_) => const LaporanPage(),
        '/alat': (_) => const AlatPage(),
        '/pinjam': (_) => const PeminjamanPage(),
        '/panjang': (_) => const PemanjanganPage(),
        '/hari': (_) => const HariPage(),
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
    _checkAuth();
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
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
