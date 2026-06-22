import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../config/app_experience.dart';
import '../models/search_category.dart';
import '../theme/app_theme.dart';
import '../theme/tatil_theme.dart';
import '../utils/app_navigation.dart';
import '../utils/price_format.dart';
import '../widgets/preview_mode_banner.dart';

/// Otobüs, transfer ve araç kiralama önizleme rezervasyonu sonrası ekran.
class CategoryBookingSuccessScreen extends StatelessWidget {
  const CategoryBookingSuccessScreen({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.reservationId,
    required this.totalPriceTL,
    required this.passengerName,
    this.eventDate,
  });

  final SearchCategory category;
  final String title;
  final String subtitle;
  final String reservationId;
  final int totalPriceTL;
  final String passengerName;
  final DateTime? eventDate;

  void _goHome(BuildContext context) {
    AppNavigation.openExploreTab(context);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: AppTheme.textPrimary),
          onPressed: () => _goHome(context),
        ),
        title: const Text(
          'Talebiniz alındı',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PreviewModeBanner(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.orangeSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(category.icon, color: AppTheme.orange, size: 28),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TatilTheme.hint.copyWith(height: 1.4),
                        ),
                        if (eventDate != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.calendar,
                                size: 14,
                                color: AppTheme.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(eventDate!),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow('Rezervasyon no', reservationId),
                  _infoRow('Yolcu', passengerName),
                  _infoRow('Tutar', PriceFormat.format(totalPriceTL)),
                  const SizedBox(height: 12),
                  Text(
                    AppExperience.paymentsEnabled
                        ? 'Onay e-postası kısa süre içinde gönderilecektir.'
                        : 'Bu bir önizleme talebidir. Gerçek bilet ve ödeme entegrasyonu yakında aktif olacak.',
                    style: TatilTheme.hint.copyWith(fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _goHome(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Keşfet\'e dön',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TatilTheme.hint.copyWith(fontSize: 13)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
