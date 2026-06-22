import 'package:flutter/material.dart';

/// Google ve Facebook — yalnızca ikon, kompakt satır.
class SocialIconButtons extends StatelessWidget {
  const SocialIconButtons({
    super.key,
    required this.onGoogle,
    required this.onFacebook,
    this.loading = false,
    this.iconSize = 64,
    this.spacing = 24,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onFacebook;
  final bool loading;
  final double iconSize;
  final double spacing;

  static const _googleLogoAsset = 'assets/icons/google_logo.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SocialIconButton(
          size: iconSize,
          onTap: loading ? null : onGoogle,
          backgroundColor: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          shadowColor: Colors.black.withValues(alpha: 0.1),
          semanticsLabel: 'Google ile giriş yap',
          child: Image.asset(
            _googleLogoAsset,
            width: iconSize * 0.52,
            height: iconSize * 0.52,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: spacing),
        _SocialIconButton(
          size: iconSize,
          onTap: loading ? null : onFacebook,
          backgroundColor: const Color(0xFF1877F2),
          shadowColor: const Color(0xFF1877F2).withValues(alpha: 0.35),
          semanticsLabel: 'Facebook ile giriş yap',
          child: Icon(
            Icons.facebook,
            color: Colors.white,
            size: iconSize * 0.52,
          ),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.size,
    required this.onTap,
    required this.backgroundColor,
    required this.child,
    required this.semanticsLabel,
    this.border,
    this.shadowColor,
  });

  final double size;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Widget child;
  final String semanticsLabel;
  final Border? border;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: radius,
              border: border,
              boxShadow: shadowColor != null
                  ? [
                      BoxShadow(
                        color: shadowColor!,
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
