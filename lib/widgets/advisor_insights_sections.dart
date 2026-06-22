import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/smart_travel_advisor_model.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';

/// Akıllı danışmandan rehbere eklenen bölümler — etkinlik & kur (tekrar yok).
class AdvisorInsightsSections extends StatelessWidget {
  const AdvisorInsightsSections({
    super.key,
    required this.advisor,
    this.onOpenTicketUrl,
  });

  final SmartTravelAdvisorResponse advisor;
  final Future<void> Function(String url)? onOpenTicketUrl;

  @override
  Widget build(BuildContext context) {
    final events = advisor.displayableEvents;
    final currency = advisor.currencyConverter;
    final showCurrency = currency.currentRateText.trim().isNotEmpty;

    if (events.isEmpty && !showCurrency) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCurrency) ...[
          _currencyCard(currency),
          if (events.isNotEmpty) const SizedBox(height: 14),
        ],
        if (events.isNotEmpty) ...[
          Text(
            'Canlı etkinlikler & konserler',
            style: TatilTheme.sectionLabel.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...events.map(_eventCard),
        ],
      ],
    );
  }

  Widget _currencyCard(CurrencyConverter currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.orangeSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currency.localCurrency,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: AppTheme.orange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              currency.currentRateText,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(LiveEventAffiliate event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.eventName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (event.date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.date,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.orange,
              ),
            ),
          ],
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textMuted,
              ),
            ),
          ],
          if (event.ticketAffiliateUrl.isNotEmpty && onOpenTicketUrl != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => onOpenTicketUrl!(event.ticketAffiliateUrl),
                child: const Text(
                  'Bilet bul',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
