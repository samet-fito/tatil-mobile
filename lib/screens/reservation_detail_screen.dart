import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/stored_booking_model.dart';
import '../services/travel_document_service.dart';
import '../services/trip_share_service.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../widgets/checkout_cancellation_card.dart';
import '../widgets/online_cancellation_section.dart';
import '../widgets/destination_hero_image.dart';
import '../utils/traveler_group_profile.dart';
import '../widgets/hero_page_scroll.dart';
import '../widgets/trip_card_content.dart';
import '../widgets/boarding_pass_card.dart';
import '../widgets/trip_guide_cta.dart';
import 'destination_guide_screen.dart';

/// Profil → Rezervasyonlarım → Seyahat kartı (tek post-booking hub).
class ReservationDetailScreen extends StatelessWidget {
  const ReservationDetailScreen({super.key, required this.booking});

  final StoredBooking booking;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  void _openGuide(BuildContext context) {
    final profile = TravelerGroupProfile.from(
      adults: booking.adults,
      children: booking.children,
      passengerAges: booking.passengerAges,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationGuideScreen(
          cityName: booking.cityName,
          country: booking.country,
          destinationIata: booking.destinationIata,
          departureDate: booking.departureDate,
          returnDate: booking.returnDate,
          nights: booking.nights,
          adults: booking.adults,
          children: booking.children,
          passengerAges: booking.passengerAges,
          hotelName: booking.hotelName,
          reservationId: booking.reservationId,
          groupProfileLabel: profile.summaryLabel,
          holidayTypes: booking.holidayTypes,
        ),
      ),
    );
  }

  void _openEticket(BuildContext context) {
    TravelDocumentService.showDocumentOptions(
      context,
      title: 'E-Bilet',
      fileName: 'vizegoo-ebilet-${booking.reservationId}.html',
      webViewerUrl: TravelDocumentService.eticketViewerUrl(booking.reservationId),
      htmlBody: TravelDocumentService.buildEticketHtml(
        reservationId: booking.reservationId,
        passengerName: booking.passengerName,
        airline: booking.airline ?? '—',
        departure: _fmtDate(booking.departureDate),
        returnDate: _fmtDate(booking.returnDate),
        adults: booking.adults,
        children: booking.children,
      ),
    );
  }

  void _openVoucher(BuildContext context) {
    TravelDocumentService.showDocumentOptions(
      context,
      title: 'Otel Voucher',
      fileName: 'vizegoo-voucher-${booking.reservationId}.html',
      webViewerUrl: TravelDocumentService.voucherViewerUrl(booking.reservationId),
      htmlBody: TravelDocumentService.buildVoucherHtml(
        reservationId: booking.reservationId,
        passengerName: booking.passengerName,
        hotelName: booking.hotelName ?? '—',
        checkIn: _fmtDate(booking.departureDate),
        checkOut: _fmtDate(booking.returnDate),
        nights: booking.nights,
      ),
    );
  }

  String _heroSubtitle() {
    if (booking.isStandaloneProduct) {
      if (booking.isCarRental &&
          booking.returnDate.isAfter(booking.departureDate)) {
        return '${booking.categoryLabel} · ${_fmtDate(booking.departureDate)} – ${_fmtDate(booking.returnDate)}';
      }
      return '${booking.categoryLabel} · ${_fmtDate(booking.departureDate)}';
    }
    if (booking.country.trim().isNotEmpty) {
      return '${booking.country} · ${booking.nights} gece';
    }
    return '${booking.nights} gece';
  }

  String get _screenTitle =>
      booking.isStandaloneProduct ? '${booking.categoryLabel} Kartı' : 'Seyahat Kartı';

  List<String> _standaloneCancellationParagraphs() {
    if (booking.isBus) {
      return const [
        'Kalkış saatinden en az 2 saat önce iptal talebinde bulunursanız tam iade için değerlendirilirsiniz.',
        'Geç iptallerde operatör koşullarına göre kesinti uygulanabilir.',
        'İade süreci 5–14 iş günü içinde kartınıza yansır.',
      ];
    }
    if (booking.isTransfer) {
      return const [
        'Transfer saatinden en az 24 saat önce iptal talebinde tam iade için değerlendirilirsiniz.',
        'Son 24 saatte iptal veya no-show durumunda ücret iadesi yapılmayabilir.',
        'İade süreci 5–14 iş günü içinde kartınıza yansır.',
      ];
    }
    if (booking.isCarRental) {
      return const [
        'Alış tarihinden en az 24 saat önce iptal talebinde tam iade için değerlendirilirsiniz.',
        'Geç iptallerde kiralama firmasının politikasına göre kesinti uygulanabilir.',
        'Depozito ve ek ücretler firma koşullarına tabidir.',
      ];
    }
    return const [
      'Etkinlik tarihinden en az 24 saat önce iptal talebinde bulunursanız tam iade için değerlendirilirsiniz. Son 24 saatte iptal ücreti uygulanabilir.',
      'İade süreci 5–14 iş günü içinde kartınıza yansır. Kesin tutar etkinlik sağlayıcısının koşullarına göre belirlenir.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: HeroPageScroll(
        title: _screenTitle,
        expandedHeight: 160,
        hero: Stack(
          fit: StackFit.expand,
          children: [
            DestinationHeroImage(iataCode: booking.destinationIata),
            Container(color: Colors.black.withValues(alpha: 0.45)),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.listTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _heroSubtitle(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TripCardContent(booking: booking),
                if (booking.hasFlight) ...[
                  const SizedBox(height: 16),
                  BoardingPassCard(booking: booking),
                ],
                const SizedBox(height: 16),
                TripTotalPaidCard(booking: booking),
                const SizedBox(height: 16),
                _actionRow(context),
                const SizedBox(height: 16),
                OnlineCancellationSection(booking: booking),
                const SizedBox(height: 16),
                if (booking.isStandaloneProduct)
                  _standaloneCancellationCard()
                else
                  CheckoutCancellationCard(
                    departureDate: booking.departureDate,
                    returnDate: booking.returnDate,
                    nights: booking.nights,
                    showFlight: booking.hasFlight,
                    showHotel: booking.hasHotel,
                    postBooking: true,
                    airline: booking.airline,
                    hotelName: booking.hotelName,
                    flightPriceTL: booking.flightPriceTL,
                    hotelPriceTL: booking.hotelPriceTL,
                  ),
                if (!booking.isStandaloneProduct) ...[
                  const SizedBox(height: 16),
                  TripGuideCta(
                    booking: booking,
                    onTap: () => _openGuide(context),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Bu kart cihazınızda saklanır — internetsiz de görüntüleyebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TatilTheme.hint.copyWith(fontSize: 11, height: 1.35),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _standaloneCancellationCard() {
    final paragraphs = _standaloneCancellationParagraphs();
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
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: 16,
                color: AppTheme.teal.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                'İptal koşulları',
                style: TatilTheme.sectionLabel.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                p,
                style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(BuildContext context) {
    final actions = <Widget>[
      Expanded(
        child: _actionButton(
          icon: CupertinoIcons.share,
          label: 'Paylaş',
          onTap: () => TripShareService.shareBooking(booking),
        ),
      ),
    ];
    if (booking.hasFlight) {
      actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: _actionButton(
            icon: CupertinoIcons.doc_plaintext,
            label: 'E-bilet',
            onTap: () => _openEticket(context),
          ),
        ),
      );
    }
    if (booking.hasHotel) {
      actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: _actionButton(
            icon: CupertinoIcons.house,
            label: 'Otel voucher',
            onTap: () => _openVoucher(context),
          ),
        ),
      );
    }
    return Row(children: actions);
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.teal),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
