import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/stored_booking_model.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/boarding_pass_data.dart';
import '../widgets/destination_hero_image.dart';
import '../widgets/hero_page_scroll.dart';

/// Canlı uçuş / biniş kartı — kapı, terminal, QR ve koltuk bilgileri.
class BoardingPassScreen extends StatelessWidget {
  const BoardingPassScreen({super.key, required this.booking});

  final StoredBooking booking;

  @override
  Widget build(BuildContext context) {
    final data = BoardingPassData.fromBooking(booking);

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B38),
      body: HeroPageScroll(
        title: 'Biniş Kartı',
        expandedHeight: 200,
        hero: Stack(
          fit: StackFit.expand,
          children: [
            DestinationHeroImage(iataCode: booking.destinationIata),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    const Color(0xFF0D3B38).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _routeHeader(data),
            ),
          ],
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      data.departsInLabel,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7EE8D8),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _flightStatusCard(data),
                const SizedBox(height: 14),
                _boardingCard(context, data),
                if (data.detailsPending) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Kapı ve terminal bilgileri havayolu onayıyla güncellenir. '
                    'Kalkıştan önce tekrar kontrol edin.',
                    textAlign: TextAlign.center,
                    style: TatilTheme.hint.copyWith(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeHeader(BoardingPassData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.originCity,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    data.departureTimeLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.flight, color: Colors.white70, size: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.destinationCity,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    data.arrivalTimeLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${data.originIata} → ${data.destinationIata}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _flightStatusCard(BoardingPassData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TatilTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flight_takeoff, color: TatilTheme.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.flightNumber,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      data.airline,
                      style: TatilTheme.hint.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.statusLabel,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoTile(Icons.airport_shuttle_outlined, 'Terminal', data.terminal),
              _infoTile(Icons.confirmation_number_outlined, 'Check-in', data.checkInCounters),
              _infoTile(Icons.door_front_door_outlined, 'Kapı', data.gate),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kapınızda en az 45 dk önce olun. Biniş saatleri ekranlardan takip edin.',
                  style: TatilTheme.hint.copyWith(fontSize: 11, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.teal),
          const SizedBox(height: 4),
          Text(label, style: TatilTheme.hint.copyWith(fontSize: 10)),
          Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _boardingCard(BuildContext context, BoardingPassData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.passengerName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Share.share(
                  'Vizegoo biniş kartı — ${data.flightNumber}\n'
                  '${data.originIata}→${data.destinationIata} · Koltuk ${data.seat}\n'
                  'Kapı ${data.gate} · ${data.reservationRef}',
                ),
                icon: const Icon(Icons.ios_share, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              QrImageView(
                data: data.qrPayload,
                version: QrVersions.auto,
                size: 120,
                backgroundColor: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _seatRow('Öncelik', data.priorityLabel, Icons.workspace_premium_outlined),
                    const SizedBox(height: 12),
                    _seatRow('Koltuk', data.seat, Icons.event_seat_outlined),
                    const SizedBox(height: 12),
                    _seatRow('Rezervasyon', data.reservationRef, Icons.tag_outlined),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(
            'Vizegoo Seyahat Kartı',
            style: TatilTheme.hint.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _seatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.teal),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TatilTheme.hint.copyWith(fontSize: 10)),
            Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
