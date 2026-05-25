import 'package:flutter/material.dart';
import '../models/route_result_model.dart';
import '../theme/app_theme.dart';

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
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} TL';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: route.isBestChoice
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildBody(),
            if (route.alternativeSuggestion != null) _buildSuggestion(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: route.isAffordable
              ? [AppTheme.primary, const Color(0xFF1D3461)]
              : [const Color(0xFF92400E), const Color(0xFF78350F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (route.isBestChoice)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      '🥇 En İyi Seçim',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                Text(
                  route.cityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${route.country} · ${route.nights} gece',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  route.score.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'PUAN',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              if (route.flight != null)
                Expanded(
                  child: _infoChip(
                    icon: Icons.flight_takeoff,
                    label: route.flight!.airline,
                    sub: route.flight!.duration,
                  ),
                ),
              const SizedBox(width: 8),
              if (route.hotel != null)
                Expanded(
                  child: _infoChip(
                    icon: Icons.hotel,
                    label: '${route.hotel!.reviewScore}/10 ⭐',
                    sub: route.hotel!.name.split(' ').take(2).join(' '),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _budgetBar('✈ Uçuş', route.budgetBreakdown.flightPercentage, route.estimatedCost.flight, AppTheme.accent),
          const SizedBox(height: 6),
          _budgetBar('🏨 Otel', route.budgetBreakdown.hotelPercentage, route.estimatedCost.hotel, const Color(0xFFD85A30)),
          const SizedBox(height: 6),
          _budgetBar('🚗 Transfer', route.budgetBreakdown.transferPercentage, route.estimatedCost.transfer, const Color(0xFF0EA5E9)),
          const SizedBox(height: 6),
          _budgetBar('💰 Harçlık', route.budgetBreakdown.pocketPercentage, route.estimatedCost.pocketMoney, const Color(0xFF6366F1)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tahmini Toplam',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Text(
                    _fmt(route.estimatedCost.total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: route.isAffordable ? AppTheme.accent : Colors.red,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (route.isAffordable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '+${_fmt(route.estimatedCost.remaining)} kalan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: route.isAffordable ? AppTheme.accent : const Color(0xFF92400E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'İncele →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  Widget _buildSuggestion() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFF0C97A))),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              route.alternativeSuggestion!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF854F0B),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.accent),
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
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetBar(String label, int percentage, int amount, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 82,
          child: Text(
            _fmt(amount),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}