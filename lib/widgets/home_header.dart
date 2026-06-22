import 'package:flutter/material.dart';
import '../theme/tatil_theme.dart';
import 'login_background_pattern.dart';

/// Ana sayfa üst bölüm — turuncu başlık, taşma yok.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    const contentHeight = 68.0;

    return SizedBox(
      height: topInset + contentHeight,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const LoginBackgroundPattern(),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topInset + 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TatilTheme.title.copyWith(fontSize: 24),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TatilTheme.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
