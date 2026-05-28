import 'screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/search_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // Misafir modunu temizle (Google ile giriş için)
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('is_guest');
  await prefs.remove('guest_session_id');

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  runApp(const TatilBulucuApp());
}

class TatilBulucuApp extends StatelessWidget {
  const TatilBulucuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tatil Bulucu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    AuthService.initGuestState().then((_) {
      if (mounted) setState(() => _initialized = true);
    });
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
  if (!_initialized) {
    return const Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );
  }

  final session = Supabase.instance.client.auth.currentSession;
  final isGuest = AuthService.isGuest;

  if (session != null || isGuest) {
    return const MainScreen();
  }
  return const LoginScreen();
}
}