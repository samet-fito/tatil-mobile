import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/route_result_model.dart';
import '../theme/app_theme.dart';
import '../utils/price_format.dart';

/// Havalimanı → otel ulaşımı — rota API verisinden.
class AirportTransferCard extends StatelessWidget {
  const AirportTransferCard({
    super.key,
    required this.iata,
    required this.cityName,
    this.hotelName,
    this.routeTransfer,
  });

  final String iata;
  final String cityName;
  final String? hotelName;
  final RouteTransferModel? routeTransfer;

  @override
  Widget build(BuildContext context) {
    if (routeTransfer == null) {
      return const SizedBox.shrink();
    }

    final t = routeTransfer!;
    final to = hotelName ?? t.routeTo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.car_detailed, color: AppTheme.orange, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Havalimanından Otele Ulaşım',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$iata → $to',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Icon(
                  t.vehicleType == 'van' ? CupertinoIcons.bus : CupertinoIcons.car,
                  color: AppTheme.orange,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.companyName ?? 'Transfer',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${t.routeFrom} → ${t.routeTo}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      if (t.durationMinutes != null)
                        Text(
                          '~${t.durationMinutes} dk · ${t.capacity} kişi',
                          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                ),
                Text(
                  PriceFormat.format(t.priceFixed.round()),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
