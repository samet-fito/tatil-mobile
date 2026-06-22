import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/holiday_types.dart';
import '../models/personalized_guide_model.dart';
import '../models/stored_booking_model.dart';
import '../services/guide_cache_store.dart';
import '../services/travel_guide_service.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/traveler_group_profile.dart';

/// Seyahat kartında kişisel rehber girişi — önbellek veya prefetch ile özet gösterir.
class TripGuideCta extends StatefulWidget {
  const TripGuideCta({
    super.key,
    required this.booking,
    required this.onTap,
  });

  final StoredBooking booking;
  final VoidCallback onTap;

  @override
  State<TripGuideCta> createState() => _TripGuideCtaState();
}

class _TripGuideCtaState extends State<TripGuideCta> {
  PersonalizedGuide? _guide;
  bool _upgrading = false;

  TravelerGroupProfile get _profile => TravelerGroupProfile.from(
        adults: widget.booking.adults,
        children: widget.booking.children,
        passengerAges: widget.booking.passengerAges,
      );

  @override
  void initState() {
    super.initState();
    _guide = TravelGuideService.buildLocalGuide(
      cityName: widget.booking.cityName,
      country: widget.booking.country,
      destinationIata: widget.booking.destinationIata,
      nights: widget.booking.nights,
      adults: widget.booking.adults,
      children: widget.booking.children,
      passengerAges: widget.booking.passengerAges,
      holidayTypes: widget.booking.holidayTypes,
    );
    _prepareGuide();
  }

  Future<void> _prepareGuide() async {
    final id = widget.booking.reservationId;
    final cached = id.isNotEmpty ? await GuideCacheStore.get(id) : null;

    if (cached != null && mounted) {
      setState(() => _guide = cached);
    }

    if (id.isEmpty) return;

    setState(() => _upgrading = true);
    try {
      final full = await TravelGuideService.load(
        cityName: widget.booking.cityName,
        country: widget.booking.country,
        destinationIata: widget.booking.destinationIata,
        departureDate: widget.booking.departureDate,
        returnDate: widget.booking.returnDate,
        nights: widget.booking.nights,
        adults: widget.booking.adults,
        children: widget.booking.children,
        passengerAges: widget.booking.passengerAges,
        hotelName: widget.booking.hotelName,
        reservationId: id,
        holidayTypes: widget.booking.holidayTypes,
      );
      if (!mounted || full == null) return;
      setState(() => _guide = full);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }

  String get _title {
    if (_guide != null && _guide!.headline.isNotEmpty) {
      return _guide!.headline;
    }
    return '${widget.booking.cityName}\'da ne yapmalısın?';
  }

  String get _subtitle {
    if (_upgrading) {
      return '${_profile.summaryLabel} için AI rehberi güncelleniyor…';
    }
    if (_guide != null && _guide!.subtitle.isNotEmpty) {
      return _guide!.subtitle;
    }
    return _fallbackSubtitle();
  }

  String _fallbackSubtitle() {
    final parts = <String>[_profile.groupType.label];
    if (widget.booking.holidayTypes.isNotEmpty) {
      parts.add(HolidayTypes.labelsOf(widget.booking.holidayTypes).join(', '));
    }
    parts.add('${widget.booking.nights} gece · size özel rota ve ipuçları');
    return parts.join(' · ');
  }

  String? get _previewLine {
    if (_guide == null) return null;
    for (final section in _guide!.sections) {
      if (section.kind == GuideSectionKind.mustDo ||
          section.kind == GuideSectionKind.interests) {
        if (section.items.isNotEmpty) return section.items.first;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewLine;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.teal.withValues(alpha: 0.12),
              AppTheme.orange.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _upgrading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CupertinoActivityIndicator(radius: 10),
                    )
                  : const Icon(CupertinoIcons.book, color: AppTheme.teal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.35),
                  ),
                  if (preview != null && preview.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _upgrading ? 'Güncelleniyor…' : 'Rehberi aç',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.teal,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(CupertinoIcons.chevron_right, color: AppTheme.teal),
            ),
          ],
        ),
      ),
    );
  }
}
