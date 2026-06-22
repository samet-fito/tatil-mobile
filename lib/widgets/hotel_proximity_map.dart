import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/destination_geo.dart';
import '../data/destination_landmarks.dart';
import '../theme/app_theme.dart';
import '../utils/selection_detail_resolver.dart';

/// Şematik mesafe haritası — otel + meşhur noktalar.
class HotelProximityMap extends StatelessWidget {
  const HotelProximityMap({
    super.key,
    required this.hotelLat,
    required this.hotelLng,
    required this.destinationIata,
    this.hotelLabel = 'Otel',
  });

  final double hotelLat;
  final double hotelLng;
  final String destinationIata;
  final String hotelLabel;

  @override
  Widget build(BuildContext context) {
    final geo = DestinationGeo.forIata(destinationIata);
    final landmarks = DestinationLandmarks.forIata(destinationIata);

    final points = <_MapPoint>[
      _MapPoint(
        lat: hotelLat,
        lng: hotelLng,
        label: hotelLabel,
        emoji: '🏨',
        isHotel: true,
      ),
      ...landmarks.map(
        (l) => _MapPoint(
          lat: l.lat,
          lng: l.lng,
          label: l.name,
          emoji: l.emoji,
        ),
      ),
      if (geo != null)
        _MapPoint(
          lat: geo.airport.lat,
          lng: geo.airport.lng,
          label: 'Havalimanı',
          emoji: '✈️',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.35,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: _ProximityMapPainter(
                hotelLat: hotelLat,
                hotelLng: hotelLng,
                points: points,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...points.where((p) => !p.isHotel).map((p) {
          final km = SelectionDetailResolver.haversineKm(
            lat1: hotelLat,
            lng1: hotelLng,
            lat2: p.lat,
            lng2: p.lng,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${km.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.orange,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MapPoint {
  const _MapPoint({
    required this.lat,
    required this.lng,
    required this.label,
    required this.emoji,
    this.isHotel = false,
  });

  final double lat;
  final double lng;
  final String label;
  final String emoji;
  final bool isHotel;
}

class _ProximityMapPainter extends CustomPainter {
  _ProximityMapPainter({
    required this.hotelLat,
    required this.hotelLng,
    required this.points,
  });

  final double hotelLat;
  final double hotelLng;
  final List<_MapPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F4F8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      bg,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFB8D4E3).withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      final y = size.height * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final lats = points.map((p) => p.lat);
    final lngs = points.map((p) => p.lng);
    var minLat = lats.reduce(math.min) - 0.02;
    var maxLat = lats.reduce(math.max) + 0.02;
    var minLng = lngs.reduce(math.min) - 0.02;
    var maxLng = lngs.reduce(math.max) + 0.02;

    Offset toOffset(double lat, double lng) {
      final x = (lng - minLng) / (maxLng - minLng);
      final y = 1 - (lat - minLat) / (maxLat - minLat);
      return Offset(
        16 + x * (size.width - 32),
        16 + y * (size.height - 32),
      );
    }

    final hotelPos = toOffset(hotelLat, hotelLng);

    for (final p in points) {
      if (p.isHotel) continue;
      final pos = toOffset(p.lat, p.lng);
      final linePaint = Paint()
        ..color = AppTheme.orange.withValues(alpha: 0.25)
        ..strokeWidth = 1.5;
      canvas.drawLine(hotelPos, pos, linePaint);
    }

    for (final p in points) {
      final pos = toOffset(p.lat, p.lng);
      final radius = p.isHotel ? 10.0 : 7.0;
      final dotPaint = Paint()
        ..color = p.isHotel ? AppTheme.orange : AppTheme.teal;
      canvas.drawCircle(pos, radius, dotPaint);
      final border = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pos, radius, border);
    }
  }

  @override
  bool shouldRepaint(covariant _ProximityMapPainter oldDelegate) => false;
}
