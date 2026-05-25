import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/guest_info_screen.dart';

class CheckoutAuthSheet extends StatefulWidget {
  final String cityName;
  final int totalPrice;
  final VoidCallback onSuccess;

  const CheckoutAuthSheet({
    super.key,
    required this.cityName,
    required this.totalPrice,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String cityName,
    required int totalPrice,
    required VoidCallback onSuccess,
  }) async {
    final status = AuthService.checkoutAuthCheck();

    if (status == AuthStatus.loggedIn) {
      onSuccess();
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CheckoutAuthSheet(
        cityName: cityName,
        totalPrice: totalPrice,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<CheckoutAuthSheet> createState() => _CheckoutAuthSheetState();
}

class _CheckoutAuthSheetState extends State<CheckoutAuthSheet> {
  bool _isLoading = false;

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final success = await AuthService.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    }
  }

  Future<void> _signInWithApple() async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('🍎 Apple girişi yakında aktif olacak!'),
      backgroundColor: Colors.black,
      duration: Duration(seconds: 2),
    ),
  );
}

  void _continueWithoutLogin() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestInfoScreen(
          cityName: widget.cityName,
          totalPrice: widget.totalPrice,
          onComplete: widget.onSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Başlık
          const Text(
            '✈️ Neredeyse Hazırsın!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.cityName} · ${_formatPrice(widget.totalPrice)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Giriş avantajları
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _benefitRow('📋', 'Rezervasyonların otomatik kaydedilir'),
                const SizedBox(height: 8),
                _benefitRow('🔔', 'Fiyat düşünce bildirim alırsın'),
                const SizedBox(height: 8),
                _benefitRow('⭐', 'Favori rotalarını takip edebilirsin'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Google butonu
          _socialButton(
            onTap: _isLoading ? null : _signInWithGoogle,
            icon: '🔵',
            label: 'Google ile Hemen Giriş Yap',
            bgColor: AppTheme.primary,
            textColor: Colors.white,
          ),
          const SizedBox(height: 10),

          // Apple butonu
          _socialButton(
            onTap: _isLoading ? null : _signInWithApple,
            icon: '🍎',
            label: 'Apple ile Hemen Giriş Yap',
            bgColor: Colors.black,
            textColor: Colors.white,
          ),
          const SizedBox(height: 16),

          // Ayırıcı
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'veya',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          // Giriş yapmadan devam
          GestureDetector(
            onTap: _continueWithoutLogin,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withOpacity(0.08),
                ),
              ),
              child: const Center(
                child: Text(
                  '👤 Giriş Yapmadan Devam Et',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required VoidCallback? onTap,
    required String icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}