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

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
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
  @override
  void initState() {
  super.initState();
  AuthService.initGuestState().then((_) {
    if (mounted) setState(() {});
  });
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (mounted) setState(() {});
  });
}

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const SearchScreen();
    }
    return const LoginScreen();
  }
}