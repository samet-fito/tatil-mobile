import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/support_config.dart';
import '../screens/support_chat_screen.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../theme/custom_page_route.dart';

/// Yardım ve destek — canlı chat, WhatsApp, SSS.
Future<void> showHelpSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TatilTheme.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Yardım & Destek',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _SupportCta(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    title: 'Canlı destek chat',
                    subtitle: 'Anında yanıt · ${SupportConfig.supportHours}',
                    color: AppTheme.teal,
                    onTap: () {
                      Navigator.pop(ctx);
                      pushAppRoute(ctx, const SupportChatScreen());
                    },
                  ),
                  const SizedBox(height: 10),
                  _SupportCta(
                    icon: CupertinoIcons.phone_fill,
                    title: 'WhatsApp destek',
                    subtitle: 'Temsilci ile yazışın',
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      final uri = Uri.parse(SupportConfig.whatsAppUrl());
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _SupportCta(
                    icon: CupertinoIcons.mail_solid,
                    title: SupportConfig.supportEmail,
                    subtitle: 'E-posta ile ulaşın',
                    color: AppTheme.orange,
                    onTap: () async {
                      final uri = Uri.parse(SupportConfig.mailtoUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sık sorulan sorular',
                    style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const _FaqTile(
                    q: 'Rezervasyonlarım nerede?',
                    a: 'Profil → Rezervasyonlarım bölümünden tamamladığınız '
                        'önizleme taleplerini görebilirsiniz.',
                  ),
                  const _FaqTile(
                    q: 'Fiyatlar kesin mi?',
                    a: 'Listelenen fiyatlar bilgilendirme amaçlıdır. Ödeme '
                        'entegrasyonu sonrası kesin tutar onay adımında '
                        'doğrulanacaktır.',
                  ),
                  const _FaqTile(
                    q: 'Ödeme ne zaman aktif olacak?',
                    a: 'Uygulama şu an önizleme modundadır. Tüm adımları '
                        'deneyebilirsiniz; gerçek ödeme yakında eklenecek.',
                  ),
                  const _FaqTile(
                    q: 'İptal nasıl yapılır?',
                    a: 'Rezervasyon detayından "İptal veya değişiklik talebi" '
                        'ile self-servis talep oluşturabilirsiniz.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SupportCta extends StatelessWidget {
  const _SupportCta({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TatilTheme.hint.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.q, required this.a});

  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            a,
            style: TatilTheme.hint.copyWith(height: 1.45, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
