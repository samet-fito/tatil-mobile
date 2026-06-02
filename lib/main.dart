import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

await Supabase.initialize(
  url: AppConstants.supabaseUrl,
  anonKey: AppConstants.supabaseAnonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.implicit,
    autoRefreshToken: true,
  ),
);

  runApp(const TatilBulucuApp());
}

class TatilBulucuApp extends StatelessWidget {
  const TatilBulucuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizegoo',
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
  _init();
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (mounted) {
      final session = data.session;
      if (session != null) {
        AuthService.clearGuest();
      }
      setState(() {});
    }
  });
}

  Future<void> _init() async {
    await AuthService.initGuestState();
    if (mounted) setState(() => _initialized = true);
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