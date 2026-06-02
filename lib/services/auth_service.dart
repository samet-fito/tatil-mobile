import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;
  static bool _isGuest = false;

  static bool get isGuest => _isGuest;
  static bool get isLoggedIn => _supabase.auth.currentSession != null;
  static User? get currentUser => _supabase.auth.currentUser;

  // ============================================================
  // GOOGLE İLE GİRİŞ
  // ============================================================
static Future<bool> signInWithGoogle() async {
  try {
    final existing = _supabase.auth.currentSession;
    if (existing != null) {
      _isGuest = false;
      return true;
    }

    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.tatilbulucu://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
    return true;
  } catch (e) {
    return false;
  }
}

  // ============================================================
  // APPLE İLE GİRİŞ
  // ============================================================
  static Future<bool> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.tatilbulucu://login-callback',
        authScreenLaunchMode: LaunchMode.inAppWebView,
      );
      _isGuest = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // MİSAFİR GİRİŞİ
  // ============================================================
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

  // ============================================================
  // ÇIKIŞ
  // ============================================================
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

  // ============================================================
  // ÖDEME ÖNCESİ KONTROL
  // ============================================================
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