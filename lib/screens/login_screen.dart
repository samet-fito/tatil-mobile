import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'search_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final success = await AuthService.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş başarısız. Tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signInWithApple() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple girişi yakında aktif olacak.'),
        backgroundColor: Colors.black,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    await AuthService.continueAsGuest();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Başlık
              const Text(
                'Tatil Bulucu',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Açıklama
              const Text(
                'Bütçeni gir, sana en uygun\nuçuş, otel ve transfer\npaketini saniyeler içinde bul.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const Spacer(flex: 1),

              // Özellik listesi
              _featureLine('Yapay zeka destekli rota motoru'),
              const SizedBox(height: 10),
              _featureLine('Yerel partner otel ve transfer ağı'),
              const SizedBox(height: 10),
              _featureLine('Gerçek zamanlı bütçe optimizasyonu'),

              const Spacer(flex: 2),

              // Google butonu
              _buildButton(
                label: 'Google ile Devam Et',
                bgColor: Colors.white,
                textColor: const Color(0xFF1F1F1F),
                onTap: _isLoading ? null : _signInWithGoogle,
              ),
              const SizedBox(height: 12),

              // Apple butonu
              _buildButton(
                label: 'Apple ile Devam Et',
                bgColor: Colors.black,
                textColor: Colors.white,
                border: Border.all(color: AppTheme.border),
                onTap: _isLoading ? null : _signInWithApple,
              ),
              const SizedBox(height: 20),

              // Ayırıcı
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'veya',
                      style: TextStyle(
                        color: AppTheme.textMuted.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.border)),
                ],
              ),
              const SizedBox(height: 20),

              // Misafir butonu
              _buildButton(
                label: 'Misafir Olarak Devam Et',
                bgColor: Colors.transparent,
                textColor: AppTheme.textSecondary,
                border: Border.all(color: AppTheme.border),
                onTap: _isLoading ? null : _continueAsGuest,
              ),

              const SizedBox(height: 24),

              // Alt not
              Center(
                child: Text(
                  'Devam ederek Gizlilik Politikasını kabul etmiş olursunuz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureLine(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required Color bgColor,
    required Color textColor,
    Border? border,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Center(
          child: _isLoading && bgColor == Colors.white
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1F1F1F),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}