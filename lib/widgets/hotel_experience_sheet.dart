import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../city_images.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/hotel_location_hints.dart';
import '../utils/price_format.dart';
import '../utils/selection_detail_resolver.dart';
import 'destination_hero_image.dart';
import 'hotel_proximity_map.dart';

/// Otel görselleri + mesafe haritası — tam ekran alt sayfa.
Future<void> showHotelExperienceSheet(
  BuildContext context, {
  required Map<String, dynamic> hotel,
  required String cityName,
  required String destinationIata,
  required DateTime checkIn,
  required DateTime checkOut,
  required int nights,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.bgPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => _HotelExperienceSheetBody(
        hotel: hotel,
        cityName: cityName,
        destinationIata: destinationIata,
        checkIn: checkIn,
        checkOut: checkOut,
        nights: nights,
        scrollController: scrollController,
      ),
    ),
  );
}

class _HotelExperienceSheetBody extends StatefulWidget {
  const _HotelExperienceSheetBody({
    required this.hotel,
    required this.cityName,
    required this.destinationIata,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.scrollController,
  });

  final Map<String, dynamic> hotel;
  final String cityName;
  final String destinationIata;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final ScrollController scrollController;

  @override
  State<_HotelExperienceSheetBody> createState() =>
      _HotelExperienceSheetBodyState();
}

class _HotelExperienceSheetBodyState extends State<_HotelExperienceSheetBody> {
  int _photoIndex = 0;

  String _date(DateTime d) => '${d.day}.${d.month}.${d.year}';

  List<String> get _photoUrls {
    final urls = <String>[];
    final hotelPhoto = widget.hotel['photoUrl']?.toString().trim();
    if (hotelPhoto != null && hotelPhoto.startsWith('http')) {
      urls.add(hotelPhoto);
    }
    final cityUrl = CityImages.networkUrl(widget.destinationIata);
    if (cityUrl.isNotEmpty && !urls.contains(cityUrl)) urls.add(cityUrl);
    if (urls.isEmpty) {
      urls.add(CityImages.networkUrl('default'));
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final name = hotel['name']?.toString() ?? 'Otel';
    final rating = PriceFormat.hotelRatingLine(hotel);
    final stars = hotel['stars'];
    final hint = HotelLocationHints.forHotel(hotel, widget.cityName);
    final lat = (hotel['latitude'] as num?)?.toDouble();
    final lng = (hotel['longitude'] as num?)?.toDouble();
    final perNight = PriceFormat.hotelPerNightTL(hotel);
    final total = PriceFormat.hotelTotalTL(hotel, widget.nights);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: _photoUrls.length,
            onPageChanged: (i) => setState(() => _photoIndex = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: _photoUrls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => DestinationHeroImage(
                    iataCode: widget.destinationIata,
                  ),
                  errorWidget: (_, __, ___) => DestinationHeroImage(
                    iataCode: widget.destinationIata,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_photoUrls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _photoUrls.length,
              (i) => Container(
                width: i == _photoIndex ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _photoIndex ? AppTheme.orange : AppTheme.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TatilTheme.sectionLabel.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                [
                  '${widget.nights} gece',
                  if (rating.isNotEmpty) rating,
                  if (stars != null && (stars as num) > 0) '${stars} yıldız',
                  if (hint != null) hint,
                ].join(' · '),
                style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(CupertinoIcons.calendar, size: 14, color: AppTheme.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Giriş ${_date(widget.checkIn)} · Çıkış ${_date(widget.checkOut)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${PriceFormat.format(total)} · ${PriceFormat.format(perNight)}/gece',
                style: TatilTheme.priceDisplay(fontSize: 16, color: AppTheme.orange),
              ),
              const SizedBox(height: 20),
              Text(
                'Merkeze & meşhur yerlere mesafe',
                style: TatilTheme.sectionLabel.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 10),
              if (lat != null && lng != null)
                HotelProximityMap(
                  hotelLat: lat,
                  hotelLng: lng,
                  destinationIata: widget.destinationIata,
                  hotelLabel: name.length > 18 ? 'Otel' : name,
                )
              else
                ...SelectionDetailResolver.hotelDetails(
                  hotel: hotel,
                  cityName: widget.cityName,
                  destinationIata: widget.destinationIata,
                ).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(line.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              Text(
                                line.value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openMaps(hotel, lat, lng),
                  icon: const Icon(CupertinoIcons.map, size: 18),
                  label: const Text('Google Maps\'te aç'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.teal,
                    side: const BorderSide(color: AppTheme.teal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openMaps(
    Map<String, dynamic> hotel,
    double? lat,
    double? lng,
  ) async {
    final query = lat != null && lng != null
        ? '$lat,$lng'
        : Uri.encodeComponent('${hotel['name']}, ${widget.cityName}');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
