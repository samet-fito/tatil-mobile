import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/explore_promotions.dart';
import '../models/search_category.dart';
import '../theme/tatil_theme.dart';

/// Keşfet alt vitrin — kampanyalar + bölgesel popüler rota fırsatları.
class ExploreDiscoveryStrip extends StatelessWidget {
  const ExploreDiscoveryStrip({
    super.key,
    required this.category,
    required this.originIata,
    required this.originCity,
    required this.onCampaignTap,
    required this.onRegionalDealTap,
  });

  final SearchCategory category;
  final String originIata;
  final String originCity;
  final void Function(ExploreCampaign campaign) onCampaignTap;
  final void Function(ExploreRegionalDeal deal) onRegionalDealTap;

  @override
  Widget build(BuildContext context) {
    final campaigns = ExplorePromotions.campaignsFor(category);
    final deals = ExplorePromotions.regionalDealsFor(
      originIata: originIata,
      category: category,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Row(
            children: [
              Text(
                'Fırsatlar',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: TatilTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                'Kupon kodlarıyla',
                style: TatilTheme.hint.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            clipBehavior: Clip.none,
            itemCount: campaigns.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = campaigns[i];
              return _CampaignCard(
                campaign: c,
                onTap: () => onCampaignTap(c),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                '$originCity · ${category.label} fırsatları',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: TatilTheme.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: TatilTheme.orangeSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Güncel',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: TatilTheme.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bu bölgeden en çok aranan ${category.label.toLowerCase()} rotaları',
          style: TatilTheme.hint.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            clipBehavior: Clip.none,
            itemCount: deals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              return _RegionalDealCard(
                deal: deals[i],
                onTap: () => onRegionalDealTap(deals[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RegionalDealCard extends StatelessWidget {
  const _RegionalDealCard({required this.deal, required this.onTap});

  final ExploreRegionalDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgent = deal.isUrgent;
    final bgTop = urgent ? const Color(0xFF1E293B) : Colors.white;
    final bgBottom = urgent ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    final textColor = urgent ? Colors.white : TatilTheme.textDark;
    final mutedColor =
        urgent ? Colors.white.withValues(alpha: 0.72) : TatilTheme.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: urgent
              ? LinearGradient(
                  colors: [bgTop, bgBottom],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: urgent ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: urgent
                ? Colors.transparent
                : TatilTheme.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: urgent ? 0.14 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  deal.route.category.icon,
                  size: 14,
                  color: urgent ? Colors.white : TatilTheme.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    deal.route.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                if (deal.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: urgent
                          ? TatilTheme.orange.withValues(alpha: 0.9)
                          : TatilTheme.orangeSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      deal.badge!,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: urgent ? Colors.white : TatilTheme.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              deal.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: mutedColor),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  deal.priceLabel,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TatilTheme.orange,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TatilTheme.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ara',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (deal.hoursLeft != null) ...[
              const SizedBox(height: 4),
              Text(
                '${deal.hoursLeft} saat içinde',
                style: TextStyle(
                  fontSize: 10,
                  color: mutedColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.onTap});

  final ExploreCampaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(campaign.accentColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.14),
              TatilTheme.bgSoft,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    campaign.discountLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${campaign.daysLeft} gün',
                  style: TatilTheme.hint.copyWith(fontSize: 10),
                ),
              ],
            ),
            const Spacer(),
            Text(
              campaign.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: TatilTheme.textDark,
              ),
            ),
            Text(
              '${campaign.subtitle} · ${campaign.code}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TatilTheme.hint.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
