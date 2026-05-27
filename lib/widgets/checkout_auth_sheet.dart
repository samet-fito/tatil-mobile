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
        content: Text('Apple girişi yakında aktif olacak.'),
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
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        32, 24, 32,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Başlık
          const Text(
            'Devam etmek için\ngiriş yapın',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.cityName}  ·  ${_formatPrice(widget.totalPrice)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 28),

          // Avantajlar
          _benefit('Rezervasyonlarınız otomatik kaydedilir'),
          const SizedBox(height: 8),
          _benefit('Fiyat değişikliklerinde bildirim alırsınız'),
          const SizedBox(height: 8),
          _benefit('Geçmiş aramalarınıza erişebilirsiniz'),

          const SizedBox(height: 28),

          // Google butonu
          _buildButton(
            label: 'Google ile Giriş Yap',
            bgColor: Colors.white,
            textColor: const Color(0xFF1F1F1F),
            onTap: _isLoading ? null : _signInWithGoogle,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),

          // Apple butonu
          _buildButton(
            label: 'Apple ile Giriş Yap',
            bgColor: Colors.black,
            textColor: Colors.white,
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

          // Giriş yapmadan devam
          _buildButton(
            label: 'Giriş Yapmadan Devam Et',
            bgColor: Colors.transparent,
            textColor: AppTheme.textSecondary,
            border: Border.all(color: AppTheme.border),
            onTap: _continueWithoutLogin,
          ),
        ],
      ),
    );
  }

  Widget _benefit(String text) {
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
    bool isLoading = false,
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
          child: isLoading
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