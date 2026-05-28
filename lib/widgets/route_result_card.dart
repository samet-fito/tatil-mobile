import '../screens/route_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/route_result_model.dart';
import '../theme/app_theme.dart';
import '../city_images.dart';

class RouteResultCard extends StatelessWidget {
  final RouteResultModel route;
  final int rank;
  final VoidCallback onTap;

  const RouteResultCard({
    super.key,
    required this.route,
    required this.rank,
    required this.onTap,
  });

  String _fmt(int price) {
    return '${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )} TL';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: route.isBestChoice
              ? Border.all(color: AppTheme.accent.withOpacity(0.5), width: 1.5)
              : Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(
          children: [
            _buildHeroImage(),
            _buildBody(),
            if (route.alternativeSuggestion != null) _buildSuggestion(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO GÖRSEL
  // ============================================================
  Widget _buildHeroImage() {
    final imageUrl = CityImages.getImage(route.destinationIata);
    final landmark = CityImages.getLandmark(route.destinationIata);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Şehir görseli
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Shimmer.fromColors(
                baseColor: AppTheme.bgSecondary,
                highlightColor: AppTheme.bgTertiary,
                child: Container(color: AppTheme.bgSecondary),
              ),
              errorWidget: (ctx, url, err) => Container(
                color: AppTheme.bgTertiary,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: AppTheme.textMuted, size: 32),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.bgPrimary.withOpacity(0.3),
                    AppTheme.bgPrimary.withOpacity(0.85),
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),

            // En iyi seçim rozeti
            if (route.isBestChoice)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'En İyi Seçim',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

            // Skor
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgPrimary.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  '${route.score.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Şehir adı ve landmark
            Positioned(
              left: 16,
              bottom: 14,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.cityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (landmark.isNotEmpty)
                    Text(
                      landmark,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // KART GÖVDE
  // ============================================================
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Uçuş & Otel bilgisi
          Row(
            children: [
              if (route.flight != null)
                Expanded(
                  child: _infoTile(
                    icon: CupertinoIcons.airplane,
                    label: route.flight!.airline,
                    sub: route.flight!.duration,
                  ),
                ),
              if (route.flight != null && route.hotel != null)
                const SizedBox(width: 10),
              if (route.hotel != null)
                Expanded(
                  child: _infoTile(
                    icon: CupertinoIcons.house,
                    label: '${route.hotel!.reviewScore}/10',
                    sub: route.hotel!.name.split(' ').take(2).join(' '),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Bütçe barları
          _budgetBar(
            icon: CupertinoIcons.airplane,
            label: 'Uçuş',
            percentage: route.budgetBreakdown.flightPercentage,
            amount: route.estimatedCost.flight,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 8),
          _budgetBar(
            icon: CupertinoIcons.house,
            label: 'Otel',
            percentage: route.budgetBreakdown.hotelPercentage,
            amount: route.estimatedCost.hotel,
            color: AppTheme.teal,
          ),
          const SizedBox(height: 8),
          _budgetBar(
            icon: CupertinoIcons.car_detailed,
            label: 'Transfer',
            percentage: route.budgetBreakdown.transferPercentage,
            amount: route.estimatedCost.transfer,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 8),
          _budgetBar(
            icon: CupertinoIcons.money_dollar_circle,
            label: 'Harçlık',
            percentage: route.budgetBreakdown.pocketPercentage,
            amount: route.estimatedCost.pocketMoney,
            color: const Color(0xFF6366F1),
          ),

          const SizedBox(height: 14),
          Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),

          // Toplam & buton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tahmini Toplam',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted),
   ),
                  const SizedBox(height: 2),
                  Text(
                    _fmt(route.estimatedCost.total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: route.isAffordable
                          ? AppTheme.textPrimary
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (route.isAffordable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '+${_fmt(route.estimatedCost.remaining)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.teal,
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: route.isAffordable
                            ? AppTheme.accent
                            : const Color(0xFF7F1D1D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'İncele',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }               

  // ============================================================
  // AKILLI ÖNERİ
  // ============================================================
  Widget _buildSuggestion() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F0E),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              route.alternativeSuggestion!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // YARDIMCI WİDGET'LAR
  // ============================================================
  Widget _infoTile({
    required IconData icon,
    required String label,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetBar(
      {required IconData icon,
      required String label,
      required int percentage,
      required int amount,
      required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            _fmt(amount),
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}