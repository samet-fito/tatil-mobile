import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// GetYourGuide tarzı güven veren alt bilgi — mağaza, menüler, ödeme logoları.
class VizegooTrustFooter extends StatelessWidget {
  const VizegooTrustFooter({super.key, this.compact = false});

  final bool compact;

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.vizegoo.app';
  static const _appStoreUrl = 'https://apps.apple.com/app/vizegoo';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.fromLTRB(20, compact ? 20 : 28, 20, compact ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) ...[
            Text(
              'Vizegoo uygulamasını indirin',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StoreButton(
                  label: 'Google Play',
                  icon: Icons.android,
                  onTap: () => _open(_playStoreUrl),
                )),
                const SizedBox(width: 10),
                Expanded(child: _StoreButton(
                  label: 'App Store',
                  icon: Icons.apple,
                  onTap: () => _open(_appStoreUrl),
                )),
              ],
            ),
            const SizedBox(height: 24),
          ],
          _FooterExpansion(
            title: 'Destek',
            items: const [
              'Yardım Merkezi',
              'İletişim',
              'İptal ve iade politikası',
              'Sık sorulan sorular',
            ],
          ),
          _FooterExpansion(
            title: 'Şirket',
            items: const [
              'Hakkımızda',
              'Kariyer',
              'Basın',
              'Blog',
            ],
          ),
          _FooterExpansion(
            title: 'Bizimle çalışın',
            items: const [
              'Tedarikçi olarak katılın',
              'Satış ortağı programı',
              'Acente çözümleri',
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Güvenli ödeme yöntemleri',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _PaymentBadge(label: 'VISA', colors: [Color(0xFF1A1F71), Color(0xFF253B80)]),
              _PaymentBadge(label: 'MC', colors: [Color(0xFFEB001B), Color(0xFFF79E1B)]),
              _PaymentBadge(label: 'Troy', colors: [Color(0xFF00A651), Color(0xFF008C45)]),
              _PaymentBadge(label: 'AMEX', colors: [Color(0xFF006FCF), Color(0xFF002663)]),
              _PaymentBadge(label: '3D', colors: [Color(0xFF7C3AED), Color(0xFFD946EF)]),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '© ${DateTime.now().year} Vizegoo · Tüm hakları saklıdır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppTheme.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterExpansion extends StatelessWidget {
  const _FooterExpansion({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: Colors.white70,
        iconColor: AppTheme.orange,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        children: items
            .map(
              (item) => Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.label, required this.colors});

  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
