import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/travel_booking_service.dart';
import 'theme/app_theme.dart';
import 'utils/live_fx_rate.dart';
import 'constants.dart';
import 'widgets/app_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  await LiveFxRate.prefetchFromApi();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
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
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (mounted) {
        final session = data.session;
        if (session != null) {
          AuthService.clearGuest();
          await TravelBookingService.syncLocalBookingsToCloud();
        }
        setState(() {});
      }
    });
  }

  Future<void> _init() async {
    await AuthService.initGuestState();
    if (Supabase.instance.client.auth.currentSession != null) {
      await TravelBookingService.syncLocalBookingsToCloud();
    }
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const AppSplash();
    }

    final session = Supabase.instance.client.auth.currentSession;
    final isGuest = AuthService.isGuest;

    if (session != null || isGuest) {
      return const MainScreen();
    }
    return const LoginScreen();
  }
}