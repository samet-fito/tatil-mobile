import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'travel_booking_service.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;
  static bool _isGuest = false;

  static const oauthRedirectUrl = 'io.supabase.tatilbulucu://login-callback';

  static bool get isGuest => _isGuest;
  static bool get isLoggedIn => _supabase.auth.currentSession != null;
  static User? get currentUser => _supabase.auth.currentUser;
  static String? get userId => currentUser?.id ?? (isGuest ? 'guest' : null);
  static String? get displayName =>
      currentUser?.userMetadata?['full_name'] as String? ??
      currentUser?.email?.split('@')[0];
  static String? get userEmail => currentUser?.email;

  static Future<void> _clearGuestFlag() async {
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
  }

  static Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.session != null) {
      await _clearGuestFlag();
      await TravelBookingService.syncLocalBookingsToCloud();
      return true;
    }
    return false;
  }

  static Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
    if (response.session != null) {
      await _clearGuestFlag();
      await TravelBookingService.syncLocalBookingsToCloud();
      return true;
    }
    // E-posta doğrulama açıksa session null olabilir
    return response.user != null;
  }

  static Future<bool> _signInWithOAuthProvider(OAuthProvider provider) async {
    if (_supabase.auth.currentSession != null) {
      await _clearGuestFlag();
      return true;
    }

    StreamSubscription<AuthState>? sub;
    try {
      final completer = Completer<bool>();

      sub = _supabase.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn &&
            data.session != null &&
            !completer.isCompleted) {
          completer.complete(true);
        }
      });

      await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: oauthRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      final signedIn = await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () => _supabase.auth.currentSession != null,
      );

      if (signedIn) {
        await _clearGuestFlag();
        await TravelBookingService.syncLocalBookingsToCloud();
      }
      return signedIn;
    } catch (e) {
      if (_supabase.auth.currentSession != null) {
        await _clearGuestFlag();
        await TravelBookingService.syncLocalBookingsToCloud();
        return true;
      }
      rethrow;
    } finally {
      await sub?.cancel();
    }
  }

  static Future<bool> signInWithGoogle() =>
      _signInWithOAuthProvider(OAuthProvider.google);

  static Future<bool> signInWithFacebook() =>
      _signInWithOAuthProvider(OAuthProvider.facebook);

  static Future<void> continueAsGuest() async {
    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);
    await prefs.setString(
      'guest_session_id',
      'guest_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static Future<String> getSessionId() async {
    if (isLoggedIn) return currentUser!.id;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('guest_session_id') ??
        'guest_${DateTime.now().millisecondsSinceEpoch}';
  }

  static void clearGuest() {
    _isGuest = false;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('is_guest');
    });
  }

  static Future<void> signOut() async {
    try {
      _isGuest = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_guest');
      await prefs.remove('guest_session_id');
      await _supabase.auth.signOut();
    } catch (e) {
      // ignore
    }
  }

  static AuthStatus checkoutAuthCheck() {
    if (isLoggedIn) return AuthStatus.loggedIn;
    if (_isGuest) return AuthStatus.guest;
    return AuthStatus.notLoggedIn;
  }

  static Future<void> initGuestState() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('is_guest') ?? false;
  }
}

enum AuthStatus { loggedIn, guest, notLoggedIn }
