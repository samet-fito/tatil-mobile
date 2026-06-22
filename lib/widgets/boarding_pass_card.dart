import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/stored_booking_model.dart';
import '../theme/tatil_theme.dart';
import '../utils/boarding_pass_data.dart';
import '../screens/boarding_pass_screen.dart';

/// Seyahat kartında özet biniş kartı önizlemesi.
class BoardingPassCard extends StatelessWidget {
  const BoardingPassCard({
    super.key,
    required this.booking,
  });

  final StoredBooking booking;

  @override
  Widget build(BuildContext context) {
    final data = BoardingPassData.fromBooking(booking);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BoardingPassScreen(booking: booking),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3B38), Color(0xFF145A54)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.airplane_ticket, color: Color(0xFF7EE8D8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Canlı biniş kartın',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7EE8D8),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  data.departsInLabel,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _airport(data.originIata, data.departureTimeLabel),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.flight, color: Colors.white54, size: 18),
                      Text(
                        data.flightNumber,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                _airport(data.destinationIata, data.arrivalTimeLabel),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('Kapı', data.gate),
                  _miniStat('Koltuk', data.seat),
                  _miniStat('Durum', data.statusLabel),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Detayları gör',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _airport(String code, String time) {
    return Column(
      children: [
        Text(
          code,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TatilTheme.hint.copyWith(color: Colors.white54, fontSize: 10)),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
