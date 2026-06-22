import 'main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/login_background_pattern.dart';
import '../widgets/social_icon_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// Yapay zeka ile üretilen logo/başlık görseli hazır olunca buraya ekle:
  /// `assets/images/login_title.png`
  static const String? titleAssetPath = null;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAuthSuccess() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (ctx) => const MainScreen()),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isRegisterMode) {
        final ok = await AuthService.signUpWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
        if (!mounted) return;
        if (ok && AuthService.isLoggedIn) {
          await _onAuthSuccess();
        } else {
          _showError(
            'Kayıt alındı. E-posta doğrulama açıksa gelen kutunuzu kontrol edin.',
          );
        }
      } else {
        final ok = await AuthService.signInWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
        if (!mounted) return;
        if (ok) {
          await _onAuthSuccess();
        } else {
          _showError('Giriş yapılamadı.');
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _oauth(Future<bool> Function() fn) async {
    setState(() => _isLoading = true);
    try {
      final ok = await fn();
      if (!mounted) return;
      if (ok) {
        await _onAuthSuccess();
      } else {
        _showError('Giriş tamamlanamadı.');
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await AuthService.continueAsGuest();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackgroundPattern(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildTitle(),
                  const SizedBox(height: 22),
                  _glassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isRegisterMode
                                ? 'E-posta ve şifre ile hesap oluştur'
                                : 'E-posta ve şifren ile devam et',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _input(
                            controller: _emailCtrl,
                            label: 'E-posta',
                            icon: CupertinoIcons.mail,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'E-posta gerekli';
                              }
                              if (!v.contains('@')) return 'Geçerli e-posta girin';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _input(
                            controller: _passwordCtrl,
                            label: 'Şifre',
                            icon: CupertinoIcons.lock,
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'Şifre en az 6 karakter olmalı';
                              }
                              return null;
                            },
                          ),
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 12),
                            _input(
                              controller: _confirmCtrl,
                              label: 'Şifre Tekrar',
                              icon: CupertinoIcons.lock,
                              obscure: true,
                              validator: (v) {
                                if (v != _passwordCtrl.text) {
                                  return 'Şifreler eşleşmiyor';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 20),
                          _primaryButton(
                            label: _isRegisterMode ? 'Hesap Oluştur' : 'Giriş Yap',
                            onTap: _isLoading ? null : _submitEmailAuth,
                            loading: _isLoading,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() {
                                            _isRegisterMode = !_isRegisterMode;
                                            _confirmCtrl.clear();
                                          }),
                                  child: Text(
                                    _isRegisterMode ? 'Giriş Yap' : 'Kayıt Ol',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF6600),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 20,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: _isLoading ? null : _continueAsGuest,
                                  child: Text(
                                    'Misafir Giriş',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _orDivider(),
                  const SizedBox(height: 20),
                  SocialIconButtons(
                    loading: _isLoading,
                    onGoogle: () => _oauth(AuthService.signInWithGoogle),
                    onFacebook: () => _oauth(AuthService.signInWithFacebook),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Devam ederek Gizlilik Politikasını kabul etmiş olursunuz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    if (LoginScreen.titleAssetPath != null) {
      return Image.asset(
        LoginScreen.titleAssetPath!,
        height: 56,
        fit: BoxFit.contain,
      );
    }

    return Column(
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF3E8)],
          ).createShader(bounds),
          child: Text(
            'Tatil Bulucu',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 38,
              fontWeight: FontWeight.w600,
              height: 1.05,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Text(
            'Keşfet · Planla · Yola Çık',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFFF6600)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6600), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return Material(
      color: const Color(0xFFFF6600),
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      shadowColor: const Color(0xFFFF6600).withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

}
