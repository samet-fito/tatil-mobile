import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import 'destination_hero_image.dart';

/// Boş / hata durumları — before.click: sakin, destinasyon görselli.
class TravelStateView extends StatelessWidget {
  const TravelStateView({
    super.key,
    this.iataCode,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.icon,
  });

  final String? iataCode;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iataCode != null && iataCode!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DestinationHeroImage(iataCode: iataCode!),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                        if (icon != null)
                          Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: AppTheme.orange, size: 26),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else if (icon != null)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.orangeSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.orange.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: AppTheme.orange, size: 30),
                ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TatilTheme.screenHeadline(fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TatilTheme.bodyMuted.copyWith(height: 1.45),
              ),
              if (primaryLabel != null && onPrimary != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    child: Text(primaryLabel!),
                  ),
                ),
              ],
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onSecondary,
                  child: Text(
                    secondaryLabel!,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
