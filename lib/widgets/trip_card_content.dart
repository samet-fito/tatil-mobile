import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/stored_booking_model.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/price_format.dart';
import 'destination_hero_image.dart';
import 'hotel_experience_sheet.dart';

/// Tek ekranda uçuş + otel + rezervasyon özeti — offline cihazda saklanır.
class TripCardContent extends StatelessWidget {
  const TripCardContent({super.key, required this.booking});

  final StoredBooking booking;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _openMaps() async {
    final lat = booking.hotelLatitude;
    final lng = booking.hotelLongitude;
    final query = lat != null && lng != null
        ? '$lat,$lng'
        : Uri.encodeComponent('${booking.hotelName}, ${booking.cityName}');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _standaloneDateLabel() {
    if (booking.isCarRental && booking.returnDate.isAfter(booking.departureDate)) {
      return 'Alış ${_fmtDate(booking.departureDate)} · Teslim ${_fmtDate(booking.returnDate)}';
    }
    return _fmtDate(booking.departureDate);
  }

  @override
  Widget build(BuildContext context) {
    if (booking.isStandaloneProduct) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _standaloneProductCard(),
          _summaryCard(standaloneMode: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _summaryCard(),
        if (booking.hasHotel) ...[
          const SizedBox(height: 12),
          _hotelCard(context),
        ],
      ],
    );
  }

  Widget _summaryCard({bool standaloneMode = false}) {
    return _card(
      child: Column(
        children: [
          _kv('Rezervasyon', booking.reservationId),
          _kv('Yolcu', booking.passengerName),
          if (booking.passengerEmail.isNotEmpty)
            _kv('E-posta', booking.passengerEmail),
          if (standaloneMode)
            _kv(
              booking.isCarRental ? 'Tarih' : 'Tarih',
              _standaloneDateLabel(),
            )
          else
            _kv(
              'Tarih',
              '${_fmtDate(booking.departureDate)} – ${_fmtDate(booking.returnDate)}',
            ),
          _kv(
            standaloneMode ? 'Katılımcı' : 'Misafir',
            '${booking.adults} yetişkin'
            '${booking.children > 0 ? ', ${booking.children} çocuk' : ''}',
          ),
          if (standaloneMode && booking.totalPriceTL > 0)
            _kv('Ödenen tutar', PriceFormat.format(booking.totalPriceTL)),
        ],
      ),
    );
  }

  Widget _standaloneProductCard() {
    final category = booking.productSearchCategory;
    final icon = category?.icon ?? CupertinoIcons.ticket_fill;
    final color = booking.isActivity
        ? AppTheme.orange
        : (booking.isBus || booking.isTransfer || booking.isCarRental)
            ? AppTheme.orange
            : AppTheme.teal;

    return _card(
      icon: icon,
      iconColor: color,
      title: booking.categoryLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.listTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (booking.cityName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              booking.cityName.trim(),
              style: TatilTheme.hint.copyWith(fontSize: 12),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _standaloneDateLabel(),
            style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _hotelCard(BuildContext context) {
    final photo = booking.hotelPhotoUrl?.trim();
    final hasPhoto = photo != null && photo.startsWith('http');

    return _card(
      icon: CupertinoIcons.house_fill,
      iconColor: AppTheme.orange,
      title: 'Otel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: photo,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => DestinationHeroImage(
                    iataCode: booking.destinationIata,
                  ),
                  errorWidget: (_, __, ___) => DestinationHeroImage(
                    iataCode: booking.destinationIata,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            booking.hotelName!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.cityName} · ${booking.nights} gece',
            style: TatilTheme.hint.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Check-in ${_fmtDate(booking.departureDate)} · Check-out ${_fmtDate(booking.returnDate)}',
            style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.35),
          ),
          if (booking.hotelPriceTL > 0) ...[
            const SizedBox(height: 8),
            Text(
              PriceFormat.format(booking.hotelPriceTL),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${booking.nights} gece konaklama toplamı',
              style: TatilTheme.hint.copyWith(fontSize: 11),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GestureDetector(
              onTap: () => showHotelExperienceSheet(
                context,
                hotel: booking.hotelMap(),
                cityName: booking.cityName,
                destinationIata: booking.destinationIata,
                checkIn: booking.departureDate,
                checkOut: booking.returnDate,
                nights: booking.nights,
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.photo, size: 14, color: AppTheme.teal),
                  SizedBox(width: 6),
                  Text(
                    'Otel detayı ve harita',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (booking.hotelLatitude != null && booking.hotelLongitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: _openMaps,
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.map, size: 14, color: AppTheme.teal),
                    SizedBox(width: 6),
                    Text(
                      'Haritada aç',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({
    required Widget child,
    IconData? icon,
    Color? iconColor,
    String? title,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && icon != null) ...[
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TatilTheme.sectionLabel.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TatilTheme.hint.copyWith(fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seyahat kartında toplam ödenen tutarı gösterir.
class TripTotalPaidCard extends StatelessWidget {
  const TripTotalPaidCard({super.key, required this.booking});

  final StoredBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Toplam ödenen',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            PriceFormat.format(booking.totalPriceTL),
            style: TatilTheme.priceDisplay(color: AppTheme.orange, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
